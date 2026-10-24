import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { Alert, Box, Button, Card, Chip, Paper, Snackbar, Stack, TablePagination, Typography } from '@mui/material'
import { Columns3 } from 'lucide-react'
import { PageHeader } from '../../../components/common/PageHeader'
import { SearchInput } from '../../../components/common/SearchInput'
import { EmptyState } from '../../../components/common/EmptyState'
import { ErrorState } from '../../../components/common/ErrorState'
import { LoadingState } from '../../../components/common/LoadingState'
import apiClient, { BRANCH_CONTEXT_EVENT } from '../../../services/apiClient'
import { authService } from '../../../services/authService'
import { EmployeeDetailsPanel } from '../components/EmployeeDetailsPanel'
import { EditColumnsDrawer } from '../components/EditColumnsDrawer'
import { EmployeesTable } from '../components/EmployeesTable'
import {
  COLUMNS, DEFAULT_ROWS_PER_PAGE, ROWS_PER_PAGE_OPTIONS, applyFilters, describeFilter, isFilterActive, isSortAvailable, matchesSearch, sortRows,
} from '../employeeColumns'
import { useEmployeeColumns } from '../useEmployeeColumns'

const emptyOptions = { branches: [], departments: [], designations: [] }

function responseData(response) {
  return response.data?.data ?? response.data
}

function listData(response) {
  const data = responseData(response)
  return Array.isArray(data) ? data : []
}

function errorMessage(error) {
  const data = error?.response?.data
  if (data?.detail) return data.detail
  if (data?.errors) {
    return Object.entries(data.errors).map(([field, messages]) => `${field}: ${Array.isArray(messages) ? messages.join(' ') : messages}`).join(' ')
  }
  return data?.message ?? error?.message ?? 'Unable to complete this request.'
}

const idNameMap = (items) => new Map(items.map((item) => [String(item.id), item.name]))

