import { useState } from 'react'
import {
  Alert, Button, FormControl, FormControlLabel, MenuItem, Paper, Select, Stack,
  Switch, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Typography,
} from '@mui/material'

export const WEEKDAYS = [
  ['SUNDAY', 'Sunday'], ['MONDAY', 'Monday'], ['TUESDAY', 'Tuesday'], ['WEDNESDAY', 'Wednesday'],
  ['THURSDAY', 'Thursday'], ['FRIDAY', 'Friday'], ['SATURDAY', 'Saturday'],
]

export const emptyDay = (weekday) => ({
  weekday, is_working: false, start_time: null, end_time: null, break_start_time: null, break_end_time: null, break_enabled: false,
})

export const emptyWeek = () => WEEKDAYS.map(([weekday]) => emptyDay(weekday))

const minutes = (value) => {
  if (!value) return null
  const [hour, minute] = value.slice(0, 5).split(':').map(Number)
  return hour * 60 + minute
}

export function scheduledSeconds(day) {
  if (!day?.is_working) return null
  const start = minutes(day.start_time)
  const end = minutes(day.end_time)
  if (start == null || end == null || end <= start) return null
  const breakStart = minutes(day.break_start_time)
  const breakEnd = minutes(day.break_end_time)
  return (end - start - (breakStart != null && breakEnd != null ? breakEnd - breakStart : 0)) * 60
}

export function formatDuration(seconds) {
  if (seconds == null) return '—'
  const hours = Math.floor(seconds / 3600)
  const mins = Math.floor((seconds % 3600) / 60)
  if (!mins) return `${hours}h`
  if (!hours) return `${mins}m`
  return `${hours}h ${mins}m`
}

function updateDay(days, weekday, patch) {
  return days.map((day) => day.weekday === weekday ? { ...day, ...patch } : day)
}

function timeParts(value) {
  if (!value) return { hour: '', minute: '', period: '' }
  const [hour24, minute] = value.slice(0, 5).split(':').map(Number)
  return {
    hour: String((hour24 % 12) || 12).padStart(2, '0'),
    minute: String(minute).padStart(2, '0'),
    period: hour24 >= 12 ? 'PM' : 'AM',
  }
}

function timeValue(parts) {
  if (!parts.hour || !parts.minute || !parts.period) return null
  const hour = Number(parts.hour) % 12 + (parts.period === 'PM' ? 12 : 0)
  return `${String(hour).padStart(2, '0')}:${parts.minute}`
}

export function formatTimeAmPm(value) {
  if (!value) return ''
  const parts = timeParts(value)
  return `${parts.hour}:${parts.minute} ${parts.period}`
}

export function formatScheduleSummary(value) {
  return value?.replace(/\b([01]\d|2[0-3]):([0-5]\d)\b/g, (_match, hour, minute) =>
    formatTimeAmPm(`${hour}:${minute}`)) ?? value
}

function isValidCommonTiming(common) {
  if (!common.start_time || !common.end_time || common.end_time <= common.start_time) return false
  if (!common.has_break) return true
  return Boolean(common.break_start_time && common.break_end_time
    && common.start_time < common.break_start_time
    && common.break_start_time < common.break_end_time
    && common.break_end_time < common.end_time)
}

