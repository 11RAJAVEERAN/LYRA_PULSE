import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Alert, Box, Button, MenuItem, Paper, Stack, Switch, Table, TableBody, TableCell, TableHead, TableRow, TextField, Typography } from '@mui/material'
import { adminUsersApi } from '../api/adminUsersApi'

const emptyForm = { phone_number: '', email: '', first_name: '', last_name: '', role: 'ADMIN', is_active: true, permissions: '' }

export function AdminUsersPage() {
  const { data: users = [], error: queryError, refetch } = useQuery({ queryKey: ['admin-users'], queryFn: adminUsersApi.list })
  const [form, setForm] = useState(emptyForm)
  const [editingId, setEditingId] = useState(null)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)

  const updateField = (field) => (event) => setForm((current) => ({ ...current, [field]: event.target.value }))

  const createUser = async (event) => {
    event.preventDefault()
    setBusy(true); setError(''); setMessage('')
    try {
      const payload = { ...form, permissions: form.permissions.split(',').map((value) => value.trim()).filter(Boolean) }
      if (editingId) await adminUsersApi.update(editingId, payload)
      else await adminUsersApi.create(payload)
      setForm(emptyForm); setEditingId(null); setMessage(editingId ? 'Account updated.' : 'Account created. It can sign in with an OTP sent to its registered mobile.'); await refetch()
    } catch (err) {
      const details = err.response?.data
      setError(typeof details === 'object' ? JSON.stringify(details) : 'Unable to create account.')
    } finally { setBusy(false) }
  }

  const toggleActive = async (user) => {
    setError('')
    try { await adminUsersApi.update(user.id, { is_active: !user.is_active }); await refetch() }
    catch (err) { setError(err.response?.data?.detail || 'Unable to update account.') }
  }

  const editUser = (user) => {
    setEditingId(user.id)
    setForm({ phone_number: user.phone_number, email: user.email || '', first_name: user.first_name || '', last_name: user.last_name || '', role: user.role, is_active: user.is_active, permissions: (user.permission_codenames || []).join(', ') })
    setError(''); setMessage('')
  }

  return <Stack spacing={3}>
    <Box><Typography variant="h4">Admin users</Typography><Typography color="text.secondary">Manage ADMIN, HR, and MANAGER accounts and Django permissions.</Typography></Box>
    {(error || queryError) && <Alert severity="error">{error || queryError.response?.data?.detail || 'Unable to load users.'}</Alert>}{message && <Alert severity="success">{message}</Alert>}
    <Paper component="form" onSubmit={createUser} sx={{ p: 3 }}>
      <Typography variant="h6" sx={{ mb: 2 }}>{editingId ? 'Edit account' : 'Create account'}</Typography>
      <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} flexWrap="wrap">
        <TextField required label="Mobile number" value={form.phone_number} onChange={updateField('phone_number')} />
        <TextField label="Email" type="email" value={form.email} onChange={updateField('email')} />
        <TextField required label="First name" value={form.first_name} onChange={updateField('first_name')} />
        <TextField label="Last name" value={form.last_name} onChange={updateField('last_name')} />
        <TextField select label="Role" value={form.role} onChange={updateField('role')} sx={{ minWidth: 140 }}>
          {['ADMIN', 'HR', 'MANAGER'].map((role) => <MenuItem key={role} value={role}>{role}</MenuItem>)}
        </TextField>
        <TextField label="Permissions" placeholder="employees.view_employee, employees.add_employee" helperText="Comma-separated app_label.codename values" value={form.permissions} onChange={updateField('permissions')} fullWidth />
        <Button type="submit" variant="contained" disabled={busy}>{editingId ? 'Save changes' : 'Create account'}</Button>
        {editingId && <Button type="button" onClick={() => { setEditingId(null); setForm(emptyForm) }}>Cancel</Button>}
      </Stack>
    </Paper>
    <Paper sx={{ overflowX: 'auto' }}><Table size="small"><TableHead><TableRow><TableCell>Name</TableCell><TableCell>Mobile</TableCell><TableCell>Email</TableCell><TableCell>Role</TableCell><TableCell>Active</TableCell><TableCell>Direct permissions</TableCell><TableCell>Actions</TableCell></TableRow></TableHead>
      <TableBody>{users.map((user) => <TableRow key={user.id}><TableCell>{`${user.first_name} ${user.last_name}`.trim()}</TableCell><TableCell>{user.phone_number}</TableCell><TableCell>{user.email}</TableCell><TableCell>{user.role}</TableCell><TableCell><Switch checked={user.is_active} onChange={() => toggleActive(user)} inputProps={{ 'aria-label': `Toggle ${user.phone_number}` }} /></TableCell><TableCell>{(user.permission_codenames || []).join(', ')}</TableCell><TableCell><Button size="small" onClick={() => editUser(user)}>Edit</Button></TableCell></TableRow>)}</TableBody>
    </Table></Paper>
  </Stack>
}