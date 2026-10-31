import { useMemo, useState } from 'react'
import { Alert, Box, Button, LinearProgress, MenuItem, Paper, Snackbar, Stack, Table, TableBody, TableCell, TableContainer, TableHead, TablePagination, TableRow, TextField, Typography } from '@mui/material'
import { History, Plus } from 'lucide-react'
import { authService } from '../../../services/authService'
import { EmptyState } from '../../../components/common/EmptyState'
import { ErrorState } from '../../../components/common/ErrorState'
import { PageHeader } from '../../../components/common/PageHeader'
import { SearchInput } from '../../../components/common/SearchInput'
import { StatusChip } from '../../../components/common/StatusChip'
import { AssignmentHistoryDrawer } from '../components/AssignmentHistoryDrawer'
import { ShiftAssignmentDialog } from '../components/ShiftAssignmentDialog'
import { useAssignShift, useBulkAssignShift, useShiftAssignments, useShiftOptions, useShifts } from '../hooks/useShiftQueries'

const errorText = (error) => {
  const data = error?.response?.data?.errors ?? error?.response?.data ?? {}
  if (typeof data === 'string') return data
  if (data && typeof data === 'object') return Object.entries(data).map(([key, value]) => `${key}: ${Array.isArray(value) ? value.join(' ') : typeof value === 'string' ? value : JSON.stringify(value)}`).join(' ')
  return error?.message ?? 'Unable to complete this request.'
}

