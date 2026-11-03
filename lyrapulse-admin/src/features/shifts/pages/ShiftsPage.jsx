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
import { authService } from '../../../services/authService'
import { ShiftFormDialog } from '../components/ShiftFormDialog'
import { formatScheduleSummary, formatTimeAmPm } from '../components/ShiftScheduleEditor'
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

const weekdayLabels = [
  ['SUNDAY', 'Sunday', 'S'], ['MONDAY', 'Monday', 'M'], ['TUESDAY', 'Tuesday', 'T'],
  ['WEDNESDAY', 'Wednesday', 'W'], ['THURSDAY', 'Thursday', 'T'], ['FRIDAY', 'Friday', 'F'],
  ['SATURDAY', 'Saturday', 'S'],
]
const weekdayNames = Object.fromEntries(weekdayLabels.map(([weekday, name]) => [weekday, name.slice(0, 3)]))

function workingDaysText(row) {
  const days = new Map((row.current_schedule?.days ?? []).map((day) => [day.weekday, day.is_working]))
  return (
    <Stack direction="row" spacing={0.25} flexWrap="nowrap" aria-label="Working days" sx={{ whiteSpace: 'nowrap' }}>
      {weekdayLabels.map(([weekday, name, initial]) => {
        const isWorking = Boolean(days.get(weekday))
        return (
          <Tooltip key={weekday} title={name}>
            <Box component="span" aria-label={`${name}: ${isWorking ? 'working' : 'off'}`} sx={{
              width: 22, height: 22, flex: '0 0 22px', display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              borderRadius: 0.75, bgcolor: isWorking ? 'info.light' : 'action.hover',
            }}>
              <Typography component="span" sx={{ color: isWorking ? 'text.primary' : 'text.secondary', fontSize: '0.75rem', lineHeight: 1, fontWeight: 700 }}>
                {initial}
              </Typography>
            </Box>
          </Tooltip>
        )
      })}
    </Stack>
  )
}

function timeRangesText(row) {
  const days = row.current_schedule?.days?.filter((day) => day.is_working && day.start_time && day.end_time) ?? []
  if (!days.length) return formatScheduleSummary(row.schedule_summary ?? '—')
  const ranges = new Map()
  days.forEach((day) => {
    const key = `${day.start_time}|${day.end_time}`
    ranges.set(key, [...(ranges.get(key) ?? []), weekdayNames[day.weekday]])
  })
  return [...ranges.entries()].map(([range, names]) => {
    const [start, end] = range.split('|')
    const label = names.length === 7 ? 'Sun–Sat'
      : names.join(',') === 'Mon,Tue,Wed,Thu,Fri' ? 'Mon–Fri'
        : names.join(' · ')
    return `${ranges.size > 1 ? `${label} ` : ''}${formatTimeAmPm(start)} – ${formatTimeAmPm(end)}`
  }).join('  ·  ')
}

const shiftColumnWidths = [165, 120, 210, 250, 150, 100, 140, 100]

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
            <Table size="small" sx={{ minWidth: 1180, tableLayout: 'fixed', '& .MuiTableCell-root': { px: 1, py: 1 }, '& .MuiTableBody-root .MuiTableRow-root': { height: 64, '& > .MuiTableCell-root': { py: 1.25, px: 1.5, fontSize: '0.875rem', verticalAlign: 'middle', whiteSpace: 'nowrap' } } }} aria-label="Shifts">
              <TableHead><TableRow sx={{ bgcolor: 'info.light' }}>
                {['Shift Name', 'Branch', 'Working Days', 'Shift Timing', 'Assigned Employees', 'Status', 'Last Modified', 'Actions'].map((label, index) => <TableCell key={label} align={label === 'Assigned Employees' || label === 'Status' ? 'center' : undefined} sx={{ width: shiftColumnWidths[index], fontWeight: 700, color: 'primary.main', whiteSpace: 'nowrap' }}>{label}</TableCell>)}
              </TableRow></TableHead>
              <TableBody>
                {results.map((row) => (
                  <TableRow key={row.id} hover>
                    <TableCell sx={{ width: 165 }}><Tooltip title={row.name}><Typography variant="body2" fontWeight={700} noWrap>{row.name}</Typography></Tooltip></TableCell>
                    <TableCell sx={{ width: 120 }}><Tooltip title={row.branch_detail?.name ?? ''}><Typography variant="body2" noWrap>{row.branch_detail?.name ?? '—'}</Typography></Tooltip></TableCell>
                    <TableCell sx={{ width: 210, whiteSpace: 'nowrap' }}>{workingDaysText(row)}</TableCell>
                    <TableCell sx={{ width: 250, whiteSpace: 'nowrap' }}><Tooltip title={timeRangesText(row)}><Typography variant="body2" noWrap>{timeRangesText(row)}</Typography></Tooltip></TableCell>
                    <TableCell align="center" sx={{ width: 150, fontWeight: 600 }}>{row.assigned_employee_count ?? 0}</TableCell>
                    <TableCell align="center" sx={{ width: 100 }}><Chip size="small" variant="outlined" color={row.is_active ? 'success' : 'default'} label={row.is_active ? 'Active' : 'Inactive'} sx={{ height: 24, fontWeight: 600, bgcolor: 'background.paper' }} /></TableCell>
                    <TableCell sx={{ width: 140, whiteSpace: 'nowrap' }}>{dateText(row.updated_at)}</TableCell>
                    <TableCell align="right" sx={{ width: 100, whiteSpace: 'nowrap' }}>
                      {canManage ? <>
                        <Tooltip title="Edit Shift"><IconButton size="small" aria-label={`Edit ${row.name}`} onClick={() => openEdit(row)}><Edit2 size={17} /></IconButton></Tooltip>
                        <Tooltip title={row.is_active ? 'Deactivate shift' : 'Reactivate shift'}>
                          <IconButton size="small" sx={{ ml: 0.5 }} aria-label={`${row.is_active ? 'Deactivate' : 'Reactivate'} ${row.name}`} onClick={() => setDeactivating(row)}>
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