function TimePicker({ value, onChange, label, disabled = false }) {
  const parts = timeParts(value)
  const changePart = (key, nextValue) => {
    const changed = { ...parts, [key]: nextValue }
    const complete = {
      hour: changed.hour || '12',
      minute: changed.minute || '00',
      period: changed.period || 'AM',
    }
    onChange(timeValue(complete))
  }
  const selectSx = {
    height: 36, fontSize: '0.8125rem',
    '& .MuiSelect-select': { px: 0.75, py: 0.75, minHeight: 'unset', display: 'flex', alignItems: 'center' },
    '& .MuiOutlinedInput-notchedOutline': { border: 0 },
  }
  return (
    <Stack direction="row" spacing={0} alignItems="center" role="group" aria-label={label}
      sx={{ width: 'fit-content', height: 40, border: 1, borderColor: 'divider', borderRadius: 1, overflow: 'hidden', bgcolor: disabled ? 'action.disabledBackground' : 'background.paper', '&:focus-within': { borderColor: 'primary.main', boxShadow: (theme) => `0 0 0 1px ${theme.palette.primary.main}` } }}>
      <FormControl size="small" sx={{ width: 58, flexShrink: 0 }}>
        <Select value={parts.hour} displayEmpty disabled={disabled} onChange={(event) => changePart('hour', event.target.value)} inputProps={{ 'aria-label': `${label} hour` }} sx={selectSx}>
          <MenuItem value="" disabled>HH</MenuItem>
          {Array.from({ length: 12 }, (_, index) => String(index + 1).padStart(2, '0')).map((hour) => <MenuItem key={hour} value={hour}>{hour}</MenuItem>)}
        </Select>
      </FormControl>
      <Typography color="text.secondary" sx={{ px: 0.25 }}>:</Typography>
      <FormControl size="small" sx={{ width: 58, flexShrink: 0 }}>
        <Select value={parts.minute} displayEmpty disabled={disabled} onChange={(event) => changePart('minute', event.target.value)} inputProps={{ 'aria-label': `${label} minute` }} sx={selectSx}>
          <MenuItem value="" disabled>MM</MenuItem>
          {Array.from({ length: 60 }, (_, index) => String(index).padStart(2, '0')).map((minute) => <MenuItem key={minute} value={minute}>{minute}</MenuItem>)}
        </Select>
      </FormControl>
      <FormControl size="small" sx={{ width: 84, flexShrink: 0, borderLeft: 1, borderColor: 'divider' }}>
        <Select value={parts.period} displayEmpty disabled={disabled} onChange={(event) => changePart('period', event.target.value)} inputProps={{ 'aria-label': `${label} AM or PM` }} sx={selectSx}>
          <MenuItem value="" disabled>AM/PM</MenuItem>
          <MenuItem value="AM">AM</MenuItem>
          <MenuItem value="PM">PM</MenuItem>
        </Select>
      </FormControl>
    </Stack>
  )
}

