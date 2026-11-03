import { useMemo, useState } from 'react'
import {
  Alert, Box, Button, Checkbox, LinearProgress, MenuItem, Paper, Snackbar, Stack, Table,
  TableBody, TableCell, TableContainer, TableHead, TablePagination, TableRow, TextField, Tooltip, Typography,
} from '@mui/material'
import { History, Plus } from 'lucide-react'
import { authService } from '../../../services/authService'
import { EmptyState } from '../../../components/common/EmptyState'
import { ErrorState } from '../../../components/common/ErrorState'
import { PageHeader } from '../../../components/common/PageHeader'
import { SearchInput } from '../../../components/common/SearchInput'
import { StatusChip } from '../../../components/common/StatusChip'
import { AssignmentHistoryDrawer } from '../components/AssignmentHistoryDrawer'
import { ShiftAssignmentDialog } from '../components/ShiftAssignmentDialog'
import {
  useAllShiftAssignments, useAllShifts, useAssignShift, useBulkAssignShift, useEmployeesForBranch,
  useShiftOptions,
} from '../hooks/useShiftQueries'
import { formatTimeAmPm } from '../components/ShiftScheduleEditor'

const EMPTY_LIST = Object.freeze([])

const errorText = (error) => {
  const data = error?.response?.data?.errors ?? error?.response?.data ?? {}
  if (typeof data === 'string') return data
  if (data && typeof data === 'object') return Object.entries(data).map(([key, value]) => `${key}: ${Array.isArray(value) ? value.join(' ') : typeof value === 'string' ? value : JSON.stringify(value)}`).join(' ')
  return error?.message ?? 'Unable to complete this request.'
}

const weekdayLabels = [
  ['SUNDAY', 'Sunday', 'S'], ['MONDAY', 'Monday', 'M'], ['TUESDAY', 'Tuesday', 'T'],
  ['WEDNESDAY', 'Wednesday', 'W'], ['THURSDAY', 'Thursday', 'T'], ['FRIDAY', 'Friday', 'F'],
  ['SATURDAY', 'Saturday', 'S'],
]

function scheduleTimeText(shift) {
  const days = shift?.current_schedule?.days?.filter((day) => day.is_working) ?? []
  if (!days.length) return 'Schedule unavailable'
  const ranges = [...new Set(days.filter((day) => day.start_time && day.end_time).map((day) => `${day.start_time}|${day.end_time}`))]
  return ranges.length ? ranges.map((range) => {
    const [start, end] = range.split('|')
    return `${formatTimeAmPm(start)} – ${formatTimeAmPm(end)}`
  }).join(' · ') : 'Schedule unavailable'
}

function scheduleDaysText(shift) {
  const schedule = shift?.current_schedule?.days
  if (!schedule?.length) return '—'
  const workdays = new Set(schedule.filter((day) => day.is_working).map((day) => day.weekday))
  return (
    <Stack direction="row" spacing={0.25} flexWrap="nowrap" sx={{ whiteSpace: 'nowrap' }} aria-label="Shift working days">
      {weekdayLabels.map(([weekday, name, letter]) => {
        const active = workdays.has(weekday)
        return <Tooltip key={weekday} title={name}>
          <Box component="span" aria-label={`${name}: ${active ? 'working' : 'off'}`} sx={{
            width: 20, height: 22, flex: '0 0 20px', display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            borderRadius: 0.75, bgcolor: active ? 'info.light' : 'action.hover', color: active ? 'text.primary' : 'text.secondary',
            fontSize: '0.75rem', lineHeight: 1, fontWeight: 700,
          }}>{letter}</Box>
        </Tooltip>
      })}
    </Stack>
  )
}

function dateText(value) {
  if (!value) return '—'
  const date = new Date(`${value.slice(0, 10)}T00:00:00`)
  return new Intl.DateTimeFormat(undefined, { day: '2-digit', month: 'short', year: 'numeric' }).format(date)
}

function employeeName(employee) {
  return employee.display_name?.trim() || employee.name || `${employee.first_name ?? ''} ${employee.last_name ?? ''}`.trim()
}

