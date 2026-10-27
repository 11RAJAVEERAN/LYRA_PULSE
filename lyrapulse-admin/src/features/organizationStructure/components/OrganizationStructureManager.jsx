import { useEffect, useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  Alert, Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, FormControl,
  IconButton, InputLabel, MenuItem, Paper, Select, Snackbar, Stack, Switch, Table,
  TableBody, TableCell, TableContainer, TableHead, TablePagination, TableRow, TextField,
  Tooltip, Typography,
} from '@mui/material'
import { ArrowLeft, Pencil, Plus, Trash2 } from 'lucide-react'


import { PageHeader } from '../../../components/common/PageHeader'
import { EmptyState } from '../../../components/common/EmptyState'
import { ErrorState } from '../../../components/common/ErrorState'
import { LoadingState } from '../../../components/common/LoadingState'
import { SearchInput } from '../../../components/common/SearchInput'
import { StatusChip } from '../../../components/common/StatusChip'
import { authService } from '../../../services/authService'
import { BRANCH_CONTEXT_EVENT, SELECTED_BRANCH_KEY } from '../../../services/apiClient'
import { employeesApi } from '../../employees/api/employeesApi'
import { fullName } from '../../employees/employeeColumns'

const PAGE_SIZE_OPTIONS = [10, 25, 50]

function currentUserCan(permission) {
  const user = authService.getCurrentUser()
  return user?.role === 'SUPERADMIN' || Boolean(user?.permissions?.includes(permission))
}

function requestError(error) {
  const data = error?.response?.data
  const message = data?.detail ?? data?.message
  if (message) return String(message)
  const fieldErrors = Object.values(data ?? {}).flat().filter(Boolean).map(String).join(' ')
  return fieldErrors || error?.message || 'Request failed. Please try again.'
}

