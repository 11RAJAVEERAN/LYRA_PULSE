import { useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  Alert, Box, Button, Checkbox, Chip, CircularProgress, FormControl, InputLabel, MenuItem, Paper, Select,
  Snackbar, Stack, Switch, Table, TableBody, TableCell, TableContainer, TableHead,
  TablePagination, TableRow, TextField, Tooltip, Typography,
} from '@mui/material'
import { Search, ShieldCheck } from 'lucide-react'
import { PageHeader } from '../../../components/common/PageHeader'
import { EmptyState } from '../../../components/common/EmptyState'
import { LoadingState } from '../../../components/common/LoadingState'
import { ErrorState } from '../../../components/common/ErrorState'
import { attendancePermissionsApi } from '../api/attendancePermissionsApi'

const PAGE_SIZE = 25
const fields = [
  ['mobile_gps_attendance_enabled', 'Mobile'],
  ['photo_attendance_enabled', 'Photo'],
  ['location_attendance_enabled', 'Location'],
  ['biometric_attendance_enabled', 'Biometric'],
  ['auto_punch_out_enabled', 'Auto punch out'],
]

export function AttendancePermissionsPage() {
  const queryClient = useQueryClient()
  const [search, setSearch] = useState('')
  const [method, setMethod] = useState('all')
  const [branch, setBranch] = useState('all')
  const [page, setPage] = useState(0)
  const [selected, setSelected] = useState([])
  const [notice, setNotice] = useState(null)
  const params = useMemo(() => ({
    search: search.trim() || undefined,
    method,
    branch: branch === 'all' ? undefined : branch,
    page: page + 1,
    page_size: PAGE_SIZE,
  }), [search, method, branch, page])
  const query = useQuery({ queryKey: ['attendance-permissions', params], queryFn: () => attendancePermissionsApi.list(params) })
  const branchQuery = useQuery({ queryKey: ['attendance-permission-branches'], queryFn: attendancePermissionsApi.branches })

  const refresh = () => queryClient.invalidateQueries({ queryKey: ['attendance-permissions'] })
  const save = useMutation({
    mutationFn: ({ employeeId, permissions }) => attendancePermissionsApi.update(employeeId, permissions),
    onSuccess: () => { refresh(); setNotice({ severity: 'success', message: 'Attendance permission saved.' }) },
    onError: (error) => setNotice({ severity: 'error', message: error.response?.data?.message || 'Could not save this change. Please try again.' }),
  })
  const bulk = useMutation({
    mutationFn: ({ ids, permissions }) => attendancePermissionsApi.bulkUpdate(ids, permissions),
    onSuccess: () => { setSelected([]); refresh(); setNotice({ severity: 'success', message: `Permissions updated for ${selected.length} employees.` }) },
    onError: (error) => setNotice({ severity: 'error', message: error.response?.data?.message || 'Bulk update failed. No changes were applied.' }),
  })

  const rows = query.data?.results ?? []
  const allOnPage = rows.length > 0 && rows.every((row) => selected.includes(row.id))
  const someOnPage = rows.some((row) => selected.includes(row.id))
  const toggleSelected = (id) => setSelected((current) => current.includes(id) ? current.filter((value) => value !== id) : [...current, id])
  const updateOne = (row, field, value) => save.mutate({ employeeId: row.id, permissions: { [field]: value } })

  return (
    <Box>
      <PageHeader title="Attendance Permission" subtitle="Control how employees can record attendance." />
      <Alert severity="info" sx={{ mb: 2 }}>Auto Punch Out settings are stored here. Automatic checkout needs a scheduler and shift end-time integration, which this project does not currently provide.</Alert>
      <Paper variant="outlined" sx={{ p: 2, mb: 2 }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={1.5} alignItems={{ md: 'center' }}>
          <TextField size="small" value={search} onChange={(event) => { setSearch(event.target.value); setPage(0) }} placeholder="Search employees" InputProps={{ startAdornment: <Search size={17} style={{ marginRight: 8 }} /> }} sx={{ minWidth: { md: 270 } }} />
          <FormControl size="small" sx={{ minWidth: 170 }}>
            <InputLabel id="permission-method-label">Attendance method</InputLabel>
            <Select labelId="permission-method-label" label="Attendance method" value={method} onChange={(event) => { setMethod(event.target.value); setPage(0) }}>
              <MenuItem value="all">All methods</MenuItem><MenuItem value="mobile">Mobile</MenuItem><MenuItem value="biometric">Biometric</MenuItem><MenuItem value="none">Not enabled</MenuItem>
            </Select>
          </FormControl>
          <FormControl size="small" sx={{ minWidth: 180 }}>
            <InputLabel id="permission-branch-label">Branch</InputLabel>
            <Select labelId="permission-branch-label" label="Branch" value={branch} onChange={(event) => { setBranch(event.target.value); setPage(0) }}>
              <MenuItem value="all">All branches</MenuItem>
              {(branchQuery.data ?? []).map((item) => <MenuItem key={item.id} value={String(item.id)}>{item.name}</MenuItem>)}
            </Select>
          </FormControl>
          <Box sx={{ flex: 1 }} />
          {selected.length > 0 && <Chip icon={<ShieldCheck size={16} />} label={`${selected.length} selected`} color="primary" variant="outlined" />}
          {(save.isPending || bulk.isPending) && <Chip icon={<CircularProgress size={14} />} label="Saving permissions" variant="outlined" />}
        </Stack>
        {selected.length > 0 && <Stack direction="row" spacing={1} mt={1.5} flexWrap="wrap" useFlexGap>
          {fields.map(([field, label]) => <Button key={field} size="small" disabled={bulk.isPending} onClick={() => bulk.mutate({ ids: selected, permissions: { [field]: true } })}>Enable {label}</Button>)}
          {fields.map(([field, label]) => <Button key={`disable-${field}`} size="small" color="inherit" disabled={bulk.isPending} onClick={() => bulk.mutate({ ids: selected, permissions: { [field]: false } })}>Disable {label}</Button>)}
        </Stack>}
      </Paper>

      {query.isLoading ? <LoadingState /> : query.isError ? <ErrorState message="Attendance permissions could not be loaded." onRetry={() => query.refetch()} /> : rows.length === 0 ? (
        <EmptyState title="No employees found" description="Try another search or branch filter." />
      ) : <Paper variant="outlined" sx={{ overflow: 'hidden' }}>
        <TableContainer sx={{ maxHeight: 'calc(100vh - 330px)' }}>
          <Table stickyHeader size="small" sx={{ minWidth: 1120 }}>
            <TableHead><TableRow>
              <TableCell padding="checkbox"><Checkbox checked={allOnPage} indeterminate={!allOnPage && someOnPage} onChange={(event) => setSelected((current) => event.target.checked ? [...new Set([...current, ...rows.map((row) => row.id)])] : current.filter((id) => !rows.some((row) => row.id === id)))} inputProps={{ 'aria-label': 'Select all employees on this page' }} /></TableCell>
              <TableCell>Employee</TableCell><TableCell>Role / Designation</TableCell><TableCell>Attendance method</TableCell>
              {fields.map(([, label]) => <TableCell key={label} align="center">{label}</TableCell>)}
              <TableCell>Biometric device</TableCell>
            </TableRow></TableHead>
            <TableBody>{rows.map((row) => <TableRow key={row.id} hover>
              <TableCell padding="checkbox"><Checkbox checked={selected.includes(row.id)} onChange={() => toggleSelected(row.id)} inputProps={{ 'aria-label': `Select ${row.name}` }} /></TableCell>
              <TableCell><Typography fontWeight={600}>{row.name}</Typography><Typography variant="caption" color="text.secondary">{row.employee_code}</Typography></TableCell>
              <TableCell>{row.role || '—'}</TableCell>
              <TableCell><Chip size="small" variant="outlined" label={row.attendance_method} /></TableCell>
              {fields.map(([field, label]) => {
                const dependent = ['photo_attendance_enabled', 'location_attendance_enabled'].includes(field)
                const disabled = (dependent && !row.mobile_gps_attendance_enabled) || save.isPending || bulk.isPending
                const message = field === 'auto_punch_out_enabled' ? 'Saved as configuration; automatic execution requires a scheduler.' : dependent && !row.mobile_gps_attendance_enabled ? 'Enable Mobile attendance first. This saved setting is retained.' : `${label} attendance permission`
                return <TableCell key={field} align="center"><Tooltip title={message}><span><Switch size="small" checked={row[field]} disabled={disabled} onChange={(event) => updateOne(row, field, event.target.checked)} inputProps={{ 'aria-label': `${label} for ${row.name}` }} /></span></Tooltip></TableCell>
              })}
              <TableCell>{row.biometric_devices?.length ? row.biometric_devices.map((device) => <Chip key={device.id} size="small" sx={{ mr: .5, mb: .5 }} label={device.name} />) : <Typography variant="body2" color="text.secondary">No assigned fingerprint</Typography>}</TableCell>
            </TableRow>)}</TableBody>
          </Table>
        </TableContainer>
        <TablePagination component="div" count={query.data?.count ?? 0} page={page} rowsPerPage={PAGE_SIZE} rowsPerPageOptions={[PAGE_SIZE]} onPageChange={(_, next) => { setPage(next); setSelected([]) }} />
      </Paper>}
      <Snackbar open={Boolean(notice)} autoHideDuration={4500} onClose={() => setNotice(null)} anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}>
        {notice && <Alert severity={notice.severity} onClose={() => setNotice(null)} variant="filled">{notice.message}</Alert>}
      </Snackbar>
    </Box>
  )
}
