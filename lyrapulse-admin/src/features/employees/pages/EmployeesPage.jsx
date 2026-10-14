import { useEffect, useMemo, useState } from 'react'
import { Alert, Box, Button, Card, CardContent, CircularProgress, Paper, Snackbar, Table, TableBody, TableCell, TableContainer, TableHead, TableRow } from '@mui/material'
import { PageHeader } from '../../../components/common/PageHeader'
import { SearchInput } from '../../../components/common/SearchInput'
import { EmptyState } from '../../../components/common/EmptyState'
import { ErrorState } from '../../../components/common/ErrorState'
import { StatusChip } from '../../../components/common/StatusChip'
import apiClient from '../../../services/apiClient'
import { EmployeeDetailsPanel } from '../components/EmployeeDetailsPanel'

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

export function EmployeesPage() {
  const [query, setQuery] = useState('')
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [pageError, setPageError] = useState('')
  const [panelOpen, setPanelOpen] = useState(false)
  const [editingId, setEditingId] = useState(null)
  const [options, setOptions] = useState(emptyOptions)
  const [optionsLoading, setOptionsLoading] = useState(true)
  const [optionsError, setOptionsError] = useState('')
  const [notice, setNotice] = useState('')

  const loadEmployees = async () => {
    setLoading(true)
    setPageError('')
    try {
      const response = await apiClient.get('/employees/')
      setRows(listData(response))
    } catch (error) {
      setPageError(errorMessage(error))
    } finally {
      setLoading(false)
    }
  }

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
  }, [])

  const filteredRows = useMemo(() => rows.filter((row) =>
    [row.first_name, row.last_name, row.name, row.display_name, row.employee_code, row.phone_number, row.email]
      .filter(Boolean).join(' ').toLowerCase().includes(query.trim().toLowerCase())), [rows, query])

  const departmentNames = useMemo(
    () => new Map(options.departments.map((department) => [String(department.id), department.name])),
    [options.departments],
  )

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

  return (
    <Box>
      <PageHeader
        title="Employees"
        subtitle="Manage employee profiles, assignments, and account status."
        action={<Button variant="contained" onClick={openCreate}>Add employee</Button>}
      />

      <Card sx={{ mb: 2 }}>
        <CardContent sx={{ p: { xs: 1.5, sm: 2 } }}>
          <SearchInput value={query} onChange={setQuery} label="Search employees" placeholder="Search by name, code, phone, or email" />
        </CardContent>
      </Card>

      {pageError ? <ErrorState message={pageError} onRetry={loadEmployees} retrying={loading} /> : null}

      <Paper sx={{ overflow: 'hidden' }}>
        {loading ? (
          <Box sx={{ py: 5, display: 'flex', justifyContent: 'center' }}><CircularProgress size={26} aria-label="Loading employees" /></Box>
        ) : pageError ? (
          <Box sx={{ minHeight: 96 }} />
        ) : filteredRows.length === 0 ? (
          <EmptyState
            title={query ? 'No matching employees' : 'No employees yet'}
            description={query ? 'Try another search term.' : 'Add an employee to start building your workforce directory.'}
            actionLabel={!query ? 'Add employee' : undefined}
            onAction={!query ? openCreate : undefined}
          />
        ) : (
          <TableContainer sx={{ border: 0, borderRadius: 0 }}>
            <Table aria-label="Employees" sx={{ minWidth: 900 }}>
              <TableHead>
                <TableRow>
                  <TableCell>Employee</TableCell>
                  <TableCell>Employee code</TableCell>
                  <TableCell>Phone</TableCell>
                  <TableCell>Email</TableCell>
                  <TableCell>Department</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {filteredRows.map((row) => (
                  <TableRow key={row.id} hover>
                    <TableCell sx={{ fontWeight: 600 }}>{[row.first_name, row.last_name].filter(Boolean).join(' ') || row.name}</TableCell>
                    <TableCell>{row.employee_code}</TableCell>
                    <TableCell>{row.phone_number}</TableCell>
                    <TableCell>{row.email || '—'}</TableCell>
                    <TableCell>{departmentNames.get(String(row.department)) ?? '—'}</TableCell>
                    <TableCell><StatusChip label={row.is_active ? 'Active' : 'Inactive'} /></TableCell>
                    <TableCell align="right"><Button size="small" onClick={() => openEdit(row)} aria-label={`Edit ${row.first_name || row.name || row.employee_code}`}>Edit</Button></TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Paper>

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