export function ShiftAssignmentsPage() {
  const user = authService.getCurrentUser()
  const canAssign = user?.role === 'SUPERADMIN' || user?.permissions?.includes('shifts.assign_shiftassignment')
  const [search, setSearch] = useState('')
  const [branch, setBranch] = useState('')
  const [department, setDepartment] = useState('')
  const [designation, setDesignation] = useState('')
  const [status, setStatus] = useState('current')
  const [page, setPage] = useState(0)
  const [pageSize, setPageSize] = useState(25)
  const [selected, setSelected] = useState([])
  const [dialogOpen, setDialogOpen] = useState(false)
  const [historyEmployee, setHistoryEmployee] = useState(null)
  const [notice, setNotice] = useState(null)
  const params = useMemo(() => ({ search: search.trim() || undefined, branch: branch || undefined, department: department || undefined, designation: designation || undefined, status, page: page + 1, page_size: pageSize }), [search, branch, department, designation, status, page, pageSize])
  const query = useShiftAssignments(params)
  const options = useShiftOptions()
  const shifts = useShifts({ branch: branch || undefined, status: 'active', page_size: 100 })
  const assign = useAssignShift()
  const bulkAssign = useBulkAssignShift()
  const rows = query.data?.results ?? []
  const people = [...new Map(rows.map((row) => [row.employee.id, row.employee])).values()]
  const error = query.isError ? errorText(query.error) : ''
  const saveMutation = selected.length ? bulkAssign : assign
  const saveError = saveMutation.isError ? errorText(saveMutation.error) : ''
  const onSave = (payload) => saveMutation.mutate(payload, {
    onSuccess: (result) => { setDialogOpen(false); setSelected([]); setNotice({ severity: 'success', message: `Shift assigned to ${result?.created_count ?? 1} employee${(result?.created_count ?? 1) === 1 ? '' : 's'}.` }) },
    onError: (e) => setNotice({ severity: 'error', message: errorText(e) }),
  })
  const toggleSelected = (employee) => setSelected((items) => items.some((item) => item.id === employee.id) ? items.filter((item) => item.id !== employee.id) : [...items, employee])
  return <Box>
    <PageHeader title="Shift Assignments" subtitle="Assign branch shifts, set employee week off days, and review assignment history." action={canAssign ? <Button variant="contained" startIcon={<Plus size={17} />} onClick={() => { setSelected([]); setDialogOpen(true) }}>Assign Shift</Button> : null} />
    <Paper variant="outlined" sx={{ overflow: 'hidden' }}>
      <Stack direction={{ xs: 'column', lg: 'row' }} spacing={1.25} sx={{ p: 2 }}>
        <Box sx={{ flex: '1 1 260px', maxWidth: { lg: 360 } }}><SearchInput value={search} onChange={(v) => { setSearch(v); setPage(0) }} placeholder="Search employees…" label="Search employees" /></Box>
        <TextField select size="small" label="Branch" value={branch} onChange={(e) => { setBranch(e.target.value); setPage(0) }} sx={{ minWidth: 170 }}><MenuItem value="">All branches</MenuItem>{(options.branches.data ?? []).map((x) => <MenuItem key={x.id} value={String(x.id)}>{x.name}</MenuItem>)}</TextField>
        <TextField select size="small" label="Department" value={department} onChange={(e) => { setDepartment(e.target.value); setPage(0) }} sx={{ minWidth: 170 }}><MenuItem value="">All departments</MenuItem>{(options.departments.data ?? []).map((x) => <MenuItem key={x.id} value={String(x.id)}>{x.name}</MenuItem>)}</TextField>
        <TextField select size="small" label="Designation" value={designation} onChange={(e) => { setDesignation(e.target.value); setPage(0) }} sx={{ minWidth: 170 }}><MenuItem value="">All designations</MenuItem>{(options.designations.data ?? []).map((x) => <MenuItem key={x.id} value={String(x.id)}>{x.name}</MenuItem>)}</TextField>
        <TextField select size="small" label="Status" value={status} onChange={(e) => { setStatus(e.target.value); setPage(0) }} sx={{ minWidth: 140 }}><MenuItem value="current">Current</MenuItem><MenuItem value="future">Future</MenuItem><MenuItem value="expired">Expired</MenuItem><MenuItem value="all">All</MenuItem></TextField>
      </Stack>
      {canAssign && selected.length ? <Stack direction="row" alignItems="center" spacing={1} sx={{ px: 2, pb: 1.5 }}><Typography variant="body2">{selected.length} selected</Typography><Button size="small" onClick={() => setDialogOpen(true)}>Assign shift to selected</Button><Button size="small" onClick={() => setSelected([])}>Clear</Button></Stack> : null}
      {query.isFetching ? <LinearProgress /> : null}
      {error && !query.data ? <Box sx={{ p: 2 }}><ErrorState message={error} onRetry={() => query.refetch()} retrying={query.isFetching} /></Box> : rows.length === 0 ? <EmptyState compact title="No assignments found" description="Change the filters or assign a shift to an employee." /> : <TableContainer sx={{ overflowX: 'auto' }}><Table size="small" sx={{ minWidth: 1000 }} aria-label="Shift assignments"><TableHead><TableRow sx={{ bgcolor: 'info.light' }}>{canAssign ? <TableCell padding="checkbox" /> : null}{['Employee', 'Branch', 'Department', 'Designation', 'Shift', 'Effective period', 'Week off', 'Status', 'History'].map((item) => <TableCell key={item} sx={{ fontWeight: 700, whiteSpace: 'nowrap', color: 'primary.main' }}>{item}</TableCell>)}</TableRow></TableHead><TableBody>{rows.map((row) => <TableRow key={row.id} hover>{canAssign ? <TableCell padding="checkbox"><input type="checkbox" aria-label={`Select ${row.employee.name}`} checked={selected.some((item) => item.id === row.employee.id)} onChange={() => toggleSelected(row.employee)} /></TableCell> : null}<TableCell><Typography variant="body2" fontWeight={700}>{row.employee.name}</Typography><Typography variant="caption" color="text.secondary">{row.employee.employee_code}</Typography></TableCell><TableCell>{row.branch?.name ?? '—'}</TableCell><TableCell>{row.employee.department?.name ?? '—'}</TableCell><TableCell>{row.employee.designation?.name ?? '—'}</TableCell><TableCell>{row.shift?.name ?? '—'}</TableCell><TableCell sx={{ whiteSpace: 'nowrap' }}>{row.effective_from} — {row.effective_to ?? 'No end date'}</TableCell><TableCell>{row.week_off_days?.join(', ') || '—'}</TableCell><TableCell><StatusChip label={row.assignment_state} /></TableCell><TableCell><Button size="small" startIcon={<History size={15} />} onClick={() => setHistoryEmployee(row.employee)}>History</Button></TableCell></TableRow>)}</TableBody></Table></TableContainer>}
      <TablePagination component="div" count={query.data?.count ?? 0} page={page} rowsPerPage={pageSize} onPageChange={(_e, next) => setPage(next)} onRowsPerPageChange={(e) => { setPageSize(Number(e.target.value)); setPage(0) }} rowsPerPageOptions={[10,25,50,100]} />
    </Paper>
    <ShiftAssignmentDialog open={dialogOpen} onClose={() => { setDialogOpen(false); setSelected([]); assign.reset(); bulkAssign.reset() }} branches={options.branches.data ?? []} shifts={shifts.data?.results ?? []} selectedEmployees={selected} onSave={onSave} saving={assign.isPending || bulkAssign.isPending} error={saveError} />
    <AssignmentHistoryDrawer employee={historyEmployee} open={Boolean(historyEmployee)} onClose={() => setHistoryEmployee(null)} />
    <Snackbar open={Boolean(notice)} autoHideDuration={5000} onClose={() => setNotice(null)} anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}><Alert severity={notice?.severity ?? 'success'} onClose={() => setNotice(null)} variant="filled">{notice?.message}</Alert></Snackbar>
  </Box>
}
