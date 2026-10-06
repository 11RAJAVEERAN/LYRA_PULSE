import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Alert, Box, Button, Card, CardContent, FormControlLabel, Grid, MenuItem, Paper, Stack, Switch, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TextField, Typography } from '@mui/material'
import { EmptyState } from '../../../components/common/EmptyState'
import { ErrorState } from '../../../components/common/ErrorState'
import { LoadingState } from '../../../components/common/LoadingState'
import { PageHeader } from '../../../components/common/PageHeader'
import { StatusChip } from '../../../components/common/StatusChip'
import { adminUsersApi } from '../api/adminUsersApi'

const emptyForm = { phone_number: '', email: '', first_name: '', last_name: '', role: 'ADMIN', is_active: true, permissions: '' }

function getErrorMessage(error) {
  const data = error?.response?.data
  if (data?.detail) return data.detail
  if (data?.errors && typeof data.errors === 'object') {
    return Object.entries(data.errors).map(([field, messages]) => `${field}: ${Array.isArray(messages) ? messages.join(' ') : messages}`).join(' ')
  }
  return data?.message ?? error?.message ?? 'Unable to complete this request.'
}

export function AdminUsersPage() {
  const { data: users = [], error: queryError, isLoading, refetch, isFetching } = useQuery({ queryKey: ['admin-users'], queryFn: adminUsersApi.list })
  const [form, setForm] = useState(emptyForm)
  const [editingId, setEditingId] = useState(null)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)

  const updateField = (field) => (event) => setForm((current) => ({ ...current, [field]: event.target.value }))

  const submitForm = async (event) => {
    event.preventDefault()
    if (busy) return
    setBusy(true)
    setError('')
    setMessage('')
    try {
      const payload = { ...form, permissions: form.permissions.split(',').map((value) => value.trim()).filter(Boolean) }
      if (editingId) await adminUsersApi.update(editingId, payload)
      else await adminUsersApi.create(payload)
      const wasEditing = Boolean(editingId)
      setForm(emptyForm)
      setEditingId(null)
      setMessage(wasEditing ? 'Account updated.' : 'Account created. The account can sign in with an OTP sent to its registered mobile.')
      await refetch()
    } catch (requestError) {
      setError(getErrorMessage(requestError))
    } finally {
      setBusy(false)
    }
  }

  const toggleActive = async (user) => {
    setError('')
    try {
      await adminUsersApi.update(user.id, { is_active: !user.is_active })
      await refetch()
    } catch (requestError) {
      setError(getErrorMessage(requestError))
    }
  }

  const editUser = (user) => {
    setEditingId(user.id)
    setForm({
      phone_number: user.phone_number,
      email: user.email || '',
      first_name: user.first_name || '',
      last_name: user.last_name || '',
      role: user.role,
      is_active: user.is_active,
      permissions: (user.permission_codenames || []).join(', '),
    })
    setError('')
    setMessage('')
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  const cancelEdit = () => {
    setEditingId(null)
    setForm(emptyForm)
    setError('')
    setMessage('')
  }

  return (
    <Box>
      <PageHeader title="Admin users" subtitle="Manage administrator, HR, and manager access." />

      {error ? <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert> : null}
      {queryError ? <ErrorState message={getErrorMessage(queryError)} onRetry={() => refetch()} retrying={isFetching} /> : null}
      {message ? <Alert severity="success" sx={{ mb: 2 }}>{message}</Alert> : null}

      <Card sx={{ mb: 2.5 }}>
        <CardContent sx={{ p: { xs: 2, md: 3 } }}>
          <Stack spacing={2.5}>
            <Box>
              <Typography variant="h6" component="h2">{editingId ? 'Edit account' : 'Create account'}</Typography>
              <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                Assign a role and optional Django permissions for this account.
              </Typography>
            </Box>

            <Box component="form" onSubmit={submitForm} noValidate>
              <Grid container spacing={2}>
                <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
                  <TextField required fullWidth label="Mobile number" value={form.phone_number} onChange={updateField('phone_number')} disabled={busy} />
                </Grid>
                <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
                  <TextField fullWidth label="Email" type="email" value={form.email} onChange={updateField('email')} disabled={busy} />
                </Grid>
                <Grid size={{ xs: 12, sm: 6, lg: 2 }}>
                  <TextField required fullWidth label="First name" value={form.first_name} onChange={updateField('first_name')} disabled={busy} />
                </Grid>
                <Grid size={{ xs: 12, sm: 6, lg: 2 }}>
                  <TextField fullWidth label="Last name" value={form.last_name} onChange={updateField('last_name')} disabled={busy} />
                </Grid>
                <Grid size={{ xs: 12, sm: 6, lg: 2 }}>
                  <TextField select fullWidth label="Role" value={form.role} onChange={updateField('role')} disabled={busy}>
                    {['ADMIN', 'HR', 'MANAGER'].map((role) => <MenuItem key={role} value={role}>{role}</MenuItem>)}
                  </TextField>
                </Grid>
                <Grid size={{ xs: 12 }}>
                  <TextField
                    fullWidth
                    label="Direct permissions"
                    placeholder="employees.view_employee, employees.add_employee"
                    helperText="Optional. Enter app_label.codename values separated by commas."
                    value={form.permissions}
                    onChange={updateField('permissions')}
                    disabled={busy}
                  />
                </Grid>
                <Grid size={{ xs: 12 }}>
                  <Stack direction={{ xs: 'column', sm: 'row' }} alignItems={{ xs: 'stretch', sm: 'center' }} justifyContent="space-between" gap={1.5}>
                    <FormControlLabel
                      control={<Switch checked={form.is_active} onChange={(event) => setForm((current) => ({ ...current, is_active: event.target.checked }))} disabled={busy} />}
                      label="Account active"
                    />
                    <Stack direction="row" justifyContent="flex-end" spacing={1}>
                      {editingId ? <Button type="button" variant="outlined" onClick={cancelEdit} disabled={busy}>Cancel</Button> : null}
                      <Button type="submit" variant="contained" disabled={busy}>
                        {busy ? 'Saving…' : editingId ? 'Save changes' : 'Create account'}
                      </Button>
                    </Stack>
                  </Stack>
                </Grid>
              </Grid>
            </Box>
          </Stack>
        </CardContent>
      </Card>

      <Paper sx={{ overflow: 'hidden' }}>
        {isLoading ? <LoadingState label="Loading admin users…" /> : queryError ? <Box sx={{ minHeight: 96 }} /> : users.length === 0 ? (
          <EmptyState title="No admin users yet" description="Create an administrator, HR, or manager account to get started." />
        ) : (
          <TableContainer sx={{ border: 0, borderRadius: 0 }}>
            <Table aria-label="Admin users" sx={{ minWidth: 860 }}>
              <TableHead>
                <TableRow>
                  <TableCell>Name</TableCell>
                  <TableCell>Mobile</TableCell>
                  <TableCell>Email</TableCell>
                  <TableCell>Role</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Direct permissions</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {users.map((user) => (
                  <TableRow key={user.id} hover>
                    <TableCell sx={{ fontWeight: 600 }}>{`${user.first_name} ${user.last_name}`.trim()}</TableCell>
                    <TableCell>{user.phone_number}</TableCell>
                    <TableCell>{user.email || '—'}</TableCell>
                    <TableCell>{user.role}</TableCell>
                    <TableCell>
                      <Stack direction="row" alignItems="center" spacing={1}>
                        <StatusChip label={user.is_active ? 'Active' : 'Inactive'} />
                        <Switch checked={user.is_active} onChange={() => toggleActive(user)} inputProps={{ 'aria-label': `Set ${user.phone_number} ${user.is_active ? 'inactive' : 'active'}` }} />
                      </Stack>
                    </TableCell>
                    <TableCell sx={{ maxWidth: 300, whiteSpace: 'normal', overflowWrap: 'anywhere' }}>
                      {(user.permission_codenames || []).length ? user.permission_codenames.join(', ') : '—'}
                    </TableCell>
                    <TableCell align="right"><Button size="small" onClick={() => editUser(user)}>Edit</Button></TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Paper>
    </Box>
  )
}