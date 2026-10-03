import { useEffect, useMemo, useState } from 'react'
import { Alert, Box, Button, Card, CardContent, CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle, FormControlLabel, Grid, MenuItem, Paper, Snackbar, Switch, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TextField, Typography } from '@mui/material'
import { PageHeader } from '../../../components/common/PageHeader'
import { SearchInput } from '../../../components/common/SearchInput'
import apiClient from '../../../services/apiClient'

const emptyForm = {
  first_name: '', last_name: '', phone_number: '', email: '', employee_code: '',
  branch: '', department: '', designation: '', joining_date: '', is_active: true,
}

const emptyOptions = { branches: [], departments: [], designations: [] }

function responseData(response) {
  return response.data?.data ?? response.data
}

function listData(response) {
  const data = responseData(response)
  return Array.isArray(data) ? data : []
}

function errorMessage(error) {
  const data = error.response?.data
  if (data?.detail) return data.detail
  if (data?.errors) return Object.values(data.errors).flat().join(' ')
  return data?.message ?? error.message ?? 'Unable to load employees.'
}

function SectionLabel({ children }) {
  return (
    <Typography variant="overline" color="text.secondary" sx={{ display: 'block', fontWeight: 700, letterSpacing: '0.08em', lineHeight: 1.5 }}>
      {children}
    </Typography>
  )
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
  const [options, setOptions] = useState(emptyOptions)
  const [optionsLoading, setOptionsLoading] = useState(true)
  const [optionsError, setOptionsError] = useState('')
  const [notice, setNotice] = useState('')

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

  // Inactive records are included so an employee's current assignment can always be shown while editing.
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

  useEffect(() => { loadEmployees(); loadOptions() }, [])

  const filteredRows = useMemo(() => rows.filter((row) =>
    [row.first_name, row.last_name, row.name, row.employee_code, row.phone_number, row.email]
      .filter(Boolean).join(' ').toLowerCase().includes(query.toLowerCase())), [rows, query])

  const departmentNames = useMemo(
    () => new Map(options.departments.map((department) => [department.id, department.name])),
    [options.departments],
  )

  // Each list shows active records that belong to the parent selection, plus the current value so it never disappears.
  const branchOptions = useMemo(
    () => options.branches.filter((item) => item.is_active || item.id === form.branch),
    [options.branches, form.branch],
  )
  const departmentOptions = useMemo(
    () => options.departments.filter((item) => item.id === form.department || (item.branch === form.branch && item.is_active)),
    [options.departments, form.branch, form.department],
  )
  const designationOptions = useMemo(
    () => options.designations.filter((item) => item.id === form.designation || (item.department === form.department && item.is_active)),
    [options.designations, form.department, form.designation],
  )

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
    if (saving) return
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
      setNotice(editingId ? 'Employee updated successfully.' : 'Employee added successfully.')
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

  const changeBranch = (event) => {
    const branch = event.target.value
    setForm((current) => {
      const department = options.departments.find((item) => item.id === current.department)
      const keepDepartment = department && department.branch === branch
      const designation = options.designations.find((item) => item.id === current.designation)
      const keepDesignation = keepDepartment && designation && designation.department === current.department
      return {
        ...current, branch,
        department: keepDepartment ? current.department : '',
        designation: keepDesignation ? current.designation : '',
      }
    })
  }

  const changeDepartment = (event) => {
    const department = event.target.value
    setForm((current) => {
      const designation = options.designations.find((item) => item.id === current.designation)
      const keepDesignation = designation && designation.department === department
      return { ...current, department, designation: keepDesignation ? current.designation : '' }
    })
  }

  const textField = (name, label, props = {}) => (
    <Grid size={{ xs: 12, sm: 6 }}>
      <TextField fullWidth name={name} label={label} value={form[name]} onChange={updateField} disabled={saving} {...props} />
    </Grid>
  )

  const selectField = ({ name, label, items, onChange, placeholder, parentMissing, parentLabel }) => {
    const hasValue = form[name] !== '' && items.some((item) => item.id === form[name])
    return (
      <Grid size={{ xs: 12 }}>
        <TextField
          select fullWidth name={name} label={label}
          value={hasValue ? form[name] : ''}
          onChange={onChange}
          disabled={saving || optionsLoading || Boolean(optionsError) || parentMissing}
          helperText={parentMissing && !optionsLoading ? `Select a ${parentLabel} first` : undefined}
          slotProps={{ inputLabel: { shrink: true }, select: { displayEmpty: true, MenuProps: { slotProps: { paper: { sx: { maxHeight: 280 } } } } } }}
        >
          <MenuItem value="">
            <Typography component="span" color="text.secondary">{optionsLoading ? 'Loading…' : placeholder}</Typography>
          </MenuItem>
          {items.map((item) => (
            <MenuItem key={item.id} value={item.id}>{item.is_active ? item.name : `${item.name} (inactive)`}</MenuItem>
          ))}
        </TextField>
      </Grid>
    )
  }

  return (
    <div>
      <PageHeader title="Employees" subtitle="Manage workforce details and employee records" action={<Button variant="contained" onClick={openCreate}>Add Employee</Button>} />
      <Card>
        <CardContent sx={{ p: 2.5 }}>
          <SearchInput value={query} onChange={setQuery} placeholder="Search employee" />
        </CardContent>
      </Card>
      {pageError ? <Alert severity="error" sx={{ mt: 2 }}>{pageError}</Alert> : null}
      <Paper sx={{ mt: 3, overflow: 'hidden' }}>
        <TableContainer>
          <Table>
            <TableHead><TableRow>
              <TableCell>Employee</TableCell><TableCell>Employee Code</TableCell><TableCell>Phone</TableCell>
              <TableCell>Email</TableCell><TableCell>Department</TableCell><TableCell>Status</TableCell><TableCell />
            </TableRow></TableHead>
            <TableBody>
              {loading ? <TableRow><TableCell colSpan={7} align="center"><CircularProgress size={24} /></TableCell></TableRow>
                : filteredRows.map((row) => <TableRow key={row.id} hover>
                  <TableCell>{[row.first_name, row.last_name].filter(Boolean).join(' ') || row.name}</TableCell>
                  <TableCell>{row.employee_code}</TableCell><TableCell>{row.phone_number}</TableCell>
                  <TableCell>{row.email}</TableCell><TableCell>{departmentNames.get(row.department) ?? '—'}</TableCell>
                  <TableCell><Typography color={row.is_active ? 'success.main' : 'text.secondary'} sx={{ fontWeight: 600 }}>{row.is_active ? 'Active' : 'Inactive'}</Typography></TableCell>
                  <TableCell align="right"><Button size="small" onClick={() => openEdit(row)}>Edit</Button></TableCell>
                </TableRow>)}
              {!loading && filteredRows.length === 0 ? <TableRow><TableCell colSpan={7} align="center">No employees found.</TableCell></TableRow> : null}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      <Dialog open={dialogOpen} onClose={() => !saving && setDialogOpen(false)} fullWidth maxWidth="sm">
        <Box component="form" onSubmit={saveEmployee} sx={{ display: 'flex', flexDirection: 'column', minHeight: 0, overflow: 'hidden' }}>
          <DialogTitle sx={{ pb: 0.5 }}>{editingId ? 'Edit Employee' : 'Add Employee'}</DialogTitle>
          <Typography variant="body2" color="text.secondary" sx={{ px: 3, pb: 1.5 }}>
            {editingId ? 'Update personal and employment details.' : 'Enter personal and employment details.'}
          </Typography>
          <DialogContent dividers sx={{ borderColor: 'divider' }}>
            {dialogError ? <Alert severity="error" sx={{ mb: 2 }}>{dialogError}</Alert> : null}
            {optionsError ? (
              <Alert severity="warning" sx={{ mb: 2 }} action={<Button color="inherit" size="small" onClick={loadOptions} disabled={optionsLoading}>Retry</Button>}>
                Unable to load branches, departments and designations. {optionsError} Existing assignments will be kept.
              </Alert>
            ) : null}
            <SectionLabel>Personal details</SectionLabel>
            <Grid container spacing={2} sx={{ mt: 0.5, mb: 3 }}>
              {textField('first_name', 'First Name', { required: true })}
              {textField('last_name', 'Last Name', { required: true })}
              {textField('phone_number', 'Mobile Number', { required: true, type: 'tel' })}
              {textField('email', 'Email', { required: true, type: 'email' })}
            </Grid>
            <SectionLabel>Employment details</SectionLabel>
            <Grid container spacing={2} sx={{ mt: 0.5 }}>
              {textField('employee_code', 'Employee Code', { required: true })}
              {textField('joining_date', 'Joining Date', { type: 'date', slotProps: { inputLabel: { shrink: true } } })}
              {selectField({ name: 'branch', label: 'Branch', items: branchOptions, onChange: changeBranch, placeholder: 'Select branch' })}
              {selectField({ name: 'department', label: 'Department', items: departmentOptions, onChange: changeDepartment, placeholder: 'Select department', parentMissing: form.branch === '', parentLabel: 'branch' })}
              {selectField({ name: 'designation', label: 'Designation', items: designationOptions, onChange: updateField, placeholder: 'Select designation', parentMissing: form.department === '', parentLabel: 'department' })}
              <Grid size={{ xs: 12 }}>
                <Box sx={{ border: 1, borderColor: 'divider', borderRadius: 2, bgcolor: 'background.default', px: 2, py: 0.5 }}>
                  <FormControlLabel
                    sx={{ width: '100%', m: 0, justifyContent: 'space-between' }}
                    labelPlacement="start"
                    label={<Typography sx={{ fontWeight: 600 }}>Active Employee</Typography>}
                    control={<Switch name="is_active" checked={form.is_active} onChange={updateField} disabled={saving} />}
                  />
                </Box>
              </Grid>
            </Grid>
          </DialogContent>
          <DialogActions sx={{ px: 3, py: 2 }}>
            <Button onClick={() => setDialogOpen(false)} disabled={saving}>Cancel</Button>
            <Button type="submit" variant="contained" disabled={saving}>{saving ? 'Saving…' : 'Save Employee'}</Button>
          </DialogActions>
        </Box>
      </Dialog>

      <Snackbar open={Boolean(notice)} autoHideDuration={4000} onClose={() => setNotice('')} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
        <Alert severity="success" variant="filled" onClose={() => setNotice('')}>{notice}</Alert>
      </Snackbar>
    </div>
  )
}