export function ShiftScheduleEditor({ days, onChange, errors = {} }) {
  const [common, setCommon] = useState({ start_time: '', end_time: '', has_break: false, break_start_time: '', break_end_time: '' })
  const workingCount = days.filter((day) => day.is_working).length
  const commonTimingValid = isValidCommonTiming(common)

  const applyCommon = () => {
    if (!commonTimingValid || !workingCount) return
    onChange(days.map((day) => day.is_working ? {
      ...day,
      start_time: common.start_time,
      end_time: common.end_time,
      break_start_time: common.has_break ? common.break_start_time || null : null,
      break_end_time: common.has_break ? common.break_end_time || null : null,
      break_enabled: common.has_break,
    } : day))
  }

  const toggleWorking = (day, enabled) => onChange(updateDay(days, day.weekday, { is_working: enabled }))

  const toggleBreak = (day, enabled) => onChange(updateDay(days, day.weekday, enabled
    ? { break_enabled: true }
    : { break_enabled: false, break_start_time: null, break_end_time: null }))

  const timeField = (day, key, label, disabled = false) => (
    <Stack spacing={0.25}>
      <Typography variant="caption" color="text.secondary">{label}</Typography>
      <TimePicker value={day[key]} disabled={disabled} label={`${label} ${day.weekday.toLowerCase()}`} onChange={(value) => onChange(updateDay(days, day.weekday, { [key]: value }))} />
    </Stack>
  )

  return (
    <Stack spacing={2}>
      <Paper variant="outlined" sx={{ p: { xs: 1.5, sm: 2 } }}>
        <Stack spacing={1.5}>
          <Typography variant="subtitle1" fontWeight={700}>Common shift timing</Typography>
          <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems={{ md: 'flex-end' }}>
            <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5}>
              <Stack spacing={0.5}>
                <Typography variant="body2" fontWeight={600}>Start Time</Typography>
                <TimePicker label="Common start time" value={common.start_time} onChange={(value) => setCommon((v) => ({ ...v, start_time: value ?? '' }))} />
              </Stack>
              <Stack spacing={0.5}>
                <Typography variant="body2" fontWeight={600}>End Time</Typography>
                <TimePicker label="Common end time" value={common.end_time} onChange={(value) => setCommon((v) => ({ ...v, end_time: value ?? '' }))} />
              </Stack>
            </Stack>
            <FormControlLabel
              sx={{ m: 0, minHeight: 40, px: 1, border: 1, borderColor: 'divider', borderRadius: 1, alignSelf: { xs: 'flex-start', md: 'flex-end' } }}
              control={<Switch size="small" checked={common.has_break} onChange={(e) => setCommon((v) => ({ ...v, has_break: e.target.checked }))} />}
              label={<Typography variant="body2">Add break</Typography>}
            />
          </Stack>

          {common.has_break ? (
            <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} sx={{ pt: 1.5, borderTop: 1, borderColor: 'divider' }}>
              <Stack spacing={0.4}>
                <Typography variant="caption" color="text.secondary">Break start</Typography>
                <TimePicker label="Common break start" value={common.break_start_time} onChange={(value) => setCommon((v) => ({ ...v, break_start_time: value ?? '' }))} />
              </Stack>
              <Stack spacing={0.4}>
                <Typography variant="caption" color="text.secondary">Break end</Typography>
                <TimePicker label="Common break end" value={common.break_end_time} onChange={(value) => setCommon((v) => ({ ...v, break_end_time: value ?? '' }))} />
              </Stack>
            </Stack>
          ) : null}

          <Stack direction="row">
            <Button size="small" variant="outlined"
              disabled={!commonTimingValid || workingCount === 0} onClick={applyCommon}>
              Apply to {workingCount} working {workingCount === 1 ? 'day' : 'days'}
            </Button>
          </Stack>
        </Stack>
      </Paper>

      {errors.days ? <Alert severity="error">{errors.days}</Alert> : null}
      <TableContainer component={Paper} variant="outlined" sx={{ maxWidth: '100%', overflowX: 'auto' }}>
        <Table size="small" sx={{ minWidth: 1040 }} aria-label="Weekly shift schedule">
          <TableHead>
            <TableRow sx={{ bgcolor: 'info.light' }}>
              <TableCell sx={{ fontWeight: 700 }}>Day</TableCell>
              <TableCell sx={{ fontWeight: 700 }}>Working</TableCell>
              <TableCell sx={{ fontWeight: 700 }}>Shift timing</TableCell>
              <TableCell sx={{ fontWeight: 700 }}>Break</TableCell>
              <TableCell sx={{ fontWeight: 700 }}>Scheduled hours</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {days.map((day) => (
              <TableRow key={day.weekday} sx={{ height: 58, opacity: day.is_working ? 1 : 0.72, '&:last-child td': { borderBottom: 0 } }}>
                <TableCell sx={{ minWidth: 96, fontWeight: 600 }}>{WEEKDAYS.find(([key]) => key === day.weekday)?.[1]}</TableCell>
                <TableCell sx={{ minWidth: 88 }}>
                  <FormControlLabel
                    sx={{ m: 0 }}
                    control={<Switch size="small" checked={day.is_working} onChange={(e) => toggleWorking(day, e.target.checked)} inputProps={{ 'aria-label': `${day.weekday} is a working day` }} />}
                    label={<Typography variant="caption" color={day.is_working ? 'success.main' : 'text.secondary'}>{day.is_working ? 'On' : 'Off'}</Typography>}
                  />
                </TableCell>
                <TableCell>
                  {day.is_working ? (
                    <Stack direction="row" spacing={0.75} alignItems="center">
                      {timeField(day, 'start_time', 'Start')}
                      <Typography color="text.secondary">→</Typography>
                      {timeField(day, 'end_time', 'End')}
                    </Stack>
                  ) : <Typography variant="body2" color="text.secondary">Not scheduled</Typography>}
                </TableCell>
                <TableCell sx={{ minWidth: 350 }}>
                  {day.is_working ? (
                    <Stack spacing={0.5}>
                      <FormControlLabel
                        sx={{ m: 0 }}
                        control={<Switch size="small" checked={day.break_enabled ?? Boolean(day.break_start_time && day.break_end_time)} onChange={(e) => toggleBreak(day, e.target.checked)} inputProps={{ 'aria-label': `Break on ${day.weekday}` }} />}
                        label={<Typography variant="caption">{day.break_enabled ?? Boolean(day.break_start_time && day.break_end_time) ? 'Break added' : 'No break'}</Typography>}
                      />
                      {(day.break_enabled ?? Boolean(day.break_start_time && day.break_end_time)) ? <Stack direction="row" spacing={0.75}>
                        {timeField(day, 'break_start_time', 'Break start')}
                        {timeField(day, 'break_end_time', 'Break end')}
                      </Stack> : null}
                    </Stack>
                  ) : <Typography variant="body2" color="text.secondary">No break</Typography>}
                </TableCell>
                <TableCell sx={{ whiteSpace: 'nowrap', fontWeight: 600 }}>{formatDuration(scheduledSeconds(day))}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Stack>
  )
}

