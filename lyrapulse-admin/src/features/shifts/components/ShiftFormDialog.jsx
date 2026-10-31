import { useEffect, useMemo, useState } from 'react'
import {
  Alert, Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, FormControl, FormControlLabel,
  InputLabel, MenuItem, Select, Stack, Switch, TextField, Typography,
} from '@mui/material'
import { ShiftScheduleEditor, WEEKDAYS, emptyWeek } from './ShiftScheduleEditor'

const today = () => {
  const d = new Date()
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

const tomorrow = () => {
  const d = new Date()
  d.setDate(d.getDate() + 1)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

const asInputTime = (value) => value ? String(value).slice(0, 5) : null

function scheduleDays(source) {
  const values = new Map((source ?? []).map((item) => [item.weekday, item]))
  return WEEKDAYS.map(([weekday]) => {
    const item = values.get(weekday)
    return item ? {
      weekday,
      is_working: item.is_working,
      start_time: asInputTime(item.start_time),
      end_time: asInputTime(item.end_time),
      break_start_time: asInputTime(item.break_start_time),
      break_end_time: asInputTime(item.break_end_time),
      break_enabled: Boolean(item.break_start_time && item.break_end_time),
    } : emptyWeek().find((day) => day.weekday === weekday)
  })
}

const daySignature = (days) => JSON.stringify((days ?? []).map((day) => [
  day.weekday, Boolean(day.is_working), asInputTime(day.start_time), asInputTime(day.end_time),
  asInputTime(day.break_start_time), asInputTime(day.break_end_time),
]))

function validateForm(form, shift) {
  const errors = []
  if (!form.name.trim()) errors.push('Shift name is required.')
  if (!shift && !form.branch) errors.push('Select a branch.')
  const working = form.days.filter((day) => day.is_working)
  if (!working.length) errors.push('Enable at least one working day.')
  for (const day of working) {
    const label = WEEKDAYS.find(([key]) => key === day.weekday)?.[1]
    if (!day.start_time || !day.end_time) {
      errors.push(`${label}: start and end time are required.`)
      continue
    }
    if (day.end_time <= day.start_time) errors.push(`${label}: end time must be later than start time. Overnight shifts are not supported yet.`)
    const hasStart = Boolean(day.break_start_time)
    const hasEnd = Boolean(day.break_end_time)
    if (hasStart !== hasEnd) errors.push(`${label}: enter both break times or remove the break.`)
    if (hasStart && hasEnd && !(day.start_time < day.break_start_time && day.break_start_time < day.break_end_time && day.break_end_time < day.end_time)) {
      errors.push(`${label}: break must be inside shift timing and have positive duration.`)
    }
  }
  const prior = shift?.current_schedule?.days ?? []
  const changed = shift ? daySignature(form.days) !== daySignature(scheduleDays(prior)) : true
  if (changed && shift && form.schedule_effective_from <= today()) errors.push('Schedule changes must take effect after today to preserve history.')
  if (!form.schedule_effective_from) errors.push('Choose when the schedule becomes effective.')
  return errors
}

export function ShiftFormDialog({ open, onClose, shift, branches, onSave, saving, serverError }) {
  const [form, setForm] = useState({ name: '', branch: '', is_active: true, schedule_effective_from: today(), days: emptyWeek() })

  useEffect(() => {
    if (!open) return
    setForm({
      name: shift?.name ?? '',
      branch: String(shift?.branch_detail?.id ?? shift?.branch ?? ''),
      is_active: shift?.is_active ?? true,
      schedule_effective_from: shift ? tomorrow() : today(),
      days: scheduleDays(shift?.current_schedule?.days),
    })
  }, [open, shift])

  const errors = useMemo(() => validateForm(form, shift), [form, shift])
  const submit = (event) => {
    event.preventDefault()
    if (errors.length) return
    const payload = {
      name: form.name.trim(),
      is_active: form.is_active,
      schedule_effective_from: form.schedule_effective_from,
      days: form.days.map(({ break_enabled, ...day }) => ({
        ...day,
        start_time: day.is_working ? day.start_time : null,
        end_time: day.is_working ? day.end_time : null,
        break_start_time: day.is_working ? day.break_start_time : null,
        break_end_time: day.is_working ? day.break_end_time : null,
      })),
    }
    if (!shift) payload.branch = Number(form.branch)
    onSave(payload)
  }

  return (
    <Dialog open={open} onClose={saving ? undefined : onClose} fullWidth maxWidth="xl" scroll="paper">
      <Box component="form" onSubmit={submit}>
        <DialogTitle sx={{ pb: 1 }}>
          <Typography variant="h5" component="div" fontWeight={700}>{shift ? 'Edit Shift' : 'Create Shift'}</Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>Configure the weekly schedule employees will be assigned to.</Typography>
        </DialogTitle>
        <DialogContent dividers>
          <Stack spacing={2.5}>
            {serverError ? <Alert severity="error">{serverError}</Alert> : null}
            {errors.length ? <Alert severity="info">{errors[0]}</Alert> : null}
            <Box>
              <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 1.25 }}>Basic information</Typography>
              <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'minmax(220px, 0.8fr) minmax(260px, 1.5fr) auto' }, gap: 1.5, alignItems: 'center' }}>
                <FormControl size="small" fullWidth disabled={Boolean(shift)}>
                  <InputLabel id="shift-branch-label">Branch</InputLabel>
                  <Select labelId="shift-branch-label" label="Branch" value={form.branch} onChange={(e) => setForm((v) => ({ ...v, branch: e.target.value }))}>
                    {branches.map((branch) => <MenuItem key={branch.id} value={String(branch.id)}>{branch.name}</MenuItem>)}
                  </Select>
                </FormControl>
                <TextField label="Shift name" required fullWidth size="small" value={form.name} onChange={(e) => setForm((v) => ({ ...v, name: e.target.value }))} inputProps={{ maxLength: 120 }} />
                {shift ? <FormControlLabel sx={{ m: 0 }} control={<Switch checked={form.is_active} onChange={(e) => setForm((v) => ({ ...v, is_active: e.target.checked }))} />} label={form.is_active ? 'Active' : 'Inactive'} /> : null}
              </Box>
              {shift ? <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 0.75 }}>Branch cannot be changed after a shift is created.</Typography> : null}
            </Box>

            {shift ? (
              <Box>
                <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 1 }}>Schedule effective date</Typography>
                <TextField
                  type="date" size="small" label="Effective from" value={form.schedule_effective_from}
                  onChange={(e) => setForm((v) => ({ ...v, schedule_effective_from: e.target.value }))}
                  slotProps={{ inputLabel: { shrink: true }, htmlInput: { min: tomorrow() } }}
                  helperText="Schedule changes take effect prospectively. Existing schedule history is preserved."
                  sx={{ width: { xs: '100%', sm: 280 } }}
                />
              </Box>
            ) : null}

            <Box>
              <Typography variant="subtitle1" fontWeight={700} sx={{ mb: 1 }}>Weekly schedule</Typography>
              <ShiftScheduleEditor days={form.days} onChange={(days) => setForm((v) => ({ ...v, days }))} />
            </Box>
          </Stack>
        </DialogContent>
        <DialogActions sx={{ px: 3, py: 2 }}>
          <Button onClick={onClose} disabled={saving}>Cancel</Button>
          <Button type="submit" variant="contained" disabled={saving || errors.length > 0}>
            {saving ? 'Saving…' : 'Save Shift'}
          </Button>
        </DialogActions>
      </Box>
    </Dialog>
  )
}