export function EmployeesPage() {
  const currentUser = authService.getCurrentUser()
  const can = (codename) => currentUser?.role === 'SUPERADMIN' || Boolean(currentUser?.permissions?.includes(codename))
  const canAdd = can('employees.add_employee')
  const canEdit = can('employees.change_employee')

  const [query, setQuery] = useState('')
  const [filters, setFilters] = useState({})
  const [sort, setSort] = useState(null) // { id, dir } — null keeps the API's default order (employee code)
  const [page, setPage] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(DEFAULT_ROWS_PER_PAGE)
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [pageError, setPageError] = useState('')
  const [panelOpen, setPanelOpen] = useState(false)
  const [editingId, setEditingId] = useState(null)
  const [columnsOpen, setColumnsOpen] = useState(false)
  const [options, setOptions] = useState(emptyOptions)
  const [optionsLoading, setOptionsLoading] = useState(true)
  const [optionsError, setOptionsError] = useState('')
  const [notice, setNotice] = useState('')
  const { visibleIds, save: saveColumns, defaultIds } = useEmployeeColumns(currentUser?.id)
  const requestId = useRef(0)

  const loadEmployees = useCallback(async () => {
    const current = ++requestId.current
    setLoading(true)
    setPageError('')
    try {
      const response = await apiClient.get('/employees/')
      if (current === requestId.current) setRows(listData(response)) // ignore responses superseded by a newer request
    } catch (error) {
      if (current === requestId.current) setPageError(errorMessage(error))
    } finally {
      if (current === requestId.current) setLoading(false)
    }
  }, [])

  // Inactive options are fetched so an employee's current assignment remains selectable while editing.
  const loadOptions = async () => {
    setOptionsLoading(true)
    setOptionsError('')
    try {
      const [branches, departments, designations] = await Promise.all(
        ['/branches/', '/departments/', '/designations/'].map((url) => apiClient.get(url, { params: { include_inactive: true } })),
      )
      setOptions({ branches: listData(branches), departments: listData(departments), designations: listData(designations) })
    } catch (error) {
      setOptionsError(errorMessage(error))
    } finally {
      setOptionsLoading(false)
    }
  }

  useEffect(() => {
    loadEmployees()
    loadOptions()
  }, [loadEmployees])

  useEffect(() => {
    const refreshBranchData = () => loadEmployees()
    window.addEventListener(BRANCH_CONTEXT_EVENT, refreshBranchData)
    return () => window.removeEventListener(BRANCH_CONTEXT_EVENT, refreshBranchData)
  }, [loadEmployees])


  const ctx = useMemo(() => ({
    branches: idNameMap(options.branches),
    departments: idNameMap(options.departments),
    designations: idNameMap(options.designations),
  }), [options])

  const columns = useMemo(() => COLUMNS.filter((column) => visibleIds.includes(column.id)), [visibleIds])

  // Search -> column filters -> sort -> page. The API returns the complete list, so this is global, not per-page.
  const searched = useMemo(() => rows.filter((row) => matchesSearch(row, query)), [rows, query])
  const filtered = useMemo(() => applyFilters(searched, filters, ctx), [searched, filters, ctx])
  const sorted = useMemo(() => sortRows(filtered, sort, ctx), [filtered, sort, ctx])
  const lastPage = Math.max(0, Math.ceil(sorted.length / rowsPerPage) - 1)
  const safePage = Math.min(page, lastPage)
  const pageRows = useMemo(() => sorted.slice(safePage * rowsPerPage, safePage * rowsPerPage + rowsPerPage), [sorted, safePage, rowsPerPage])

  const activeFilters = COLUMNS.filter((column) => isFilterActive(column, filters[column.id]))
  const hasNarrowing = Boolean(query.trim()) || activeFilters.length > 0
  const activeCount = rows.filter((row) => row.is_active).length

  const changeQuery = (value) => { setQuery(value); setPage(0) }
  const changeFilter = (id, value) => {
    setFilters((current) => {
      const next = { ...current }
      if (value === undefined) delete next[id]
      else next[id] = value
      return next
    })
    setPage(0)
  }
  // Click cycle per column: ascending -> descending -> back to the default order.
  const changeSort = (id) => {
    setSort((current) => (current?.id !== id ? { id, dir: 'asc' } : current.dir === 'asc' ? { id, dir: 'desc' } : null))
    setPage(0)
  }
  // Explicit direction from a sort popover; null returns to the default order.
  const changeSortTo = (id, dir) => { setSort(dir ? { id, dir } : null); setPage(0) }
  const clearAll = () => { setQuery(''); setFilters({}); setPage(0) }

  const openCreate = () => {
    setEditingId(null)
    setPanelOpen(true)
  }

  const openEdit = (row) => {
    setEditingId(row.id)
    setPanelOpen(true)
  }

  // `message` is null when the panel must stay open (employee saved but a document upload failed).
  const handleSaved = async (message, { keepOpen = false } = {}) => {
    if (!keepOpen) setPanelOpen(false)
    if (message) setNotice(message)
    await loadEmployees()
  }

  const handleSaveColumns = (ids) => {
    saveColumns(ids)
    // A hidden column can no longer be sorted by or filtered on, so drop those so nothing invisible narrows the table.
    const keep = new Set(ids)
    setFilters((current) => Object.fromEntries(Object.entries(current).filter(([id]) => keep.has(id))))
    setSort((current) => (current && !isSortAvailable(current.id, keep) ? null : current))
    setColumnsOpen(false)
  }

  return (
    <Box>
      <PageHeader
        title="Employees"
        subtitle="Manage employee profiles, assignments, and account status."
      />

      <Card sx={{ mb: 1.5 }}>
        <Box sx={{ p: { xs: 1.5, sm: 2 } }}>
          <Stack direction={{ xs: 'column', md: 'row' }} sx={{ gap: 1.5, alignItems: { md: 'center' }, justifyContent: 'space-between' }}>
            <Typography variant="h6" component="h2" sx={{ color: 'text.primary', whiteSpace: 'nowrap' }}>
              Total Active Employees{' '}
              <Box component="span" sx={{ color: 'secondary.main', fontVariantNumeric: 'tabular-nums' }}>{loading && rows.length === 0 ? '…' : activeCount}</Box>
              {hasNarrowing && !loading ? (
                <Typography component="span" variant="body2" color="text.secondary" sx={{ ml: 1, fontWeight: 400 }}>· {sorted.length} matching</Typography>
              ) : null}
            </Typography>
            <Stack direction={{ xs: 'column', sm: 'row' }} sx={{ gap: 1, alignItems: { sm: 'center' } }}>
              <Box sx={{ width: { xs: '100%', sm: 300 } }}>
                <SearchInput value={query} onChange={changeQuery} label="Search employees" placeholder="Search by name, code, phone, or email" />
              </Box>
              <Stack direction="row" sx={{ gap: 1 }}>
                {canAdd ? <Button variant="contained" onClick={openCreate}>Add Employee</Button> : null}
                <Button variant="outlined" startIcon={<Columns3 size={16} aria-hidden="true" />} onClick={() => setColumnsOpen(true)}>Edit Columns</Button>
              </Stack>
            </Stack>
          </Stack>
          {activeFilters.length > 0 ? (
            <Stack direction="row" sx={{ gap: 1, mt: 1.5, flexWrap: 'wrap', alignItems: 'center' }} aria-label="Active filters">
              {activeFilters.map((column) => (
                <Chip
                  key={column.id}
                  size="small"
                  color="info"
                  variant="outlined"
                  label={`${column.label}: ${describeFilter(column, filters[column.id], ctx, rows)}`}
                  onDelete={() => changeFilter(column.id, undefined)}
                />
              ))}
              <Button size="small" onClick={() => { setFilters({}); setPage(0) }}>Clear filters</Button>
            </Stack>
          ) : null}
        </Box>
      </Card>

      {pageError ? <ErrorState message={pageError} onRetry={loadEmployees} retrying={loading} /> : null}
      {optionsError ? <Alert severity="warning" sx={{ mb: 2 }}>Branch, department and designation names could not be loaded: {optionsError}</Alert> : null}

      <Paper variant="outlined" sx={{ overflow: 'hidden', borderRadius: 2 }}>
        {loading && rows.length === 0 ? (
          <LoadingState label="Loading employees…" />
        ) : pageError && rows.length === 0 ? (
          <Box sx={{ minHeight: 96 }} />
        ) : sorted.length === 0 ? (
          <EmptyState
            title={hasNarrowing ? 'No matching employees' : 'No employees yet'}
            description={hasNarrowing ? 'Try a different search or clear the filters.' : 'Add an employee to start building your workforce directory.'}
            actionLabel={hasNarrowing ? 'Clear search and filters' : canAdd ? 'Add Employee' : undefined}
            onAction={hasNarrowing ? clearAll : canAdd ? openCreate : undefined}
          />
        ) : (
          <>
            <EmployeesTable
              rows={pageRows}
              allRows={rows}
              columns={columns}
              ctx={ctx}
              sort={sort}
              onSort={changeSort}
              onSortTo={changeSortTo}
              filters={filters}
              onFilterChange={changeFilter}
              canEdit={canEdit}
              onEdit={openEdit}
            />
            <TablePagination
              component="div"
              count={sorted.length}
              page={safePage}
              onPageChange={(_event, next) => setPage(next)}
              rowsPerPage={rowsPerPage}
              onRowsPerPageChange={(event) => { setRowsPerPage(Number(event.target.value)); setPage(0) }}
              rowsPerPageOptions={ROWS_PER_PAGE_OPTIONS}
              labelRowsPerPage="Rows"
              sx={{ borderTop: '1px solid', borderColor: 'divider', '& .MuiTablePagination-toolbar': { minHeight: 48 } }}
              slotProps={{ select: { inputProps: { 'aria-label': 'Rows per page' } } }}
            />
          </>
        )}
      </Paper>

      <EditColumnsDrawer open={columnsOpen} visibleIds={visibleIds} defaultIds={defaultIds} onSave={handleSaveColumns} onClose={() => setColumnsOpen(false)} />

      <EmployeeDetailsPanel
        open={panelOpen}
        employeeId={editingId}
        rows={rows}
        options={options}
        optionsLoading={optionsLoading}
        optionsError={optionsError}
        onRetryOptions={loadOptions}
        onClose={() => setPanelOpen(false)}
        onSaved={handleSaved}
      />

      <Snackbar open={Boolean(notice)} autoHideDuration={4000} onClose={() => setNotice('')} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
        <Alert severity="success" variant="filled" onClose={() => setNotice('')}>{notice}</Alert>
      </Snackbar>
    </Box>
  )
}