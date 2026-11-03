import { useEffect, useState } from 'react'
import { Alert, Autocomplete, Button, Checkbox, Dialog, DialogActions, DialogContent, DialogTitle, FormControl, InputLabel, ListItemText, MenuItem, Select, Stack, TextField, Typography } from '@mui/material'
import { useEmployeesForBranch, useShifts } from '../hooks/useShiftQueries'

const dateToday = () => { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}` }
const weekdays = [['SUNDAY', 'Sunday'], ['MONDAY', 'Monday'], ['TUESDAY', 'Tuesday'], ['WEDNESDAY', 'Wednesday'], ['THURSDAY', 'Thursday'], ['FRIDAY', 'Friday'], ['SATURDAY', 'Saturday']]

export function ShiftAssignmentDialog({ open, onClose, branches, shifts, selectedEmployees, onSave, saving, error }) {
  const [branch, setBranch] = useState('')
  const [employee, setEmployee] = useState(null)
  const [employeeIds, setEmployeeIds] = useState([])
  const [shiftId, setShiftId] = useState('')
  const [from, setFrom] = useState(dateToday())
  const [to, setTo] = useState('')
  const [weekOffDays, setWeekOffDays] = useState([])
  const employeesQuery = useEmployeesForBranch(branch, Boolean(branch))
  const branchShifts = useShifts({ branch: branch || undefined, status: 'active', page_size: 100 })
  const employees = employeesQuery.data ?? []
  const shiftOptions = branchShifts.data?.results ?? shifts ?? []
  const bulk = selectedEmployees.length > 0
  useEffect(() => {
    if (!open) return
    setBranch(String(selectedEmployees[0]?.branch ?? selectedEmployees[0]?.branch_id ?? ''))
    setEmployee(null); setEmployeeIds(selectedEmployees.map((item) => item.id)); setShiftId('')
    setFrom(dateToday()); setTo(''); setWeekOffDays([])
  }, [open, selectedEmployees])
  const selectedShift = shiftOptions.find((item) => String(item.id) === String(shiftId))
  const submit = () => onSave({ ...(bulk ? { employee_ids: employeeIds } : { employee_id: employee?.id }), shift_id: Number(shiftId), effective_from: from, effective_to: to || null, ...(weekOffDays.length ? { week_off_days: weekOffDays } : {}) })
  const invalid = !branch || !shiftId || !from || (to && to < from) || (!bulk && !employee) || (bulk && !employeeIds.length)
  return <Dialog open={open} onClose={saving ? undefined : onClose} fullWidth maxWidth="md">
    <DialogTitle>{bulk ? `Assign shift to ${employeeIds.length} employees` : 'Assign shift'}</DialogTitle>
    <DialogContent><Stack spacing={2} sx={{ pt: 1 }}>
      {error ? <Alert severity="error">{error}</Alert> : null}
      <FormControl size="small" fullWidth><InputLabel>Branch</InputLabel><Select label="Branch" value={branch} disabled={bulk} onChange={(e) => { setBranch(e.target.value); setEmployee(null); setEmployeeIds([]); setShiftId('') }}>
        {branches.map((item) => <MenuItem key={item.id} value={String(item.id)}>{item.name}</MenuItem>)}</Select></FormControl>
      {bulk ? <Typography variant="body2" color="text.secondary">{employeeIds.length} employee{employeeIds.length === 1 ? '' : 's'} selected</Typography> : <Autocomplete options={employees.filter((item) => item.is_active && item.branch)} value={employee} onChange={(_e, value) => setEmployee(value)} getOptionLabel={(item) => `${item.display_name || `${item.first_name ?? ''} ${item.last_name ?? ''}`.trim()} · ${item.employee_code}`} isOptionEqualToValue={(a,b) => a.id === b.id} renderInput={(params) => <TextField {...params} label="Employee" size="small" placeholder="Select employee" />} />}
      <FormControl size="small" fullWidth><InputLabel>Shift</InputLabel><Select label="Shift" value={shiftId} onChange={(e) => setShiftId(e.target.value)}>{shiftOptions.map((item) => <MenuItem key={item.id} value={String(item.id)}>{item.name}</MenuItem>)}</Select></FormControl>
      <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5}><TextField type="date" size="small" label="Effective from" value={from} onChange={(e) => setFrom(e.target.value)} slotProps={{ inputLabel: { shrink: true } }} fullWidth /><TextField type="date" size="small" label="Effective to (optional)" value={to} onChange={(e) => setTo(e.target.value)} slotProps={{ inputLabel: { shrink: true } }} fullWidth /></Stack>
      <FormControl size="small" fullWidth>
        <InputLabel id="assignment-week-off-label">Employee Week Off (optional)</InputLabel>
        <Select multiple labelId="assignment-week-off-label" label="Employee Week Off (optional)" value={weekOffDays} onChange={(event) => setWeekOffDays(event.target.value)} renderValue={(selected) => selected.length ? selected.map((day) => weekdays.find(([value]) => value === day)?.[1] ?? day).join(', ') : 'Not set'}>
          {weekdays.map(([value, label]) => <MenuItem key={value} value={value}><Checkbox size="small" checked={weekOffDays.includes(value)} /><ListItemText primary={label} /></MenuItem>)}
        </Select>
      </FormControl>
      {selectedShift ? <Typography variant="caption" color="text.secondary">The shift schedule must be in effect from the selected effective date. Reassigning closes an existing assignment the day before this date.</Typography> : null}
    </Stack></DialogContent>
    <DialogActions sx={{ p: 2 }}><Button onClick={onClose} disabled={saving}>Cancel</Button><Button variant="contained" onClick={submit} disabled={saving || invalid}>{saving ? 'Saving…' : 'Assign shift'}</Button></DialogActions>
  </Dialog>
}
