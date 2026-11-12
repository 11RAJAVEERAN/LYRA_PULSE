import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  Alert, Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, FormControl,
  InputLabel, MenuItem, Paper, Select, Stack, Switch, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, TextField, Typography,
} from '@mui/material'
import { MapPin, Pencil, Plus } from 'lucide-react'

import { EmptyState } from '../../../components/common/EmptyState'
import { ErrorState } from '../../../components/common/ErrorState'
import { LoadingState } from '../../../components/common/LoadingState'
import { PageHeader } from '../../../components/common/PageHeader'
import { StatusChip } from '../../../components/common/StatusChip'
import { authService } from '../../../services/authService'
import { branchesApi } from '../api/branchesApi'
import { companiesApi } from '../../companies/api/companiesApi'

const blankBranch = {
  name: '', code: '', address: '', organization_id: '', latitude: '', longitude: '',
  attendance_radius_meters: '40', is_active: true,
}

function errorText(error) {
  const data = error?.response?.data
  if (data?.detail) return data.detail
  if (data?.errors) {
    return Object.entries(data.errors)
      .map(([field, messages]) => `${field}: ${Array.isArray(messages) ? messages.join(' ') : messages}`)
      .join(' ')
  }
  if (error?.response?.status === 401) return 'Your session has expired. Sign in again to continue.'
  if (error?.response?.status === 403) return 'You are not authorized to manage this branch.'
  if (error?.response?.status === 404) return 'This branch is no longer available in your authorized scope.'
  return data?.message ?? error?.message ?? 'The request could not be completed.'
}

function radiusValidationError(value) {
  const radius = String(value).trim()
  if (!/^\d+$/.test(radius)) return 'Enter a whole number of metres.'
  const number = Number(radius)
  if (!Number.isSafeInteger(number) || number < 10 || number > 100) {
    return 'Attendance radius must be between 10 and 100 metres.'
  }
  return ''
}

function radiusChanged(value, editingBranch) {
  return !editingBranch || String(value) !== String(editingBranch.attendance_radius_meters)
}

function branchPayload(form, isPlatformAdmin, editingBranch) {
  const payload = {
    name: form.name.trim(),
    code: form.code.trim(),
    address: form.address,
    latitude: form.latitude === '' ? null : form.latitude,
    longitude: form.longitude === '' ? null : form.longitude,
    is_active: form.is_active,
  }
  if (radiusChanged(form.attendance_radius_meters, editingBranch)) {
    payload.attendance_radius_meters = Number(form.attendance_radius_meters)
  }
  if (isPlatformAdmin && (!editingBranch || !editingBranch.organization)) {
    payload.organization_id = Number(form.organization_id)
  }
  return payload
}