function assignmentIndex(assignments) {
  const grouped = new Map()
  assignments.forEach((assignment) => {
    const rows = grouped.get(assignment.employee.id) ?? []
    rows.push(assignment)
    grouped.set(assignment.employee.id, rows)
  })
  return new Map([...grouped.entries()].map(([employeeId, rows]) => {
    const current = rows.find((row) => row.assignment_state === 'CURRENT') ?? null
    const future = rows.filter((row) => row.assignment_state === 'FUTURE').sort((a, b) => a.effective_from.localeCompare(b.effective_from))[0] ?? null
    const previous = rows.filter((row) => row.assignment_state === 'EXPIRED').sort((a, b) => b.effective_from.localeCompare(a.effective_from))[0] ?? null
    return [employeeId, { current, future, previous }]
  }))
}

export function ShiftAssignmentsPage() {
  const user = authService.getCurrentUser()
  const canAssign = user?.role === 'SUPERADMIN' || user?.permissions?.includes('shifts.assign_shiftassignment')
  const [search, setSearch] = useState('')
  const [branch, setBranch] = useState('')
  const [department, setDepartment] = useState('')
  const [designation, setDesignation] = useState('')
  const [status, setStatus] = useState('all')
  const [page, setPage] = useState(0)
  const [pageSize, setPageSize] = useState(25)
  const [selected, setSelected] = useState([])
  const [dialogOpen, setDialogOpen] = useState(false)
  const [historyEmployee, setHistoryEmployee] = useState(null)
  const [notice, setNotice] = useState(null)

  const employeeFilters = useMemo(() => ({
    branch: branch || undefined, department: department || undefined, designation: designation || undefined,
  }), [branch, department, designation])
  const employeesQuery = useEmployeesForBranch(employeeFilters)
  const assignmentsQuery = useAllShiftAssignments({ ...employeeFilters, status: 'all' })
  const shiftsQuery = useAllShifts({ branch: branch || undefined, status: 'all' })
  const options = useShiftOptions()
  const assign = useAssignShift()
  const bulkAssign = useBulkAssignShift()
  const employees = employeesQuery.data ?? EMPTY_LIST
  const assignments = assignmentsQuery.data ?? EMPTY_LIST
  const assignmentByEmployee = useMemo(() => assignmentIndex(assignments), [assignments])
  const shiftsById = useMemo(() => new Map((shiftsQuery.data ?? EMPTY_LIST).map((shift) => [shift.id, shift])), [shiftsQuery.data])
  const branchesById = useMemo(() => new Map((options.branches.data ?? EMPTY_LIST).map((item) => [item.id, item.name])), [options.branches.data])
  const designationsById = useMemo(() => new Map((options.designations.data ?? EMPTY_LIST).map((item) => [item.id, item.name])), [options.designations.data])

  const normalizedSearch = search.trim().toLocaleLowerCase()
  const filteredEmployees = useMemo(() => employees.filter((employee) => {
    const name = employeeName(employee).toLocaleLowerCase()
    const code = String(employee.employee_code ?? '').toLocaleLowerCase()
    const record = assignmentByEmployee.get(employee.id) ?? {}
    if (normalizedSearch && !name.includes(normalizedSearch) && !code.includes(normalizedSearch)) return false
    if (status === 'current' && !record.current) return false
    if (status === 'unassigned' && record.current) return false
    if (status === 'future' && !record.future) return false
    if (status === 'expired' && (record.current || !record.previous)) return false
    return true
  }), [employees, assignmentByEmployee, normalizedSearch, status])

  const pageRows = filteredEmployees.slice(page * pageSize, (page + 1) * pageSize)
  const pageSelectable = pageRows.filter((employee) => employee.is_active && employee.branch)
  const visibleIds = pageSelectable.map((employee) => employee.id)
  const selectedIds = new Set(selected.map((employee) => employee.id))
  const allVisibleSelected = visibleIds.length > 0 && visibleIds.every((id) => selectedIds.has(id))
  const someVisibleSelected = visibleIds.some((id) => selectedIds.has(id))
  const selectedBranchIds = new Set(selected.map((employee) => String(employee.branch)))
  const mixedBranchSelection = selectedBranchIds.size > 1
  const currentError = employeesQuery.isError ? errorText(employeesQuery.error)
    : assignmentsQuery.isError ? errorText(assignmentsQuery.error)
      : shiftsQuery.isError ? errorText(shiftsQuery.error) : ''
  const isLoading = employeesQuery.isFetching || assignmentsQuery.isFetching || shiftsQuery.isFetching
  const saveMutation = selected.length > 0 ? bulkAssign : assign
  const saveError = saveMutation.isError ? errorText(saveMutation.error) : ''

  const resetSelection = () => setSelected([])
  const onSave = (payload) => saveMutation.mutate(payload, {
    onSuccess: (result) => {
      const assignedCount = result?.created_count ?? 1
      setDialogOpen(false)
      setSelected([])
      setNotice({ severity: 'success', message: `Shift assigned to ${assignedCount} employee${assignedCount === 1 ? '' : 's'}.` })
    },
    onError: (error) => setNotice({ severity: 'error', message: errorText(error) }),
  })

  const toggleEmployee = (employee) => {
    const exists = selectedIds.has(employee.id)
    if (exists) {
      setSelected((rows) => rows.filter((row) => row.id !== employee.id))
      return
    }
    if (!employee.is_active || !employee.branch) return
    if (selected.length && String(selected[0].branch) !== String(employee.branch)) {
      setNotice({ severity: 'warning', message: 'Bulk assignment requires employees from the same branch. Filter by branch or clear the selection.' })
      return
    }
    setSelected((rows) => [...rows, employee])
  }

  const togglePageSelection = () => {
    if (allVisibleSelected) {
      setSelected((rows) => rows.filter((employee) => !visibleIds.includes(employee.id)))
      return
    }
    const pageBranches = new Set(pageSelectable.map((employee) => String(employee.branch)))
    if (pageBranches.size > 1 && !branch) {
      setNotice({ severity: 'warning', message: 'Choose one branch before selecting all employees for a bulk assignment.' })
      return
    }
    if (selected.length && pageSelectable.some((employee) => String(employee.branch) !== String(selected[0].branch))) {
      setNotice({ severity: 'warning', message: 'Bulk assignment requires employees from the same branch. Clear the selection or filter by branch.' })
      return
    }
    setSelected((rows) => [...new Map([...rows, ...pageSelectable].map((employee) => [employee.id, employee])).values()])
  }

  const changeFilter = (setter) => (event) => {
    setter(event.target.value)
    setPage(0)
    resetSelection()
  }
  const retry = () => Promise.all([employeesQuery.refetch(), assignmentsQuery.refetch(), shiftsQuery.refetch()])

  return <Box>
    <PageHeader
      title="Shift Assignments"
      subtitle="Assign shifts to employees and manage their work schedules."
      action={canAssign ? (
        <Button variant="contained" startIcon={<Plus size={17} />} disabled={mixedBranchSelection}
          onClick={() => setDialogOpen(true)}>
          Assign Shift
        </Button>
      ) : null}
    />
    <Paper variant="outlined" sx={{ overflow: 'hidden' }}>
      <Stack direction="row" flexWrap="wrap" spacing={1.25} useFlexGap sx={{ p: 2, alignItems: 'center' }}>
        <Box sx={{ flex: '2 1 300px', minWidth: 260 }}>
          <SearchInput value={search} onChange={(value) => { setSearch(value); setPage(0) }} placeholder="Search employee name or ID..." label="Search employee name or ID" />
        </Box>
        <TextField select size="small" label="Branch" value={branch} onChange={changeFilter(setBranch)} sx={{ flex: '1 1 150px', minWidth: 145 }}>
          <MenuItem value="">All branches</MenuItem>{(options.branches.data ?? []).map((item) => <MenuItem key={item.id} value={String(item.id)}>{item.name}</MenuItem>)}
        </TextField>
        <TextField select size="small" label="Department" value={department} onChange={changeFilter(setDepartment)} sx={{ flex: '1 1 150px', minWidth: 145 }}>
          <MenuItem value="">All departments</MenuItem>{(options.departments.data ?? []).map((item) => <MenuItem key={item.id} value={String(item.id)}>{item.name}</MenuItem>)}
        </TextField>
        <TextField select size="small" label="Designation" value={designation} onChange={changeFilter(setDesignation)} sx={{ flex: '1 1 150px', minWidth: 145 }}>
          <MenuItem value="">All designations</MenuItem>{(options.designations.data ?? []).map((item) => <MenuItem key={item.id} value={String(item.id)}>{item.name}</MenuItem>)}
        </TextField>
        <TextField select size="small" label="Employee Status" value={status} onChange={changeFilter(setStatus)} sx={{ flex: '1 1 150px', minWidth: 145 }}>
          <MenuItem value="all">All Employees</MenuItem><MenuItem value="current">Assigned</MenuItem><MenuItem value="unassigned">Unassigned</MenuItem><MenuItem value="future">Future assignment</MenuItem><MenuItem value="expired">Previous assignment</MenuItem>
        </TextField>
      </Stack>
      {canAssign && selected.length ? (
        <Stack direction={{ xs: 'column', sm: 'row' }} alignItems={{ sm: 'center' }} justifyContent="space-between" spacing={1.5} sx={{ mx: 2, mb: 1.5, px: 1.5, py: 1, border: 1, borderColor: 'divider', borderRadius: 1 }}>
          <Typography variant="body2" fontWeight={600}>{selected.length} employee{selected.length === 1 ? '' : 's'} selected</Typography>
          <Stack direction={{ xs: 'column', sm: 'row' }} flexWrap="wrap" alignItems={{ sm: 'center' }} spacing={1}>
            {mixedBranchSelection ? <Alert severity="warning" sx={{ py: 0 }}>Choose employees from one branch.</Alert> : null}
            <Button size="small" variant="contained" disabled={mixedBranchSelection} onClick={() => setDialogOpen(true)}>Assign Shift</Button>
            <Button size="small" onClick={resetSelection}>Clear Selection</Button>
          </Stack>
        </Stack>
      ) : null}
      {isLoading ? <LinearProgress aria-label="Loading employees and shift assignments" /> : null}
      {currentError ? (
        <Box sx={{ p: 2 }}><ErrorState message={currentError} onRetry={retry} retrying={isLoading} /></Box>
      ) : filteredEmployees.length === 0 ? (
        <EmptyState compact title={normalizedSearch || status !== 'all' ? 'No employees match these filters' : 'No employees found'} description="Try changing the filters or clearing the search." />
      ) : (
        <TableContainer sx={{ overflowX: 'auto' }}>
          <Table size="small" sx={{ minWidth: canAssign ? 1600 : 1550, tableLayout: 'fixed', '& .MuiTableBody-root .MuiTableRow-root': { height: 64, '& > .MuiTableCell-root': { py: 1.25, px: 1.5, fontSize: '0.875rem', verticalAlign: 'middle', whiteSpace: 'nowrap' } } }} aria-label="Employee shift assignments">
            <TableHead><TableRow sx={{ bgcolor: 'info.light', height: 48 }}>
              {canAssign ? <TableCell padding="checkbox" sx={{ width: 48 }}>
                <Checkbox size="small" checked={allVisibleSelected} indeterminate={!allVisibleSelected && someVisibleSelected}
                  disabled={pageSelectable.length === 0} onChange={togglePageSelection} inputProps={{ 'aria-label': 'Select all employees on this page' }} />
              </TableCell> : null}
              {['Employee', 'Designation', 'Branch', 'Assigned Shift', 'Working Days', 'Effective From', 'Week Off', 'Status', 'Actions'].map((label, index) => <TableCell key={label} align={label === 'Status' ? 'center' : undefined} sx={{ width: [210, 180, 155, 245, 180, 185, 115, 110, 110][index], fontWeight: 700, whiteSpace: 'nowrap', color: 'primary.main' }}>{label}</TableCell>)}
            </TableRow></TableHead>
            <TableBody>
              {pageRows.map((employee) => {
                const assignment = assignmentByEmployee.get(employee.id) ?? {}
                const displayedAssignment = assignment.current ?? assignment.future ?? assignment.previous
                const scheduledAssignment = assignment.current ?? assignment.future
                const displayedShift = scheduledAssignment ? shiftsById.get(scheduledAssignment.shift.id) : null
                const selectedEmployee = selectedIds.has(employee.id)
                return (
                  <TableRow key={employee.id} hover selected={selectedEmployee}>
                    {canAssign ? <TableCell padding="checkbox">
                      <Checkbox size="small" checked={selectedEmployee} disabled={!employee.is_active || !employee.branch}
                        onChange={() => toggleEmployee(employee)} inputProps={{ 'aria-label': `Select ${employeeName(employee)}` }} />
                    </TableCell> : null}
                    <TableCell sx={{ width: 210 }}>
                      <Tooltip title={employeeName(employee)}><Typography variant="body2" fontWeight={700} noWrap>{employeeName(employee)}</Typography></Tooltip>
                      <Typography variant="caption" color="text.secondary" noWrap>{employee.employee_code || '—'}</Typography>
                    </TableCell>
                    <TableCell sx={{ width: 180 }}><Tooltip title={employee.designation ? designationsById.get(employee.designation) ?? '' : ''}><Typography variant="body2" noWrap>{employee.designation ? designationsById.get(employee.designation) ?? '—' : '—'}</Typography></Tooltip></TableCell>
                    <TableCell sx={{ width: 155 }}><Tooltip title={branchesById.get(employee.branch) ?? ''}><Typography variant="body2" noWrap>{branchesById.get(employee.branch) ?? '—'}</Typography></Tooltip></TableCell>
                    <TableCell sx={{ width: 245 }}>
                      {displayedShift ? <Stack spacing={0.25} sx={{ minWidth: 0 }}>
                        <Tooltip title={scheduledAssignment.shift.name}><Typography variant="body2" fontWeight={600} noWrap>{scheduledAssignment.shift.name}</Typography></Tooltip>
                        <Tooltip title={scheduleTimeText(displayedShift)}><Typography variant="caption" color="text.secondary" noWrap>{assignment.future && !assignment.current ? 'Upcoming · ' : ''}{scheduleTimeText(displayedShift)}</Typography></Tooltip>
                      </Stack> : <Stack spacing={0.25}>
                        <Typography variant="body2" color="text.secondary">No shift assigned</Typography>
                        {assignment.previous ? <Typography variant="caption" color="text.secondary" noWrap>Previous: {assignment.previous.shift.name}</Typography> : null}
                      </Stack>}
                    </TableCell>
                    <TableCell sx={{ width: 180 }}>{displayedShift ? scheduleDaysText(displayedShift) : '—'}</TableCell>
                    <TableCell sx={{ width: 185, whiteSpace: 'nowrap' }}>{displayedAssignment ? <Stack spacing={0.25}><Typography variant="body2">{dateText(displayedAssignment.effective_from)}</Typography>{displayedAssignment.effective_to ? <Typography variant="caption" color="text.secondary">to {dateText(displayedAssignment.effective_to)}</Typography> : null}</Stack> : '—'}</TableCell>
                    <TableCell sx={{ width: 115, whiteSpace: 'nowrap' }}>{displayedAssignment?.week_off_days?.length ? displayedAssignment.week_off_days.join(', ') : 'Not set'}</TableCell>
                    <TableCell align="center" sx={{ width: 110 }}><StatusChip label={assignment.current ? 'Assigned' : 'Unassigned'} color={assignment.current ? 'success' : 'default'} /></TableCell>
                    <TableCell align="center" sx={{ width: 110 }}><Tooltip title="Assignment History"><Button size="small" aria-label={`Assignment history for ${employeeName(employee)}`} onClick={() => setHistoryEmployee({ id: employee.id, name: employeeName(employee), employee_code: employee.employee_code })}><History size={17} /></Button></Tooltip></TableCell>
                  </TableRow>
                )
              })}
            </TableBody>
          </Table>
        </TableContainer>
      )}
      <TablePagination component="div" count={filteredEmployees.length} page={page} rowsPerPage={pageSize}
        onPageChange={(_event, next) => setPage(next)}
        onRowsPerPageChange={(event) => { setPageSize(Number(event.target.value)); setPage(0) }} rowsPerPageOptions={[10, 25, 50, 100]} />
    </Paper>
    <ShiftAssignmentDialog open={dialogOpen} onClose={() => { setDialogOpen(false); assign.reset(); bulkAssign.reset() }}
      branches={options.branches.data ?? []} shifts={[]} selectedEmployees={selected} onSave={onSave}
      saving={assign.isPending || bulkAssign.isPending} error={saveError} />
    <AssignmentHistoryDrawer employee={historyEmployee} open={Boolean(historyEmployee)} onClose={() => setHistoryEmployee(null)} />
    <Snackbar open={Boolean(notice)} autoHideDuration={5000} onClose={() => setNotice(null)} anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}>
      {notice ? <Alert severity={notice.severity} onClose={() => setNotice(null)} variant="filled">{notice.message}</Alert> : undefined}
    </Snackbar>
  </Box>
}
