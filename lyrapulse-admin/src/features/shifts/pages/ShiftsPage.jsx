import { useMemo, useState } from 'react'
import {
  Alert, Box, Button, Chip, Dialog, DialogActions, DialogContent, DialogTitle, IconButton, LinearProgress,
  MenuItem, Paper, Snackbar, Stack, Table, TableBody, TableCell, TableContainer, TableHead, TablePagination,
  TableRow, TextField, Tooltip, Typography,
} from '@mui/material'
import { Edit2, Plus, RotateCcw, ToggleLeft, ToggleRight } from 'lucide-react'
import { EmptyState } from '../../../components/common/EmptyState'
import { ErrorState } from '../../../components/common/ErrorState'
import { PageHeader } from '../../../components/common/PageHeader'
import { SearchInput } from '../../../components/common/SearchInput'
import { StatusChip } from '../../../components/common/StatusChip'
import { authService } from '../../../services/authService'
import { ShiftFormDialog } from '../components/ShiftFormDialog'
import { useCreateShift, useShift, useShiftOptions, useShifts, useUpdateShift } from '../hooks/useShiftQueries'

function messageFrom(error) {
  const data = error?.response?.data
  const errors = data?.errors ?? data
  if (errors && typeof errors === 'object') {
    return Object.entries(errors).map(([key, value]) => {
      const text = Array.isArray(value) ? value.map((item) => typeof item === 'string' ? item : JSON.stringify(item)).join(' ') : typeof value === 'string' ? value : JSON.stringify(value)
      return `${key}: ${text}`
    }).join(' ')
  }
  return data?.message ?? error?.message ?? 'Unable to complete this request.'
}

function dateText(value) {
  if (!value) return '—'
  return new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' }).format(new Date(value))
}

