import { useEffect, useMemo, useState } from 'react'
import { Alert, Box, Button, Card, CardContent, Checkbox, CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle, Grid, MenuItem, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TextField, Typography } from '@mui/material'
import { PageHeader } from '../../../components/common/PageHeader'
import { SearchInput } from '../../../components/common/SearchInput'
import apiClient from '../../../services/apiClient'

const emptyForm = {
  first_name: '', last_name: '', phone_number: '', email: '', employee_code: '',
  branch: '', department: '', designation: '', joining_date: '', is_active: true,
}

function responseData(response) {
  return response.data?.data ?? response.data
}

function errorMessage(error) {
  const data = error.response?.data
  if (data?.detail) return data.detail
  if (data?.errors) return Object.values(data.errors).flat().join(' ')
  return data?.message ?? error.message ?? 'Unable to load employees.'
}

export function EmployeesPage() {
  const [query, setQuery] = useState('')
  const [rows, setRows] = useState([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [pageError, setPageError] = useState('')
  const [dialogError, setDialogError] = useState('')
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editingId, setEditingId] = useState(null)
  const [form, setForm] = useState(emptyForm)

  const loadEmployees = async () => {
    setLoading(true)
    setPageError('')
    try {
      const response = await apiClient.get('/employees/')
      const data = responseData(response)
      setRows(Array.isArray(data) ? data : [])
    } catch (error) {
      setPageError(errorMessage(error))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { loadEmployees() }, [])

  const filteredRows = useMemo(() => rows.filter((row) =>
    [row.first_name, row.last_name, row.name, row.employee_code, row.phone_number, row.email]
      .filter(Boolean).join(' ').toLowerCase().includes(query.toLowerCase())), [rows, query])

  const openCreate = () => {
    setEditingId(null)
    setForm(emptyForm)
    setDialogError('')
    setDialogOpen(true)
  }

  const openEdit = (row) => {
    setEditingId(row.id)
    setForm({
      first_name: row.first_name ?? '', last_name: row.last_name ?? '',
      phone_number: row.phone_number ?? '', email: row.email ?? '',
      employee_code: row.employee_code ?? '', branch: row.branch ?? '',
      department: row.department ?? '', designation: row.designation ?? '',
      joining_date: row.joining_date ?? '', is_active: Boolean(row.is_active),
    })
    setDialogError('')
    setDialogOpen(true)
  }

  const saveEmployee = async (event) => {
    event.preventDefault()
    setSaving(true)
    setDialogError('')
    const payload = { ...form }
    for (const field of ['branch', 'department', 'designation']) {
      payload[field] = payload[field] === '' ? null : Number(payload[field])
    }
    payload.joining_date = payload.joining_date || null
    try {
      if (editingId) await apiClient.patch(`/employees/${editingId}/`, payload)
      else await apiClient.post('/employees/', payload)
      setDialogOpen(false)
      await loadEmployees()
    } catch (error) {
      setDialogError(errorMessage(error))
    } finally {
      setSaving(false)
    }
  }

  const updateField = (event) => {
    const { name, value, type, checked } = event.target
    setForm((current) => ({ ...current, [name]: type === 'checkbox' ? checked : value }))
  }

  return (
    <div>
      <PageHeader title="Employees" subtitle="Manage workforce details and employee records" action={<Button variant="contained" onClick={openCreate}>Add Employee</Button>} />
      <Card>
        <CardContent sx={{ p: 2.5 }}>
          <SearchInput value={query} onChange={setQuery} placeholder="Search employee" />
          <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1 }}>
            Branch, department, and designation fields accept existing database IDs.
          </Typography>
        </CardContent>
      </Card>
      {pageError ? <Alert severity="error" sx={{ mt: 2 }}>{pageError}</Alert> : null}
      <Paper sx={{ mt: 3, overflow: 'hidden' }}>
        <TableContainer>
          <Table>
            <TableHead><TableRow>
              <TableCell>Employee</TableCell><TableCell>Employee Code</TableCell><TableCell>Phone</TableCell>
              <TableCell>Email</TableCell><TableCell>Department ID</TableCell><TableCell>Status</TableCell><TableCell />
            </TableRow></TableHead>
            <TableBody>
              {loading ? <TableRow><TableCell colSpan={7} align="center"><CircularProgress size={24} /></TableCell></TableRow>
                : filteredRows.map((row) => <TableRow key={row.id} hover>
                  <TableCell>{[row.first_name, row.last_name].filter(Boolean).join(' ') || row.name}</TableCell>
                  <TableCell>{row.employee_code}</TableCell><TableCell>{row.phone_number}</TableCell>
                  <TableCell>{row.email}</TableCell><TableCell>{row.department ?? '—'}</TableCell>
                  <TableCell><Typography color={row.is_active ? 'success.main' : 'text.secondary'} sx={{ fontWeight: 600 }}>{row.is_active ? 'Active' : 'Inactive'}</Typography></TableCell>
                  <TableCell align="right"><Button size="small" onClick={() => openEdit(row)}>Edit</Button></TableCell>
                </TableRow>)}
              {!loading && filteredRows.length === 0 ? <TableRow><TableCell colSpan={7} align="center">No employees found.</TableCell></TableRow> : null}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      <Dialog open={dialogOpen} onClose={() => !saving && setDialogOpen(false)} fullWidth maxWidth="md">
        <Box component="form" onSubmit={saveEmployee}>
          <DialogTitle>{editingId ? 'Edit Employee' : 'Add Employee'}</DialogTitle>
          <DialogContent>
            {dialogError ? <Alert severity="error" sx={{ mb: 2 }}>{dialogError}</Alert> : null}
            <Grid container spacing={2} sx={{ pt: 1 }}>
              {[
                ['first_name', 'First name', true], ['last_name', 'Last name', true],
                ['phone_number', 'Mobile number', true], ['email', 'Email', true],
                ['employee_code', 'Employee code', true], ['branch', 'Branch ID'],
                ['department', 'Department ID'], ['designation', 'Designation ID'],
                ['joining_date', 'Joining date'],
              ].map(([name, label, required]) => <Grid key={name} size={{ xs: 12, sm: 6 }}>
                <TextField fullWidth name={name} label={label} value={form[name]} onChange={updateField}
                  required={Boolean(required)} type={name === 'joining_date' ? 'date' : name.endsWith('branch') || ['branch', 'department', 'designation'].includes(name) ? 'number' : 'text'}
                  slotProps={name === 'joining_date' ? { inputLabel: { shrink: true } } : undefined}
                  disabled={saving} />
              </Grid>)}
              <Grid size={{ xs: 12 }}>
                <Box sx={{ display: 'flex', alignItems: 'center' }}>
                  <Checkbox name="is_active" checked={form.is_active} onChange={updateField} disabled={saving} />
                  <Typography>Active employee</Typography>
                </Box>
              </Grid>
            </Grid>
          </DialogContent>
          <DialogActions sx={{ px: 3, pb: 2 }}>
            <Button onClick={() => setDialogOpen(false)} disabled={saving}>Cancel</Button>
            <Button type="submit" variant="contained" disabled={saving}>{saving ? 'Saving…' : 'Save Employee'}</Button>
          </DialogActions>
        </Box>
      </Dialog>
    </div>
  )
}
