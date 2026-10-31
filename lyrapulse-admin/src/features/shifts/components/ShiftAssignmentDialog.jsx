import { useEffect, useMemo, useState } from 'react'
import { Alert, Autocomplete, Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, FormControl, InputLabel, MenuItem, Select, Stack, TextField, Typography } from '@mui/material'
import { WEEKDAYS } from './ShiftScheduleEditor'
import { useEmployeesForBranch, useShifts } from '../hooks/useShiftQueries'

const dateToday = () => { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}` }

export function ShiftAssignmentDialog({ open, onClose, branches, shifts, selectedEmployees, onSave, saving, error }) {
  const [branch, setBranch] = useState('')
  const [employee, setEmployee] = useState(null)
  const [employeeIds, setEmployeeIds] = useState([])
  const [shiftId, setShiftId] = useState('')
  const [from, setFrom] = useState(dateToday())
  const [to, setTo] = useState('')
  const [weekOff, setWeekOff] = useState(['SUNDAY'])
  const employeesQuery = useEmployeesForBranch(branch)
  const branchShifts = useShifts({ branch: branch || undefined, status: 'active', page_size: 100 })
  const employees = employeesQuery.data ?? []
  const shiftOptions = branchShifts.data?.results ?? shifts ?? []
  const bulk = selectedEmployees.length > 0
  useEffect(() => {
    if (!open) return
    setBranch(String(selectedEmployees[0]?.branch_id ?? ''))
    setEmployee(null); setEmployeeIds(selectedEmployees.map((item) => item.id)); setShiftId('')
    setFrom(dateToday()); setTo(''); setWeekOff(['SUNDAY'])
  }, [open, selectedEmployees])
  const selectedShift = useMemo(() => shiftOptions.find((item) => String(item.id) === String(shiftId)), [shiftOptions, shiftId])
  const submit = () => onSave({ ...(bulk ? { employee_ids: employeeIds } : { employee_id: employee?.id }), shift_id: Number(shiftId), effective_from: from, effective_to: to || null, week_off_days: weekOff })
  const invalid = !branch || !shiftId || !from || (to && to < from) || (!bulk && !employee) || (bulk && !employeeIds.length) || weekOff.length === 0
  return <Dialog open={open} onClose={saving ? undefined : onClose} fullWidth maxWidth="sm">
    <DialogTitle>{bulk ? `Assign shift to ${employeeIds.length} employees` : 'Assign shift'}</DialogTitle>
    <DialogContent><Stack spacing={2} sx={{ pt: 1 }}>
      {error ? <Alert severity="error">{error}</Alert> : null}
      <FormControl size="small" fullWidth><InputLabel>Branch</InputLabel><Select label="Branch" value={branch} onChange={(e) => { setBranch(e.target.value); setEmployee(null); setEmployeeIds([]); setShiftId('') }}>
        {branches.map((item) => <MenuItem key={item.id} value={String(item.id)}>{item.name}</MenuItem>)}</Select></FormControl>
      {bulk ? <Typography variant="body2" color="text.secondary">Selected employees: {selectedEmployees.map((item) => item.name).join(', ')}</Typography> : <Autocomplete options={employees} value={employee} onChange={(_e, value) => setEmployee(value)} getOptionLabel={(item) => `${item.display_name || `${item.first_name ?? ''} ${item.last_name ?? ''}`.trim()} · ${item.employee_code}`} isOptionEqualToValue={(a,b) => a.id === b.id} renderInput={(params) => <TextField {...params} label="Employee" size="small" placeholder="Select employee" />} />}
      <FormControl size="small" fullWidth><InputLabel>Shift</InputLabel><Select label="Shift" value={shiftId} onChange={(e) => setShiftId(e.target.value)}>{shiftOptions.map((item) => <MenuItem key={item.id} value={String(item.id)}>{item.name}</MenuItem>)}</Select></FormControl>
      <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5}><TextField type="date" size="small" label="Effective from" value={from} onChange={(e) => setFrom(e.target.value)} slotProps={{ inputLabel: { shrink: true } }} fullWidth /><TextField type="date" size="small" label="Effective to (optional)" value={to} onChange={(e) => setTo(e.target.value)} slotProps={{ inputLabel: { shrink: true } }} fullWidth /></Stack>
      <BoxWeekOff weekOff={weekOff} onChange={setWeekOff} />
      {selectedShift ? <Typography variant="caption" color="text.secondary">The shift schedule must be in effect from the selected effective date. Reassigning closes an existing assignment the day before this date.</Typography> : null}
    </Stack></DialogContent>
    <DialogActions sx={{ p: 2 }}><Button onClick={onClose} disabled={saving}>Cancel</Button><Button variant="contained" onClick={submit} disabled={saving || invalid}>{saving ? 'Saving…' : 'Assign shift'}</Button></DialogActions>
  </Dialog>
}

function BoxWeekOff({ weekOff, onChange }) {
  return <Stack><Typography variant="subtitle2" fontWeight={700}>Employee week off days</Typography><Stack direction="row" flexWrap="wrap">{WEEKDAYS.map(([key, label]) => <Button key={key} size="small" variant={weekOff.includes(key) ? 'contained' : 'outlined'} onClick={() => onChange(weekOff.includes(key) ? weekOff.filter((v) => v !== key) : [...weekOff, key])} sx={{ m: 0.35 }}>{label}</Button>)}</Stack></Stack>
}