export function OrganizationStructureManager({ page, api }) {

  const queryClient = useQueryClient()
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [branchContext, setBranchContext] = useState(() => window.localStorage.getItem(SELECTED_BRANCH_KEY) ?? '')
  const [parentFilter, setParentFilter] = useState(() => page.initialFilterFromSelectedBranch
    ? (window.localStorage.getItem(SELECTED_BRANCH_KEY) ?? 'all')
    : 'all')
  const [pageNumber, setPageNumber] = useState(0)
  const [rowsPerPage, setRowsPerPage] = useState(10)
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editing, setEditing] = useState(null)
  const [loadingDetailId, setLoadingDetailId] = useState(null)
  const [deleting, setDeleting] = useState(null)
  const [form, setForm] = useState({ name: '', parentId: '' })
  const [notice, setNotice] = useState(null)
  const [employeeDetailsRow, setEmployeeDetailsRow] = useState(null)
  const canAdd = currentUserCan('employees.add_employee')
  const canChange = currentUserCan('employees.change_employee')
  const params = useMemo(() => ({
    include_inactive: true,
    branch: page.parentField === 'branch'
      ? (parentFilter === 'all' ? '' : parentFilter || '')
      : (branchContext || undefined),
    ...(page.parentField === 'department'
      ? { department: parentFilter === 'all' ? '' : parentFilter || undefined }
      : {}),
  }), [page, parentFilter, branchContext])

  const rowsQuery = useQuery({
    queryKey: ['org-structure', page.key, params],
    queryFn: () => api.list(params),
  })
  const parentQuery = useQuery({
    queryKey: ['org-structure-parent-options', page.key, branchContext],
    queryFn: () => api.listParents({
      include_inactive: true,
      ...(branchContext ? { branch: branchContext } : {}),
    }),
  })
  const rows = rowsQuery.data ?? []
  const parents = parentQuery.data ?? []
  const employeeParams = employeeDetailsRow ? {
    [page.employeeFilterParam]: employeeDetailsRow.id,
    branch: employeeDetailsRow.branch,
  } : undefined
  const employeeQuery = useQuery({
    queryKey: ['org-structure-employees', page.key, employeeDetailsRow?.id, employeeDetailsRow?.branch],
    queryFn: () => employeesApi.list(employeeParams),
    enabled: Boolean(employeeDetailsRow),
  })
  const invalidateStructureQueries = async () => Promise.all([
    queryClient.invalidateQueries({ queryKey: ['org-structure'] }),
    queryClient.invalidateQueries({ queryKey: ['org-structure-parent-options'] }),
  ])

  useEffect(() => {
    const syncBranch = (event) => {
      const branchId = event.detail?.branchId ?? ''
      setBranchContext(branchId)
      setParentFilter(page.initialFilterFromSelectedBranch ? (branchId || 'all') : 'all')
    }
    window.addEventListener(BRANCH_CONTEXT_EVENT, syncBranch)
    return () => window.removeEventListener(BRANCH_CONTEXT_EVENT, syncBranch)
  }, [page.key, page.initialFilterFromSelectedBranch])

  const filteredRows = rows.filter((row) => {
    const matchesSearch = (String(row.name ?? '') + ' ' + String(row[page.secondValue] ?? ''))
      .toLowerCase().includes(search.trim().toLowerCase())
    const matchesStatus = statusFilter === 'all' || (statusFilter === 'active' ? row.is_active : !row.is_active)
    return matchesSearch && matchesStatus
  })
  const pageRows = filteredRows.slice(pageNumber * rowsPerPage, (pageNumber + 1) * rowsPerPage)

  const saveMutation = useMutation({
    mutationFn: async () => {
      const payload = { name: form.name.trim(), [page.parentField]: Number(form.parentId) }
      if (editing) return api.update(editing.id, payload)
      return api.create(payload)
    },
    onSuccess: async () => {
      setDialogOpen(false)
      setNotice({ severity: 'success', message: page.singular + (editing ? ' updated.' : ' created.') })
      await invalidateStructureQueries()
    },
    onError: (error) => setNotice({ severity: 'error', message: requestError(error) }),
  })
  const statusMutation = useMutation({
    mutationFn: ({ row, is_active }) => api.update(row.id, { is_active }),
    onSuccess: async () => {
      setNotice({ severity: 'success', message: page.singular + ' status updated.' })
      await invalidateStructureQueries()
    },
    onError: (error) => setNotice({ severity: 'error', message: requestError(error) }),
  })
  const deleteMutation = useMutation({
    mutationFn: (row) => api.remove(row.id),
    onSuccess: async () => {
      setDeleting(null)
      setNotice({ severity: 'success', message: page.singular + ' deleted.' })
      await invalidateStructureQueries()
    },
    onError: (error) => setNotice({ severity: 'error', message: requestError(error) }),
  })

  const openCreate = () => {
    saveMutation.reset()
    setEditing(null)
    setForm({ name: '', parentId: parents.find((item) => item.is_active)?.id?.toString() ?? '' })
    setDialogOpen(true)
  }
  const openEdit = async (row) => {
    saveMutation.reset()
    setLoadingDetailId(row.id)
    try {
      const record = { ...row, ...await api.get(row.id) }
      setEditing(record)
      setForm({ name: record.name, parentId: String(record[page.parentValue] ?? '') })
      setDialogOpen(true)
    } catch (error) {
      setNotice({ severity: 'error', message: requestError(error) })
    } finally {
      setLoadingDetailId(null)
    }
  }
  const openEmployeeList = (row) => setEmployeeDetailsRow(row)

  return (
    <Box>
      <PageHeader
        title={page.title}
        action={canAdd ? (
          <Button variant="contained" startIcon={<Plus size={17} />} onClick={openCreate}
            disabled={parentQuery.isLoading || !parents.some((parent) => parent.is_active)}>
            Add {page.singular}
          </Button>
        ) : null}
      />
      <Paper variant="outlined" sx={{ p: { xs: 1.5, sm: 2 }, mb: 2 }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={1.5} alignItems={{ md: 'center' }}>
          <SearchInput value={search} onChange={(value) => { setSearch(value); setPageNumber(0) }}
            label={'Search ' + page.title.toLowerCase()} placeholder={'Search ' + page.singular.toLowerCase() + ' name'} />
          <FormControl size="small" sx={{ minWidth: 145 }}>
            <InputLabel id={page.key + '-status-filter'}>Status</InputLabel>
            <Select labelId={page.key + '-status-filter'} label="Status" value={statusFilter}
              onChange={(event) => { setStatusFilter(event.target.value); setPageNumber(0) }}>
              <MenuItem value="all">All statuses</MenuItem>
              <MenuItem value="active">Active</MenuItem>
              <MenuItem value="inactive">Inactive</MenuItem>
            </Select>
          </FormControl>
          <FormControl size="small" sx={{ minWidth: 190 }}>
            <InputLabel id={page.key + '-parent-filter'}>{page.parentLabel}</InputLabel>
            <Select labelId={page.key + '-parent-filter'} label={page.parentLabel} value={parentFilter}
              onChange={(event) => { setParentFilter(event.target.value); setPageNumber(0) }}>
              <MenuItem value="all">All {page.parentLabel.toLowerCase()}s</MenuItem>
              {parents.map((parent) => <MenuItem key={parent.id} value={String(parent.id)}>{parent.name}</MenuItem>)}
            </Select>
          </FormControl>
        </Stack>
      </Paper>

      {rowsQuery.isError ? <ErrorState message={requestError(rowsQuery.error)}
        onRetry={() => rowsQuery.refetch()} retrying={rowsQuery.isFetching} /> : null}
      {parentQuery.isError ? (
        <Alert severity="warning" sx={{ mb: 2 }}>
          Could not load {page.parentLabel.toLowerCase()} options.
          <Button size="small" onClick={() => parentQuery.refetch()}>Retry</Button>
        </Alert>
      ) : null}
      {employeeDetailsRow ? (
        <Paper variant="outlined" sx={{ overflow: 'hidden', mb: 2 }}>
          <Stack direction="row" spacing={1.5} alignItems="center" justifyContent="space-between" sx={{ p: 2 }}>
            <Box>
              <Typography variant="h6">Employees in {employeeDetailsRow.name}</Typography>
              <Typography variant="body2" color="text.secondary">
                {employeeQuery.isSuccess ? employeeQuery.data.length + ' employees' : 'Loading matching employees…'}
              </Typography>
            </Box>
            <Button variant="outlined" startIcon={<ArrowLeft size={16} />} onClick={() => setEmployeeDetailsRow(null)}>
              Back to {page.title}
            </Button>
          </Stack>
          {employeeQuery.isLoading ? <LoadingState label="Loading employees…" />
            : employeeQuery.isError ? <ErrorState message={requestError(employeeQuery.error)}
              onRetry={() => employeeQuery.refetch()} retrying={employeeQuery.isFetching} />
              : employeeQuery.data.length === 0 ? (
                <EmptyState title="No employees found" description={'There are no employees assigned to this ' + page.singular.toLowerCase() + '.'} />
              ) : (
                <TableContainer sx={{ overflowX: 'auto' }}>
                  <Table size="small" aria-label={'Employees in ' + employeeDetailsRow.name}>
                    <TableHead><TableRow>
                      <TableCell>Employee ID</TableCell>
                      <TableCell>Employee Name</TableCell>
                      <TableCell>Employee Tag</TableCell>
                    </TableRow></TableHead>
                    <TableBody>{employeeQuery.data.map((employee) => (
                      <TableRow key={employee.id} hover>
                        <TableCell>{employee.employee_code || '—'}</TableCell>
                        <TableCell>{fullName(employee) || '—'}</TableCell>
                        <TableCell><StatusChip label={employee.is_active ? 'Active' : 'Inactive'} /></TableCell>
                      </TableRow>
                    ))}</TableBody>
                  </Table>
                </TableContainer>
              )}
        </Paper>
      ) : null}
      <Paper variant="outlined" sx={{ overflow: 'hidden' }}>
        {rowsQuery.isLoading ? <LoadingState label={'Loading ' + page.title.toLowerCase() + '…'} />
          : rowsQuery.isError ? <Box sx={{ minHeight: 100 }} />
            : filteredRows.length === 0 ? (
              <EmptyState title={'No ' + page.title.toLowerCase() + ' found'}
                description={search ? 'Try a different search or filter.' : 'Add a ' + page.singular.toLowerCase() + ' to get started.'} />
            ) : (
              <>
                <TableContainer sx={{ overflowX: 'auto' }}>
                  <Table size="small" aria-label={page.title} sx={{ minWidth: 650 }}>
                    <TableHead>
                      <TableRow>
                        <TableCell width="55">#</TableCell>
                        <TableCell>{page.singular} Name</TableCell>
                        <TableCell>{page.secondColumn}</TableCell>
                        <TableCell align="center">Employee Count</TableCell>
                        <TableCell>Status</TableCell>
                        <TableCell align="right">Actions</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {pageRows.map((row, index) => (
                        <TableRow key={row.id} hover>
                          <TableCell>{pageNumber * rowsPerPage + index + 1}</TableCell>
                          <TableCell><Typography variant="body2" fontWeight={600}>{row.name}</Typography></TableCell>
                          <TableCell>
                            {row[page.secondValue] || '—'}
                            {page.showBranchUnderParent && row.branch_name ? (
                              <Typography variant="caption" display="block" color="text.secondary">{row.branch_name}</Typography>
                            ) : null}
                          </TableCell>
                          <TableCell align="center">
                            <Button size="small" onClick={() => openEmployeeList(row)}
                              aria-label={'View ' + row.employee_count + ' employees in ' + row.name}>
                              {row.employee_count}
                            </Button>
                          </TableCell>
                          <TableCell><StatusChip label={row.is_active ? 'Active' : 'Inactive'} /></TableCell>
                          <TableCell align="right">
                            {canChange ? (
                              <Tooltip title={'Edit ' + page.singular.toLowerCase()}>
                                <IconButton size="small" aria-label={'Edit ' + row.name}
                                  onClick={() => openEdit(row)} disabled={loadingDetailId === row.id}>
                                  <Pencil size={16} />
                                </IconButton>
                              </Tooltip>
                            ) : null}
                            {canChange ? (
                              <Tooltip title={row.is_active ? 'Deactivate' : 'Activate'}>
                                <Switch size="small" checked={row.is_active}
                                  onChange={(_, value) => statusMutation.mutate({ row, is_active: value })}
                                  disabled={statusMutation.isPending}
                                  inputProps={{ 'aria-label': (row.is_active ? 'Deactivate ' : 'Activate ') + row.name }} />
                              </Tooltip>
                            ) : null}
                            {canChange ? (
                              <Tooltip title={'Delete ' + page.singular.toLowerCase()}>
                                <IconButton size="small" color="error" aria-label={'Delete ' + row.name}
                                  onClick={() => { deleteMutation.reset(); setDeleting(row) }}>
                                  <Trash2 size={16} />
                                </IconButton>
                              </Tooltip>
                            ) : null}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
                <TablePagination component="div" count={filteredRows.length} page={pageNumber}
                  onPageChange={(_, next) => setPageNumber(next)} rowsPerPage={rowsPerPage}
                  onRowsPerPageChange={(event) => { setRowsPerPage(Number(event.target.value)); setPageNumber(0) }}
                  rowsPerPageOptions={PAGE_SIZE_OPTIONS} labelRowsPerPage="Rows" />
              </>
            )}
      </Paper>

      <Dialog open={dialogOpen} onClose={() => !saveMutation.isPending && setDialogOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>{editing ? 'Edit ' + page.singular : 'Add ' + page.singular}</DialogTitle>
        <DialogContent sx={{ display: 'grid', gap: 2, pt: '12px !important' }}>
          <TextField autoFocus required label={page.singular + ' Name'} value={form.name}
            onChange={(event) => setForm((current) => ({ ...current, name: event.target.value }))} inputProps={{ maxLength: 150 }} />
          <TextField select required label={page.parentLabel} value={form.parentId}
            onChange={(event) => setForm((current) => ({ ...current, parentId: event.target.value }))}
            disabled={Boolean(editing && (editing.employee_count > 0 || (page.lockParentWhenRelatedRecords && editing.designation_count > 0)))}>
            {parents.filter((parent) => parent.is_active || String(parent.id) === form.parentId)
              .map((parent) => <MenuItem key={parent.id} value={String(parent.id)}>{parent.name}</MenuItem>)}
          </TextField>
          {editing && (editing.employee_count > 0 || (page.lockParentWhenRelatedRecords && editing.designation_count > 0)) ? (
            <Typography variant="caption" color="text.secondary">
              The {page.parentLabel.toLowerCase()} cannot be changed while employees or designations use this record.
            </Typography>
          ) : null}
          {saveMutation.isError ? <Alert severity="error">{requestError(saveMutation.error)}</Alert> : null}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)} disabled={saveMutation.isPending}>Cancel</Button>
          <Button variant="contained" onClick={() => saveMutation.mutate()}
            disabled={saveMutation.isPending || !form.name.trim() || !form.parentId}>
            {editing ? 'Save changes' : 'Add ' + page.singular}
          </Button>
        </DialogActions>
      </Dialog>
      <Dialog open={Boolean(deleting)} onClose={() => !deleteMutation.isPending && setDeleting(null)}>
        <DialogTitle>Delete {page.singular.toLowerCase()}?</DialogTitle>
        <DialogContent>
          <Typography>{deleting?.name} will be deleted if no employees or related records use it.</Typography>
          {deleteMutation.isError ? <Alert severity="error" sx={{ mt: 2 }}>{requestError(deleteMutation.error)}</Alert> : null}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleting(null)} disabled={deleteMutation.isPending}>Cancel</Button>
          <Button color="error" variant="contained" onClick={() => deleteMutation.mutate(deleting)}
            disabled={deleteMutation.isPending}>Delete</Button>
        </DialogActions>
      </Dialog>
      <Snackbar open={Boolean(notice)} autoHideDuration={4000} onClose={() => setNotice(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
        {notice ? <Alert severity={notice.severity} variant="filled" onClose={() => setNotice(null)}>{notice.message}</Alert> : undefined}
      </Snackbar>
    </Box>
  )
}

