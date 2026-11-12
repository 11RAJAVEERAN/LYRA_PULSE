import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  Alert, Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, FormControl,
  InputLabel, MenuItem, Paper, Select, Stack, Switch, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, TextField, Typography,
} from '@mui/material'
import { Building2, Pencil, ShieldCheck, UserPlus } from 'lucide-react'

import { EmptyState } from '../../../components/common/EmptyState'
import { ErrorState } from '../../../components/common/ErrorState'
import { LoadingState } from '../../../components/common/LoadingState'
import { PageHeader } from '../../../components/common/PageHeader'
import { StatusChip } from '../../../components/common/StatusChip'
import { authService } from '../../../services/authService'
import { companiesApi } from '../api/companiesApi'

const blankCompany = { name: '', code: '', is_active: true }
const blankAdmin = { phone_number: '', email: '', first_name: '', last_name: '', is_active: true, organization_id: '' }

function errorText(error) {
  const data = error?.response?.data
  if (data?.detail) return data.detail
  if (data?.errors) {
    return Object.entries(data.errors)
      .map(([field, messages]) => `${field}: ${Array.isArray(messages) ? messages.join(' ') : messages}`)
      .join(' ')
  }
  return data?.message ?? error?.message ?? 'The request could not be completed.'
}

export function CompaniesPage() {
  const queryClient = useQueryClient()
  const user = authService.getCurrentUser()
  const isPlatformAdmin = user?.is_global === true
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('all')
  const [companyDialog, setCompanyDialog] = useState(false)
  const [companyForm, setCompanyForm] = useState(blankCompany)
  const [editingCompany, setEditingCompany] = useState(null)
  const [activeCompany, setActiveCompany] = useState(null)
  const [adminDialog, setAdminDialog] = useState(false)
  const [adminForm, setAdminForm] = useState(blankAdmin)
  const [editingAdmin, setEditingAdmin] = useState(null)
  const [error, setError] = useState('')

  const companyQuery = useQuery({
    queryKey: ['companies', search, status],
    queryFn: () => companiesApi.list({ search, status }),
  })
  const companyDetailQuery = useQuery({
    queryKey: ['company-detail', activeCompany?.id],
    queryFn: () => companiesApi.get(activeCompany.id),
    enabled: Boolean(activeCompany),
  })
  const assignmentCompaniesQuery = useQuery({
    queryKey: ['companies', 'super-admin-assignment-options'],
    queryFn: () => companiesApi.list({ status: 'active' }),
    enabled: isPlatformAdmin,
  })
  const adminsQuery = useQuery({
    queryKey: ['company-super-admins', activeCompany?.id],
    queryFn: () => companiesApi.superAdmins(activeCompany.id),
    enabled: Boolean(activeCompany),
  })

  const refresh = async () => Promise.all([
    queryClient.invalidateQueries({ queryKey: ['companies'] }),
    queryClient.invalidateQueries({ queryKey: ['company-detail', activeCompany?.id] }),
    queryClient.invalidateQueries({ queryKey: ['company-super-admins', activeCompany?.id] }),
  ])

  const saveCompany = useMutation({
    mutationFn: () => editingCompany
      ? companiesApi.update(editingCompany.id, isPlatformAdmin ? companyForm : { name: companyForm.name })
      : companiesApi.create(companyForm),
    onSuccess: async () => {
      setCompanyDialog(false)
      setError('')
      await refresh()
    },
    onError: (requestError) => setError(errorText(requestError)),
  })

  const saveAdmin = useMutation({
    mutationFn: () => {
      const payload = { ...adminForm }
      if (!isPlatformAdmin || !editingAdmin) delete payload.organization_id
      return editingAdmin
        ? companiesApi.updateSuperAdmin(activeCompany.id, editingAdmin.id, payload)
        : companiesApi.createSuperAdmin(activeCompany.id, payload)
    },
    onSuccess: async () => {
      setAdminDialog(false)
      setError('')
      await refresh()
    },
    onError: (requestError) => setError(errorText(requestError)),
  })

  const openCompanyEditor = (company = null) => {
    setError('')
    setEditingCompany(company)
    setCompanyForm(company ? { name: company.name, code: company.code, is_active: company.is_active } : blankCompany)
    setCompanyDialog(true)
  }

  const openAdminEditor = (admin = null) => {
    setError('')
    setEditingAdmin(admin)
    setAdminForm(admin ? {
      phone_number: admin.phone_number,
      email: admin.email ?? '',
      first_name: admin.first_name ?? '',
      last_name: admin.last_name ?? '',
      is_active: admin.is_active,
      organization_id: String(activeCompany?.id ?? ''),
    } : { ...blankAdmin, organization_id: String(activeCompany?.id ?? '') })
    setAdminDialog(true)
  }

  const toggleCompany = async (company) => {
    setError('')
    try {
      await companiesApi.update(company.id, { is_active: !company.is_active })
      await refresh()
    } catch (requestError) {
      setError(errorText(requestError))
    }
  }

  const toggleAdmin = async (admin) => {
    setError('')
    try {
      await companiesApi.updateSuperAdmin(activeCompany.id, admin.id, { is_active: !admin.is_active })
      await refresh()
    } catch (requestError) {
      setError(errorText(requestError))
    }
  }

  return (
    <Box>
      <PageHeader
        title="Companies"
        action={isPlatformAdmin ? (
          <Button variant="contained" startIcon={<Building2 size={17} />} onClick={() => openCompanyEditor()}>
            Add company
          </Button>
        ) : null}
      />
      {error ? <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert> : null}

      <Paper variant="outlined" sx={{ p: 2, mb: 2 }}>
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5}>
          <TextField
            size="small"
            label="Search companies"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            fullWidth
          />
          <FormControl size="small" sx={{ minWidth: 170 }}>
            <InputLabel id="company-status-label">Status</InputLabel>
            <Select labelId="company-status-label" label="Status" value={status} onChange={(event) => setStatus(event.target.value)}>
              <MenuItem value="all">All companies</MenuItem>
              <MenuItem value="active">Active</MenuItem>
              <MenuItem value="inactive">Inactive</MenuItem>
            </Select>
          </FormControl>
        </Stack>
      </Paper>

      <Paper variant="outlined" sx={{ overflow: 'hidden' }}>
        {companyQuery.isLoading ? <LoadingState label="Loading companies…" />
          : companyQuery.isError ? <ErrorState message={errorText(companyQuery.error)} onRetry={() => companyQuery.refetch()} retrying={companyQuery.isFetching} />
            : companyQuery.data?.length === 0 ? <EmptyState title="No companies found" description="Create a company or change the search filters." />
              : (
                <TableContainer sx={{ overflowX: 'auto' }}>
                  <Table size="small" aria-label="Companies" sx={{ minWidth: 680 }}>
                    <TableHead><TableRow>
                      <TableCell>Company</TableCell><TableCell>Code</TableCell><TableCell>Status</TableCell><TableCell align="right">Actions</TableCell>
                    </TableRow></TableHead>
                    <TableBody>{(companyQuery.data ?? []).map((company) => (
                      <TableRow key={company.id} hover>
                        <TableCell>
                          <Typography fontWeight={600}>{company.name}</Typography>
                          <Typography variant="caption" color="text.secondary">Created {new Date(company.created_at).toLocaleDateString()}</Typography>
                        </TableCell>
                        <TableCell>{company.code}</TableCell>
                        <TableCell><StatusChip label={company.is_active ? 'Active' : 'Inactive'} /></TableCell>
                        <TableCell align="right">
                          <Stack direction="row" spacing={0.5} justifyContent="flex-end">
                            <Button size="small" startIcon={<ShieldCheck size={16} />} onClick={() => setActiveCompany(company)}>Super Admins</Button>
                            <Button size="small" startIcon={<Pencil size={16} />} onClick={() => openCompanyEditor(company)}>Edit</Button>
                            {isPlatformAdmin ? <Switch checked={company.is_active} onChange={() => toggleCompany(company)} inputProps={{ 'aria-label': `Set ${company.name} ${company.is_active ? 'inactive' : 'active'}` }} /> : null}
                          </Stack>
                        </TableCell>
                      </TableRow>
                    ))}</TableBody>
                  </Table>
                </TableContainer>
              )}
      </Paper>

      <Dialog open={companyDialog} onClose={() => setCompanyDialog(false)} fullWidth maxWidth="sm">
        <Box component="form" onSubmit={(event) => { event.preventDefault(); saveCompany.mutate() }}>
          <DialogTitle>{editingCompany ? 'Edit company' : 'Create company'}</DialogTitle>
          <DialogContent>
            <Stack spacing={2} sx={{ pt: 1 }}>
              <TextField label="Company name" required value={companyForm.name} onChange={(event) => setCompanyForm({ ...companyForm, name: event.target.value })} />
              <TextField label="Company code" required disabled={Boolean(editingCompany) || !isPlatformAdmin} value={companyForm.code} onChange={(event) => setCompanyForm({ ...companyForm, code: event.target.value })} />
              {isPlatformAdmin && editingCompany ? (
                <Stack direction="row" alignItems="center" justifyContent="space-between">
                  <Typography>Company active</Typography>
                  <Switch checked={companyForm.is_active} onChange={(event) => setCompanyForm({ ...companyForm, is_active: event.target.checked })} />
                </Stack>
              ) : null}
            </Stack>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setCompanyDialog(false)}>Cancel</Button>
            <Button type="submit" variant="contained" disabled={saveCompany.isPending}>{saveCompany.isPending ? 'Saving…' : 'Save'}</Button>
          </DialogActions>
        </Box>
      </Dialog>

      <Dialog open={Boolean(activeCompany)} onClose={() => setActiveCompany(null)} fullWidth maxWidth="md">
        <DialogTitle>{(companyDetailQuery.data ?? activeCompany)?.name} · Company details</DialogTitle>
        <DialogContent>
          {companyDetailQuery.isError ? <Alert severity="error" sx={{ mb: 2 }}>{errorText(companyDetailQuery.error)}</Alert> : null}
          {companyDetailQuery.isLoading ? <LoadingState label="Loading company details…" /> : (
            <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ mb: 2 }}>
              <Typography><strong>Code:</strong> {(companyDetailQuery.data ?? activeCompany)?.code}</Typography>
              <Typography><strong>Status:</strong> {(companyDetailQuery.data ?? activeCompany)?.is_active ? 'Active' : 'Inactive'}</Typography>
              <Typography><strong>Created:</strong> {new Date((companyDetailQuery.data ?? activeCompany)?.created_at).toLocaleDateString()}</Typography>
            </Stack>
          )}
          <Typography variant="h6" sx={{ mb: 1 }}>Authorized Super Admins</Typography>
          <Stack direction="row" justifyContent="flex-end" sx={{ mb: 1 }}>
            <Button startIcon={<UserPlus size={17} />} onClick={() => openAdminEditor()}>Add Super Admin</Button>
          </Stack>
          {adminsQuery.isLoading ? <LoadingState label="Loading Super Admins…" />
            : adminsQuery.isError ? <ErrorState message={errorText(adminsQuery.error)} onRetry={() => adminsQuery.refetch()} retrying={adminsQuery.isFetching} />
              : adminsQuery.data?.length === 0 ? <EmptyState title="No Company Super Admins" description="Add an authorized administrator for this company." />
                : (
                  <TableContainer sx={{ overflowX: 'auto' }}>
                    <Table size="small" aria-label="Company Super Admins">
                      <TableHead><TableRow><TableCell>Name</TableCell><TableCell>Phone</TableCell><TableCell>Email</TableCell><TableCell>Status</TableCell><TableCell align="right">Actions</TableCell></TableRow></TableHead>
                      <TableBody>{(adminsQuery.data ?? []).map((admin) => (
                        <TableRow key={admin.id}>
                          <TableCell>{`${admin.first_name} ${admin.last_name}`.trim() || '—'}</TableCell>
                          <TableCell>{admin.phone_number}</TableCell>
                          <TableCell>{admin.email || '—'}</TableCell>
                          <TableCell><StatusChip label={admin.is_active ? 'Active' : 'Inactive'} /></TableCell>
                          <TableCell align="right">
                            <Button size="small" onClick={() => openAdminEditor(admin)}>Edit</Button>
                            <Switch checked={admin.is_active} onChange={() => toggleAdmin(admin)} inputProps={{ 'aria-label': `Set ${admin.phone_number} ${admin.is_active ? 'inactive' : 'active'}` }} />
                          </TableCell>
                        </TableRow>
                      ))}</TableBody>
                    </Table>
                  </TableContainer>
                )}
        </DialogContent>
        <DialogActions><Button onClick={() => setActiveCompany(null)}>Close</Button></DialogActions>
      </Dialog>

      <Dialog open={adminDialog} onClose={() => setAdminDialog(false)} fullWidth maxWidth="sm">
        <Box component="form" onSubmit={(event) => { event.preventDefault(); saveAdmin.mutate() }}>
          <DialogTitle>{editingAdmin ? 'Edit Company Super Admin' : 'Add Company Super Admin'}</DialogTitle>
          <DialogContent>
            <Stack spacing={2} sx={{ pt: 1 }}>
              {isPlatformAdmin && editingAdmin ? (
                <TextField
                  select
                  label="Company assignment"
                  value={adminForm.organization_id}
                  onChange={(event) => setAdminForm({ ...adminForm, organization_id: event.target.value })}
                >
                  {(assignmentCompaniesQuery.data ?? []).map((company) => (
                    <MenuItem key={company.id} value={String(company.id)}>{company.name}</MenuItem>
                  ))}
                </TextField>
              ) : null}
              <TextField label="Phone number" required value={adminForm.phone_number} onChange={(event) => setAdminForm({ ...adminForm, phone_number: event.target.value })} />
              <TextField label="Email" type="email" value={adminForm.email} onChange={(event) => setAdminForm({ ...adminForm, email: event.target.value })} />
              <TextField label="First name" value={adminForm.first_name} onChange={(event) => setAdminForm({ ...adminForm, first_name: event.target.value })} />
              <TextField label="Last name" value={adminForm.last_name} onChange={(event) => setAdminForm({ ...adminForm, last_name: event.target.value })} />
              {editingAdmin ? <Stack direction="row" alignItems="center" justifyContent="space-between"><Typography>Access active</Typography><Switch checked={adminForm.is_active} onChange={(event) => setAdminForm({ ...adminForm, is_active: event.target.checked })} /></Stack> : null}
            </Stack>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setAdminDialog(false)}>Cancel</Button>
            <Button type="submit" variant="contained" disabled={saveAdmin.isPending}>{saveAdmin.isPending ? 'Saving…' : 'Save'}</Button>
          </DialogActions>
        </Box>
      </Dialog>
    </Box>
  )
}