export function ShiftsPage() {
  const user = authService.getCurrentUser()
  const canManage = user?.role === 'SUPERADMIN' || user?.permissions?.includes('shifts.manage_shifts')
  const [search, setSearch] = useState('')
  const [branch, setBranch] = useState('')
  const [status, setStatus] = useState('active')
  const [page, setPage] = useState(0)
  const [pageSize, setPageSize] = useState(25)
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editingId, setEditingId] = useState(null)
  const [deactivating, setDeactivating] = useState(null)
  const [notice, setNotice] = useState(null)
  const params = useMemo(() => ({ search: search.trim() || undefined, branch: branch || undefined, status, page: page + 1, page_size: pageSize }), [search, branch, status, page, pageSize])
  const shifts = useShifts(params)
  const options = useShiftOptions()
  const editQuery = useShift(editingId, dialogOpen && Boolean(editingId))
  const createMutation = useCreateShift()
  const updateMutation = useUpdateShift()

  const openCreate = () => { setEditingId(null); setDialogOpen(true) }
  const openEdit = (shift) => { setEditingId(shift.id); setDialogOpen(true) }
  const submit = (payload) => {
    const mutation = editingId ? updateMutation : createMutation
    const variables = editingId ? { id: editingId, payload } : payload
    mutation.mutate(variables, {
      onSuccess: () => {
        setDialogOpen(false)
        setEditingId(null)
        setNotice({ severity: 'success', message: editingId ? 'Shift updated.' : 'Shift created.' })
      },
    })
  }
  const confirmLifecycle = () => {
    updateMutation.mutate({ id: deactivating.id, payload: { is_active: !deactivating.is_active } }, {
      onSuccess: () => {
        setNotice({ severity: 'success', message: deactivating.is_active ? 'Shift deactivated.' : 'Shift reactivated.' })
        setDeactivating(null)
      },
      onError: (error) => setNotice({ severity: 'error', message: messageFrom(error) }),
    })
  }

  const results = shifts.data?.results ?? []
  const pageError = shifts.isError ? messageFrom(shifts.error) : options.branches.isError ? messageFrom(options.branches.error) : ''
  const editError = editingId && editQuery.isError ? messageFrom(editQuery.error) : ''
  const saveError = (createMutation.isError || updateMutation.isError) ? messageFrom(createMutation.error ?? updateMutation.error) : ''

  return (
    <Box>
      <PageHeader
        title="Shifts"
        subtitle="Create and manage employee work schedules."
        action={canManage ? <Button variant="contained" startIcon={<Plus size={17} />} onClick={openCreate}>Create Shift</Button> : null}
      />
      <Paper variant="outlined" sx={{ overflow: 'hidden' }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={1.25} sx={{ p: 2 }}>
          <Box sx={{ flex: '1 1 300px', maxWidth: { md: 460 } }}><SearchInput value={search} onChange={(value) => { setSearch(value); setPage(0) }} placeholder="Search shifts…" label="Search shifts" /></Box>
          <TextField select size="small" label="Branch" value={branch} onChange={(e) => { setBranch(e.target.value); setPage(0) }} sx={{ minWidth: 190 }}>
            <MenuItem value="">All authorized branches</MenuItem>
            {(options.branches.data ?? []).map((item) => <MenuItem key={item.id} value={String(item.id)}>{item.name}</MenuItem>)}
          </TextField>
          <TextField select size="small" label="Status" value={status} onChange={(e) => { setStatus(e.target.value); setPage(0) }} sx={{ minWidth: 150 }}>
            <MenuItem value="active">Active</MenuItem><MenuItem value="inactive">Inactive</MenuItem><MenuItem value="all">All</MenuItem>
          </TextField>
        </Stack>
        {shifts.isFetching ? <LinearProgress aria-label="Loading shifts" /> : null}
        {pageError && !shifts.data ? (
          <Box sx={{ p: 2 }}><ErrorState message={pageError} onRetry={() => shifts.refetch()} retrying={shifts.isFetching} /></Box>
        ) : results.length === 0 ? (
          <EmptyState compact title={search || status !== 'active' ? 'No shifts match these filters' : 'No shifts yet'} description={search || status !== 'active' ? 'Try changing or clearing the filters.' : 'Create a shift to start assigning work schedules.'} />
        ) : (
          <TableContainer sx={{ overflowX: 'auto' }}>
            <Table size="small" sx={{ minWidth: 870 }} aria-label="Shifts">
              <TableHead><TableRow sx={{ bgcolor: 'info.light' }}>
                {['Shift Name', 'Branch', 'Schedule Summary', 'Scheduled Hours / Week', 'Assigned Employees', 'Status', 'Last Modified', 'Actions'].map((label) => <TableCell key={label} sx={{ fontWeight: 700, color: 'primary.main', whiteSpace: 'nowrap' }}>{label}</TableCell>)}
              </TableRow></TableHead>
              <TableBody>
                {results.map((row) => (
                  <TableRow key={row.id} hover>
                    <TableCell><Typography variant="body2" fontWeight={700}>{row.name}</Typography></TableCell>
                    <TableCell>{row.branch_detail?.name ?? '—'}</TableCell>
                    <TableCell sx={{ minWidth: 180 }}>{row.schedule_summary ?? '—'}</TableCell>
                    <TableCell>{row.scheduled_working_seconds_per_week == null ? '—' : `${Math.floor(row.scheduled_working_seconds_per_week / 3600)}h ${Math.floor((row.scheduled_working_seconds_per_week % 3600) / 60) ? `${Math.floor((row.scheduled_working_seconds_per_week % 3600) / 60)}m` : ''}`}</TableCell>
                    <TableCell>{row.assigned_employee_count ?? 0}</TableCell>
                    <TableCell><StatusChip label={row.is_active ? 'Active' : 'Inactive'} /></TableCell>
                    <TableCell sx={{ whiteSpace: 'nowrap' }}>{dateText(row.updated_at)}</TableCell>
                    <TableCell align="right" sx={{ whiteSpace: 'nowrap' }}>
                      {canManage ? <>
                        <Tooltip title="Edit shift"><IconButton size="small" aria-label={`Edit ${row.name}`} onClick={() => openEdit(row)}><Edit2 size={17} /></IconButton></Tooltip>
                        <Tooltip title={row.is_active ? 'Deactivate shift' : 'Reactivate shift'}>
                          <IconButton size="small" aria-label={`${row.is_active ? 'Deactivate' : 'Reactivate'} ${row.name}`} onClick={() => setDeactivating(row)}>
                            {row.is_active ? <ToggleLeft size={18} /> : <ToggleRight size={18} />}
                          </IconButton>
                        </Tooltip>
                      </> : <Chip size="small" variant="outlined" label="View only" />}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
        <TablePagination
          component="div" count={shifts.data?.count ?? 0} page={page} rowsPerPage={pageSize}
          onPageChange={(_event, next) => setPage(next)}
          onRowsPerPageChange={(event) => { setPageSize(Number(event.target.value)); setPage(0) }}
          rowsPerPageOptions={[10, 25, 50, 100]}
        />
      </Paper>

      <ShiftFormDialog
        open={dialogOpen} shift={editingId ? editQuery.data : null} branches={options.branches.data ?? []}
        onClose={() => { setDialogOpen(false); setEditingId(null); createMutation.reset(); updateMutation.reset() }}
        onSave={submit} saving={createMutation.isPending || updateMutation.isPending || Boolean(editingId && editQuery.isLoading)}
        serverError={saveError || editError}
      />

      <Dialog open={Boolean(deactivating)} onClose={() => setDeactivating(null)}>
        <DialogTitle>{deactivating?.is_active ? 'Deactivate shift?' : 'Reactivate shift?'}</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary">
            {deactivating?.is_active
              ? `${deactivating?.name} will remain in assignment history and cannot receive new assignments.`
              : `${deactivating?.name} will be available for new assignments again.`}
          </Typography>
        </DialogContent>
        <DialogActions sx={{ p: 2 }}>
          <Button onClick={() => setDeactivating(null)} disabled={updateMutation.isPending}>Cancel</Button>
          <Button color={deactivating?.is_active ? 'error' : 'primary'} variant="contained" onClick={confirmLifecycle} disabled={updateMutation.isPending}>
            {deactivating?.is_active ? 'Deactivate' : 'Reactivate'}
          </Button>
        </DialogActions>
      </Dialog>
      <Snackbar open={Boolean(notice)} autoHideDuration={5000} onClose={() => setNotice(null)} anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}>
        {notice ? <Alert severity={notice.severity} onClose={() => setNotice(null)} variant="filled">{notice.message}</Alert> : undefined}
      </Snackbar>
    </Box>
  )
}

