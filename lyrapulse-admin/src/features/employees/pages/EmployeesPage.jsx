import { useEffect, useMemo, useState } from 'react'
import { Alert, Box, Button, Card, CardContent, CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle, Divider, FormControlLabel, Grid, MenuItem, Paper, Snackbar, Switch, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TextField, Typography } from '@mui/material'
import { PageHeader } from '../../../components/common/PageHeader'
import { SearchInput } from '../../../components/common/SearchInput'
import { EmptyState } from '../../../components/common/EmptyState'
import { ErrorState } from '../../../components/common/ErrorState'
import { StatusChip } from '../../../components/common/StatusChip'
import apiClient from '../../../services/apiClient'

const emptyForm = {
  first_name: '', last_name: '', phone_number: '', email: '', employee_code: '',
  branch: '', department: '', designation: '', joining_date: '', is_active: true,
}

const emptyOptions = { branches: [], departments: [], designations: [] }
const sameId = (left, right) => left !== '' && left != null && right !== '' && right != null && String(left) === String(right)

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

function SectionHeading({ children }) {
  return (
    <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1.5 }}>
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
    [row.first_name, row.last_name, row.name, row.employee_code, row.phone_number, row.email]
      .filter(Boolean).join(' ').toLowerCase().includes(query.trim().toLowerCase())), [rows, query])

  const departmentNames = useMemo(
    () => new Map(options.departments.map((department) => [String(department.id), department.name])),
    [options.departments],
  )

  const branchOptions = useMemo(
    () => options.branches.filter((item) => item.is_active || sameId(item.id, form.branch)),
    [options.branches, form.branch],
  )
  const departmentOptions = useMemo(
    () => options.departments.filter((item) => sameId(item.id, form.department) || (sameId(item.branch, form.branch) && item.is_active)),
    [options.departments, form.branch, form.department],
  )
  const designationOptions = useMemo(
    () => options.designations.filter((item) => sameId(item.id, form.designation) || (sameId(item.department, form.department) && item.is_active)),
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
      const department = options.departments.find((item) => sameId(item.id, current.department))
      const keepDepartment = department && sameId(department.branch, branch)
      const designation = options.designations.find((item) => sameId(item.id, current.designation))
      const keepDesignation = keepDepartment && designation && sameId(designation.department, current.department)
      return {
        ...current,
        branch,
        department: keepDepartment ? current.department : '',
        designation: keepDesignation ? current.designation : '',
      }
    })
  }

  const changeDepartment = (event) => {
    const department = event.target.value
    setForm((current) => {
      const designation = options.designations.find((item) => sameId(item.id, current.designation))
      const keepDesignation = designation && sameId(designation.department, department)
      return { ...current, department, designation: keepDesignation ? current.designation : '' }
    })
  }

  const textField = (name, label, props = {}) => (
    <Grid size={{ xs: 12, sm: 6 }}>
      <TextField fullWidth name={name} label={label} value={form[name]} onChange={updateField} disabled={saving} {...props} />
    </Grid>
  )

  const selectField = ({ name, label, items, onChange, placeholder, parentMissing, parentLabel }) => {
    const hasValue = form[name] !== '' && items.some((item) => sameId(item.id, form[name]))
    return (
      <Grid size={{ xs: 12, sm: 6 }}>
        <TextField
          select
          fullWidth
          name={name}
          label={label}
          value={hasValue ? form[name] : ''}
          onChange={onChange}
          disabled={saving || optionsLoading || Boolean(optionsError) || parentMissing}
          helperText={parentMissing ? `Select a ${parentLabel} first` : optionsError || undefined}
          slotProps={{
            inputLabel: { shrink: true },
            select: { displayEmpty: true, MenuProps: { slotProps: { paper: { sx: { maxHeight: 280 } } } } },
          }}
        >
          <MenuItem value="">
            <Typography component="span" color="text.secondary">
              {optionsLoading ? 'Loading options…' : placeholder}
            </Typography>
          </MenuItem>
          {items.map((item) => (
            <MenuItem key={item.id} value={item.id}>
              {item.is_active ? item.name : `${item.name} (inactive)`}
            </MenuItem>
          ))}
        </TextField>
      </Grid>
    )
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

      <Dialog open={dialogOpen} onClose={() => !saving && setDialogOpen(false)} fullWidth maxWidth="md" scroll="paper">
        <Box component="form" onSubmit={saveEmployee} noValidate>
          <DialogTitle>{editingId ? 'Edit employee' : 'Add employee'}</DialogTitle>
          <DialogContent dividers>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2.5 }}>
              {editingId ? 'Update the employee’s personal and employment information.' : 'Add contact details and assign the employee to an organization unit.'}
            </Typography>
            {dialogError ? <Alert severity="error" sx={{ mb: 2 }}>{dialogError}</Alert> : null}
            {optionsError ? (
              <Alert severity="warning" sx={{ mb: 2 }} action={<Button color="inherit" size="small" onClick={loadOptions} disabled={optionsLoading}>Retry</Button>}>
                Organization options could not be loaded. Existing selections are preserved. {optionsError}
              </Alert>
            ) : null}

            <SectionHeading>Personal information</SectionHeading>
            <Grid container spacing={2}>
              {textField('first_name', 'First name', { required: true, autoComplete: 'given-name' })}
              {textField('last_name', 'Last name', { required: true, autoComplete: 'family-name' })}
              {textField('phone_number', 'Mobile number', { required: true, type: 'tel', autoComplete: 'tel' })}
              {textField('email', 'Email address', { required: true, type: 'email', autoComplete: 'email' })}
            </Grid>

            <Divider sx={{ my: 2.5 }} />
            <SectionHeading>Employment information</SectionHeading>
            <Grid container spacing={2}>
              {textField('employee_code', 'Employee code', { required: true })}
              {textField('joining_date', 'Joining date', { type: 'date', slotProps: { inputLabel: { shrink: true } } })}
              {selectField({ name: 'branch', label: 'Branch', items: branchOptions, onChange: changeBranch, placeholder: 'Select branch' })}
              {selectField({ name: 'department', label: 'Department', items: departmentOptions, onChange: changeDepartment, placeholder: 'Select department', parentMissing: form.branch === '', parentLabel: 'branch' })}
              {selectField({ name: 'designation', label: 'Designation', items: designationOptions, onChange: updateField, placeholder: 'Select designation', parentMissing: form.department === '', parentLabel: 'department' })}
            </Grid>

            <Divider sx={{ my: 2.5 }} />
            <SectionHeading>Status</SectionHeading>
            <FormControlLabel
              control={<Switch name="is_active" checked={form.is_active} onChange={updateField} disabled={saving} />}
              label={form.is_active ? 'Active employee' : 'Inactive employee'}
            />
          </DialogContent>
          <DialogActions>
            <Button type="button" variant="outlined" onClick={() => setDialogOpen(false)} disabled={saving}>Cancel</Button>
            <Button type="submit" variant="contained" disabled={saving}>
              {saving ? 'Saving…' : editingId ? 'Save changes' : 'Add employee'}
            </Button>
          </DialogActions>
        </Box>
      </Dialog>

      <Snackbar open={Boolean(notice)} autoHideDuration={4000} onClose={() => setNotice('')} anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
        <Alert severity="success" variant="filled" onClose={() => setNotice('')}>{notice}</Alert>
      </Snackbar>
    </Box>
  )
}