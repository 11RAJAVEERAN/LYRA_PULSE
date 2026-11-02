import { useMemo, useState } from 'react'
import {
  Alert, Box, Button, Checkbox, Chip, LinearProgress, MenuItem, Paper, Snackbar, Stack, Table,
  TableBody, TableCell, TableContainer, TableHead, TablePagination, TableRow, TextField, Typography,
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

const weekdayNames = {
  SUNDAY: 'Sun', MONDAY: 'Mon', TUESDAY: 'Tue', WEDNESDAY: 'Wed',
  THURSDAY: 'Thu', FRIDAY: 'Fri', SATURDAY: 'Sat',
}

function scheduleText(shift) {
  const days = shift?.current_schedule?.days?.filter((day) => day.is_working) ?? []
  if (!days.length) return shift?.schedule_summary === 'Varies by day' ? 'Varies by day' : 'Schedule unavailable'
  const ranges = new Map()
  days.forEach((day) => {
    const key = `${day.start_time}|${day.end_time}`
    ranges.set(key, [...(ranges.get(key) ?? []), day.weekday])
  })
  return [...ranges.entries()].map(([range, weekdays]) => {
    const [start, end] = range.split('|')
    const dayLabel = weekdays.length === 5 && weekdays[0] === 'MONDAY' && weekdays[4] === 'FRIDAY'
      ? 'Mon–Fri'
      : weekdays.map((weekday) => weekdayNames[weekday]).join(', ')
    return `${dayLabel} · ${formatTimeAmPm(start)}–${formatTimeAmPm(end)}`
  }).join('  |  ')
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

function employeeName(employee) {
  return employee.display_name?.trim() || employee.name || `${employee.first_name ?? ''} ${employee.last_name ?? ''}`.trim()
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
      subtitle="Assign shifts to employees and review their assignment history."
      action={canAssign ? (
        <Button variant="contained" startIcon={<Plus size={17} />} disabled={mixedBranchSelection}
          onClick={() => setDialogOpen(true)}>
          {selected.length ? `Assign to selected (${selected.length})` : 'Assign Shift'}
        </Button>
      ) : null}
    />
    <Paper variant="outlined" sx={{ overflow: 'hidden' }}>
      <Stack direction={{ xs: 'column', lg: 'row' }} spacing={1.25} sx={{ p: 2 }}>
        <Box sx={{ flex: '1 1 260px', maxWidth: { lg: 360 } }}>
          <SearchInput value={search} onChange={(value) => { setSearch(value); setPage(0) }} placeholder="Search employees…" label="Search employees" />
        </Box>
        <TextField select size="small" label="Branch" value={branch} onChange={changeFilter(setBranch)} sx={{ minWidth: 170 }}>
          <MenuItem value="">All branches</MenuItem>{(options.branches.data ?? []).map((item) => <MenuItem key={item.id} value={String(item.id)}>{item.name}</MenuItem>)}
        </TextField>
        <TextField select size="small" label="Department" value={department} onChange={changeFilter(setDepartment)} sx={{ minWidth: 170 }}>
          <MenuItem value="">All departments</MenuItem>{(options.departments.data ?? []).map((item) => <MenuItem key={item.id} value={String(item.id)}>{item.name}</MenuItem>)}
        </TextField>
        <TextField select size="small" label="Designation" value={designation} onChange={changeFilter(setDesignation)} sx={{ minWidth: 170 }}>
          <MenuItem value="">All designations</MenuItem>{(options.designations.data ?? []).map((item) => <MenuItem key={item.id} value={String(item.id)}>{item.name}</MenuItem>)}
        </TextField>
        <TextField select size="small" label="Status" value={status} onChange={changeFilter(setStatus)} sx={{ minWidth: 150 }}>
          <MenuItem value="all">All employees</MenuItem><MenuItem value="current">Assigned</MenuItem><MenuItem value="unassigned">Unassigned</MenuItem><MenuItem value="future">Future assignment</MenuItem><MenuItem value="expired">Previous assignment</MenuItem>
        </TextField>
      </Stack>
      {canAssign && selected.length ? (
        <Stack direction="row" alignItems="center" spacing={1} sx={{ px: 2, pb: 1.5 }}>
          <Typography variant="body2" fontWeight={600}>{selected.length} employee{selected.length === 1 ? '' : 's'} selected</Typography>
          {mixedBranchSelection ? <Alert severity="warning" sx={{ py: 0 }}>Choose employees from one branch.</Alert> : null}
          <Button size="small" disabled={mixedBranchSelection} onClick={() => setDialogOpen(true)}>Assign Shift</Button>
          <Button size="small" onClick={resetSelection}>Clear selection</Button>
        </Stack>
      ) : null}
      {isLoading ? <LinearProgress aria-label="Loading employees and shift assignments" /> : null}
      {currentError ? (
        <Box sx={{ p: 2 }}><ErrorState message={currentError} onRetry={retry} retrying={isLoading} /></Box>
      ) : filteredEmployees.length === 0 ? (
        <EmptyState compact title={normalizedSearch || status !== 'all' ? 'No employees match these filters' : 'No employees found'} description="Try changing the filters or clearing the search." />
      ) : (
        <TableContainer sx={{ overflowX: 'auto' }}>
          <Table size="small" sx={{ minWidth: 1000 }} aria-label="Employee shift assignments">
            <TableHead><TableRow sx={{ bgcolor: 'info.light' }}>
              {canAssign ? <TableCell padding="checkbox" sx={{ width: 48 }}>
                <Checkbox size="small" checked={allVisibleSelected} indeterminate={!allVisibleSelected && someVisibleSelected}
                  disabled={pageSelectable.length === 0} onChange={togglePageSelection} inputProps={{ 'aria-label': 'Select all employees on this page' }} />
              </TableCell> : null}
              {['Employee', 'Role / Designation', 'Branch', 'Current Shift', 'Effective Period', 'Week Off', 'Status', 'History'].map((label) => <TableCell key={label} sx={{ fontWeight: 700, whiteSpace: 'nowrap', color: 'primary.main' }}>{label}</TableCell>)}
            </TableRow></TableHead>
            <TableBody>
              {pageRows.map((employee) => {
                const assignment = assignmentByEmployee.get(employee.id) ?? {}
                const displayedAssignment = assignment.current ?? assignment.future ?? assignment.previous
                const currentShift = assignment.current ? shiftsById.get(assignment.current.shift.id) : null
                const selectedEmployee = selectedIds.has(employee.id)
                return (
                  <TableRow key={employee.id} hover selected={selectedEmployee}>
                    {canAssign ? <TableCell padding="checkbox">
                      <Checkbox size="small" checked={selectedEmployee} disabled={!employee.is_active || !employee.branch}
                        onChange={() => toggleEmployee(employee)} inputProps={{ 'aria-label': `Select ${employeeName(employee)}` }} />
                    </TableCell> : null}
                    <TableCell sx={{ minWidth: 180 }}>
                      <Typography variant="body2" fontWeight={700}>{employeeName(employee)}</Typography>
                      <Typography variant="caption" color="text.secondary">{employee.employee_code}</Typography>
                    </TableCell>
                    <TableCell sx={{ minWidth: 150 }}>{employee.designation ? designationsById.get(employee.designation) ?? '—' : '—'}</TableCell>
                    <TableCell>{branchesById.get(employee.branch) ?? '—'}</TableCell>
                    <TableCell sx={{ minWidth: 210 }}>
                      {currentShift ? <Stack spacing={0.25}><Typography variant="body2" fontWeight={600}>{assignment.current.shift.name}</Typography><Typography variant="caption" color="text.secondary">{scheduleText(currentShift)}</Typography></Stack>
                        : <Stack spacing={0.25}><Chip size="small" variant="outlined" label="Not Assigned" sx={{ width: 'fit-content' }} />{assignment.future ? <Typography variant="caption" color="text.secondary">Upcoming: {assignment.future.shift.name} · {assignment.future.effective_from}</Typography> : null}{assignment.previous && !assignment.future ? <Typography variant="caption" color="text.secondary">Previous: {assignment.previous.shift.name}</Typography> : null}</Stack>}
                    </TableCell>
                    <TableCell sx={{ whiteSpace: 'nowrap' }}>{displayedAssignment ? `${displayedAssignment.effective_from} — ${displayedAssignment.effective_to ?? 'No end date'}` : '—'}</TableCell>
                    <TableCell>{displayedAssignment?.week_off_days?.join(', ') || '—'}</TableCell>
                    <TableCell><StatusChip label={assignment.current ? 'Assigned' : 'Unassigned'} color={assignment.current ? 'success' : 'default'} /></TableCell>
                    <TableCell><Button size="small" startIcon={<History size={15} />} onClick={() => setHistoryEmployee({ id: employee.id, name: employeeName(employee), employee_code: employee.employee_code })}>History</Button></TableCell>
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