export function BranchesPage() {
  const queryClient = useQueryClient()
  const user = authService.getCurrentUser()
  const isPlatformAdmin = user?.is_global === true
  const canManageBranches = user?.role === 'SUPERADMIN'
  const canEditAssignedRadius = user?.role === 'ADMIN'
  const [selectedCompany, setSelectedCompany] = useState(user?.organization?.id ? String(user.organization.id) : '')
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState('all')
  const [branchDialog, setBranchDialog] = useState(false)
  const [editingBranch, setEditingBranch] = useState(null)
  const [viewingBranch, setViewingBranch] = useState(null)
  const [form, setForm] = useState(blankBranch)
  const [radiusBranch, setRadiusBranch] = useState(null)
  const [radiusValue, setRadiusValue] = useState('')
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')

  const companiesQuery = useQuery({
    queryKey: ['companies', 'branch-options', user?.id],
    queryFn: () => companiesApi.list({ status: 'all' }),
    enabled: isPlatformAdmin,
  })
  const companies = companiesQuery.data ?? []
  const activeCompanies = companies.filter((company) => company.is_active)
  const selectedCompanyId = selectedCompany || (
    isPlatformAdmin
      ? (activeCompanies[0] ? String(activeCompanies[0].id) : companiesQuery.isSuccess ? 'unassigned' : '')
      : String(user?.organization?.id ?? '')
  )

  const branchQuery = useQuery({
    queryKey: ['branches', user?.id, selectedCompanyId, search, status],
    queryFn: () => branchesApi.list({
      ...(selectedCompanyId === 'unassigned' ? { unassigned: true } : { organization: selectedCompanyId || undefined }),
      search,
      status,
    }),
    enabled: Boolean(selectedCompanyId),
  })

  const refresh = async () => queryClient.invalidateQueries({ queryKey: ['branches'] })
  const saveBranch = useMutation({
    mutationFn: () => {
      const payload = branchPayload(form, isPlatformAdmin, editingBranch)
      return editingBranch ? branchesApi.update(editingBranch.id, payload) : branchesApi.create(payload)
    },
    onSuccess: async () => {
      setBranchDialog(false)
      setError('')
      await refresh()
    },
    onError: (requestError) => setError(errorText(requestError)),
  })

  const saveRadius = useMutation({
    mutationFn: () => branchesApi.updateAttendanceRadius(radiusBranch.id, {
      attendance_radius_meters: Number(radiusValue),
    }),
    onSuccess: async () => {
      setRadiusBranch(null)
      setError('')
      setNotice('Branch attendance radius updated.')
      await refresh()
    },
    onError: (requestError) => setError(errorText(requestError)),
  })

  const openEditor = async (branch = null) => {
    setError('')
    if (!branch) {
      setEditingBranch(null)
      setForm({
        ...blankBranch,
        organization_id: selectedCompanyId === 'unassigned' ? '' : selectedCompanyId,
      })
      setBranchDialog(true)
      return
    }
    try {
      const detail = await branchesApi.get(branch.id)
      setEditingBranch(detail)
      setForm({
        name: detail.name,
        code: detail.code,
        address: detail.address ?? '',
        organization_id: detail.organization?.id ? String(detail.organization.id) : '',
        latitude: detail.latitude ?? '',
        longitude: detail.longitude ?? '',
        attendance_radius_meters: String(detail.attendance_radius_meters ?? 40),
        is_active: detail.is_active,
      })
      setBranchDialog(true)
    } catch (requestError) {
      setError(errorText(requestError))
    }
  }

  const toggleBranch = async (branch) => {
    setError('')
    try {
      await branchesApi.update(branch.id, { is_active: !branch.is_active })
      await refresh()
    } catch (requestError) {
      setError(errorText(requestError))
    }
  }

  const selectedCompanyDetails = companies.find((company) => String(company.id) === selectedCompanyId)
  const fullRadiusChanged = radiusChanged(form.attendance_radius_meters, editingBranch)
  const fullRadiusError = fullRadiusChanged ? radiusValidationError(form.attendance_radius_meters) : ''
  const assignedRadiusChanged = radiusBranch
    ? String(radiusValue) !== String(radiusBranch.attendance_radius_meters)
    : false
  const assignedRadiusError = assignedRadiusChanged ? radiusValidationError(radiusValue) : ''

  return (
    <Box>
      <PageHeader
        title="Branches"
        action={canManageBranches && selectedCompanyId !== 'unassigned' && selectedCompanyDetails?.is_active !== false ? (
          <Button variant="contained" startIcon={<Plus size={17} />} onClick={() => openEditor()} disabled={!selectedCompanyId}>
            Add branch
          </Button>
        ) : null}
      />
      {error ? <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert> : null}
      {notice ? <Alert severity="success" sx={{ mb: 2 }} onClose={() => setNotice('')}>{notice}</Alert> : null}

      <Paper variant="outlined" sx={{ p: 2, mb: 2 }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={1.5}>
          {isPlatformAdmin ? (
            <FormControl size="small" sx={{ minWidth: 240 }}>
              <InputLabel id="branch-company-label">Company</InputLabel>
              <Select labelId="branch-company-label" label="Company" value={selectedCompanyId} onChange={(event) => setSelectedCompany(event.target.value)}>
                {companies.map((company) => <MenuItem key={company.id} value={String(company.id)}>{company.name}{company.is_active ? '' : ' (Inactive)'}</MenuItem>)}
                <MenuItem value="unassigned">Unassigned legacy branches</MenuItem>
              </Select>
            </FormControl>
          ) : (
            <TextField size="small" label="Company" value={user?.organization?.name ?? ''} disabled sx={{ minWidth: 220 }} />
          )}
          <TextField size="small" label="Search branches" value={search} onChange={(event) => setSearch(event.target.value)} fullWidth />
          <FormControl size="small" sx={{ minWidth: 170 }}>
            <InputLabel id="branch-status-label">Status</InputLabel>
            <Select labelId="branch-status-label" label="Status" value={status} onChange={(event) => setStatus(event.target.value)}>
              <MenuItem value="all">All branches</MenuItem><MenuItem value="active">Active</MenuItem><MenuItem value="inactive">Inactive</MenuItem>
            </Select>
          </FormControl>
        </Stack>
      </Paper>

      {selectedCompanyId === 'unassigned' ? <Alert severity="info" sx={{ mb: 2 }}>These legacy branches are not assigned to a Company. Assign ownership only after confirming the correct Company.</Alert> : null}
      <Paper variant="outlined" sx={{ overflow: 'hidden' }}>
        {((isPlatformAdmin && companiesQuery.isLoading) || branchQuery.isLoading) ? <LoadingState label="Loading branches…" />
          : (isPlatformAdmin && companiesQuery.isError) ? <ErrorState message={errorText(companiesQuery.error)} onRetry={() => companiesQuery.refetch()} retrying={companiesQuery.isFetching} />
            : branchQuery.isError ? <ErrorState message={errorText(branchQuery.error)} onRetry={() => branchQuery.refetch()} retrying={branchQuery.isFetching} />
              : branchQuery.data?.length === 0 ? <EmptyState title="No branches found" description="Create a branch or adjust the selected company and filters." />
                : (
                  <TableContainer sx={{ overflowX: 'auto' }}>
                    <Table size="small" aria-label="Branches" sx={{ minWidth: 760 }}>
                      <TableHead><TableRow><TableCell>Branch</TableCell><TableCell>Code</TableCell><TableCell>Company</TableCell><TableCell>Attendance location</TableCell><TableCell>Status</TableCell><TableCell align="right">Actions</TableCell></TableRow></TableHead>
                      <TableBody>{(branchQuery.data ?? []).map((branch) => (
                        <TableRow key={branch.id} hover>
                          <TableCell><Typography fontWeight={600}>{branch.name}</Typography><Typography variant="caption" color="text.secondary">{branch.address || 'No address'}</Typography></TableCell>
                          <TableCell>{branch.code}</TableCell>
                          <TableCell>{branch.organization?.name ?? 'Unassigned'}</TableCell>
                          <TableCell>
                            <Typography>{branch.attendance_radius_meters} m</Typography>
                            <Typography variant="caption" color="text.secondary">
                              {branch.location_configured ? `${branch.latitude}, ${branch.longitude}` : 'Location not configured'}
                            </Typography>
                            {branch.attendance_radius_meters > 100
                              ? <Typography variant="caption" color="warning.main" display="block">Legacy radius above 100 m</Typography>
                              : null}
                          </TableCell>
                          <TableCell><StatusChip label={branch.is_active ? 'Active' : 'Inactive'} /></TableCell>
                          <TableCell align="right">
                            <Button size="small" onClick={() => setViewingBranch(branch)}>Details</Button>
                            {canManageBranches ? (
                              <>
                                <Button size="small" startIcon={<Pencil size={15} />} onClick={() => openEditor(branch)}>Edit</Button>
                                <Switch checked={branch.is_active} onChange={() => toggleBranch(branch)} inputProps={{ 'aria-label': `Set ${branch.name} ${branch.is_active ? 'inactive' : 'active'}` }} />
                              </>
                            ) : null}
                            {canEditAssignedRadius ? (
                              <Button size="small" onClick={() => { setError(''); setRadiusValue(String(branch.attendance_radius_meters)); setRadiusBranch(branch) }}>
                                Edit radius
                              </Button>
                            ) : null}
                          </TableCell>
                        </TableRow>
                      ))}</TableBody>
                    </Table>
                  </TableContainer>
                )}
      </Paper>

      <Dialog open={branchDialog} onClose={() => setBranchDialog(false)} fullWidth maxWidth="sm">
        <Box component="form" onSubmit={(event) => {
          event.preventDefault()
          if (fullRadiusError) return
          saveBranch.mutate()
        }}>
          <DialogTitle>{editingBranch ? 'Edit branch' : 'Create branch'}</DialogTitle>
          <DialogContent>
            <Stack spacing={2} sx={{ pt: 1 }}>
              {isPlatformAdmin && (!editingBranch || !editingBranch.organization) ? (
                <TextField select required label="Company" value={form.organization_id} onChange={(event) => setForm({ ...form, organization_id: event.target.value })}>
                  {activeCompanies.map((company) => <MenuItem key={company.id} value={String(company.id)}>{company.name}</MenuItem>)}
                </TextField>
              ) : null}
              <TextField required label="Branch name" value={form.name} onChange={(event) => setForm({ ...form, name: event.target.value })} />
              <TextField required label="Branch code" value={form.code} onChange={(event) => setForm({ ...form, code: event.target.value })} />
              <TextField label="Address" multiline minRows={2} value={form.address} onChange={(event) => setForm({ ...form, address: event.target.value })} />
              <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
                <TextField label="Latitude" type="number" inputProps={{ step: '0.000001', min: -90, max: 90 }} value={form.latitude} onChange={(event) => setForm({ ...form, latitude: event.target.value })} fullWidth />
                <TextField label="Longitude" type="number" inputProps={{ step: '0.000001', min: -180, max: 180 }} value={form.longitude} onChange={(event) => setForm({ ...form, longitude: event.target.value })} fullWidth />
              </Stack>
              {editingBranch?.attendance_radius_meters > 100 ? (
                <Alert severity="warning">
                  This branch has a legacy radius of {editingBranch.attendance_radius_meters} m. It will be preserved unless you explicitly change it to a value from 10 to 100 m.
                </Alert>
              ) : null}
              <TextField
                label="Attendance radius (metres)"
                type="number"
                inputProps={{ min: 10, max: 100, step: 1 }}
                value={form.attendance_radius_meters}
                onChange={(event) => setForm({ ...form, attendance_radius_meters: event.target.value })}
                error={Boolean(fullRadiusError)}
                helperText={fullRadiusError || 'Enter a whole number from 10 to 100 metres.'}
              />
              {editingBranch ? <Stack direction="row" alignItems="center" justifyContent="space-between"><Typography>Branch active</Typography><Switch checked={form.is_active} onChange={(event) => setForm({ ...form, is_active: event.target.checked })} /></Stack> : null}
            </Stack>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setBranchDialog(false)}>Cancel</Button>
            <Button type="submit" variant="contained" disabled={saveBranch.isPending || Boolean(fullRadiusError) || (isPlatformAdmin && !form.organization_id)}>{saveBranch.isPending ? 'Saving…' : 'Save'}</Button>
          </DialogActions>
        </Box>
      </Dialog>

      <Dialog open={Boolean(radiusBranch)} onClose={() => setRadiusBranch(null)} fullWidth maxWidth="xs">
        <Box component="form" onSubmit={(event) => {
          event.preventDefault()
          if (!assignedRadiusChanged || assignedRadiusError) return
          saveRadius.mutate()
        }}>
          <DialogTitle>Attendance radius</DialogTitle>
          <DialogContent>
            <Stack spacing={2} sx={{ pt: 1 }}>
              <Typography>{radiusBranch?.name}</Typography>
              {radiusBranch?.attendance_radius_meters > 100 ? (
                <Alert severity="warning">
                  This legacy radius will remain unchanged unless you select a valid value from 10 to 100 metres.
                </Alert>
              ) : null}
              <TextField
                label="Attendance radius (metres)"
                type="number"
                inputProps={{ min: 10, max: 100, step: 1 }}
                value={radiusValue}
                onChange={(event) => setRadiusValue(event.target.value)}
                error={Boolean(assignedRadiusError)}
                helperText={assignedRadiusError || 'Enter a whole number from 10 to 100 metres.'}
              />
            </Stack>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setRadiusBranch(null)}>Cancel</Button>
            <Button
              type="submit"
              variant="contained"
              disabled={saveRadius.isPending || !assignedRadiusChanged || Boolean(assignedRadiusError)}
            >
              {saveRadius.isPending ? 'Saving…' : 'Save radius'}
            </Button>
          </DialogActions>
        </Box>
      </Dialog>

      <Dialog open={Boolean(viewingBranch)} onClose={() => setViewingBranch(null)} fullWidth maxWidth="sm">
        <DialogTitle>{viewingBranch?.name}</DialogTitle>
        <DialogContent>
          <Stack spacing={1.5} sx={{ pt: 1 }}>
            <Typography><strong>Code:</strong> {viewingBranch?.code}</Typography>
            <Typography><strong>Company:</strong> {viewingBranch?.organization?.name ?? 'Unassigned legacy branch'}</Typography>
            <Typography><strong>Address:</strong> {viewingBranch?.address || 'Not provided'}</Typography>
            <Typography><strong>Status:</strong> {viewingBranch?.is_active ? 'Active' : 'Inactive'}</Typography>
            <Typography><strong>Attendance radius:</strong> {viewingBranch?.attendance_radius_meters} meters</Typography>
            {viewingBranch?.attendance_radius_meters > 100 ? (
              <Alert severity="warning">This legacy radius is above 100 metres and is preserved until explicitly changed.</Alert>
            ) : null}
            <Typography sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <MapPin size={16} /> {viewingBranch?.location_configured ? `${viewingBranch.latitude}, ${viewingBranch.longitude}` : 'Attendance location not configured'}
            </Typography>
          </Stack>
        </DialogContent>
        <DialogActions><Button onClick={() => setViewingBranch(null)}>Close</Button></DialogActions>
      </Dialog>
    </Box>
  )
}