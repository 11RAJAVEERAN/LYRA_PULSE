import { useMemo, useState } from 'react'
import {
  Alert, Box, Button, FormControlLabel, Paper, Stack, Switch, Table, TableBody, TableCell, TableContainer,
  TableHead, TableRow, TextField, Typography,
} from '@mui/material'
import { Clipboard, ClipboardPaste, Coffee, WandSparkles } from 'lucide-react'

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

export function ShiftScheduleEditor({ days, onChange, errors = {} }) {
  const [common, setCommon] = useState({ start_time: '', end_time: '', has_break: false, break_start_time: '', break_end_time: '' })
  const [copied, setCopied] = useState(null)
  const workingCount = days.filter((day) => day.is_working).length
  const weeklySeconds = useMemo(() => days.reduce((sum, day) => sum + (scheduledSeconds(day) ?? 0), 0), [days])

  const applyCommon = () => {
    if (!common.start_time || !common.end_time || !workingCount) return
    onChange(days.map((day) => day.is_working ? {
      ...day,
      start_time: common.start_time,
      end_time: common.end_time,
      break_start_time: common.has_break ? common.break_start_time || null : null,
      break_end_time: common.has_break ? common.break_end_time || null : null,
      break_enabled: common.has_break,
    } : day))
  }

  const toggleWorking = (day, enabled) => onChange(updateDay(days, day.weekday, enabled
    ? { is_working: true }
    : { is_working: false, start_time: null, end_time: null, break_start_time: null, break_end_time: null, break_enabled: false }))

  const toggleBreak = (day, enabled) => onChange(updateDay(days, day.weekday, enabled
    ? { break_enabled: true }
    : { break_enabled: false, break_start_time: null, break_end_time: null }))

  const timeField = (day, key, label, disabled = false) => (
    <TextField
      type="time" size="small" value={day[key] ?? ''} disabled={disabled}
      onChange={(event) => onChange(updateDay(days, day.weekday, { [key]: event.target.value || null }))}
      label={label} slotProps={{ inputLabel: { shrink: true }, htmlInput: { step: 300, 'aria-label': `${label} ${day.weekday.toLowerCase()}` } }}
      sx={{ width: { xs: 142, sm: 150 }, '& .MuiInputBase-input': { fontVariantNumeric: 'tabular-nums' } }}
    />
  )

  return (
    <Stack spacing={2}>
      <Paper variant="outlined" sx={{ p: { xs: 1.5, sm: 2 }, bgcolor: 'info.light' }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2} alignItems={{ md: 'center' }} justifyContent="space-between">
          <Box>
            <Typography variant="subtitle1" fontWeight={700}>Common shift timing</Typography>
            <Typography variant="body2" color="text.secondary">Set one schedule and apply it to the working days below.</Typography>
          </Box>
          <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
            <TextField type="time" size="small" label="Start time" value={common.start_time} onChange={(e) => setCommon((v) => ({ ...v, start_time: e.target.value }))} slotProps={{ inputLabel: { shrink: true }, htmlInput: { step: 300 } }} sx={{ width: 150, bgcolor: 'background.paper' }} />
            <TextField type="time" size="small" label="End time" value={common.end_time} onChange={(e) => setCommon((v) => ({ ...v, end_time: e.target.value }))} slotProps={{ inputLabel: { shrink: true }, htmlInput: { step: 300 } }} sx={{ width: 150, bgcolor: 'background.paper' }} />
            <FormControlLabel
              sx={{ mx: 0, px: 1, borderRadius: 1, bgcolor: 'background.paper' }}
              control={<Switch size="small" checked={common.has_break} onChange={(e) => setCommon((v) => ({ ...v, has_break: e.target.checked }))} />}
              label={<Typography variant="body2"><Coffee size={14} style={{ verticalAlign: 'middle', marginRight: 5 }} />Add break</Typography>}
            />
          </Stack>
        </Stack>
        {common.has_break ? (
          <Stack direction="row" spacing={1} sx={{ mt: 1.5 }}>
            <TextField type="time" size="small" label="Break start" value={common.break_start_time} onChange={(e) => setCommon((v) => ({ ...v, break_start_time: e.target.value }))} slotProps={{ inputLabel: { shrink: true }, htmlInput: { step: 300 } }} sx={{ width: 150, bgcolor: 'background.paper' }} />
            <TextField type="time" size="small" label="Break end" value={common.break_end_time} onChange={(e) => setCommon((v) => ({ ...v, break_end_time: e.target.value }))} slotProps={{ inputLabel: { shrink: true }, htmlInput: { step: 300 } }} sx={{ width: 150, bgcolor: 'background.paper' }} />
          </Stack>
        ) : null}
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} alignItems={{ sm: 'center' }} sx={{ mt: 1.5 }}>
          <Button size="small" variant="contained" startIcon={<WandSparkles size={16} />} disabled={!common.start_time || !common.end_time || workingCount === 0} onClick={applyCommon}>
            Apply to working days
          </Button>
          <Typography variant="caption" color="text.secondary">
            {workingCount ? `Updates ${workingCount} enabled ${workingCount === 1 ? 'day' : 'days'}.` : 'Enable working days below first.'}
          </Typography>
        </Stack>
      </Paper>

      {errors.days ? <Alert severity="error">{errors.days}</Alert> : null}
      <TableContainer component={Paper} variant="outlined" sx={{ maxWidth: '100%', overflowX: 'auto' }}>
        <Table size="small" sx={{ minWidth: 910 }} aria-label="Weekly shift schedule">
          <TableHead>
            <TableRow sx={{ bgcolor: 'info.light' }}>
              <TableCell sx={{ fontWeight: 700 }}>Day</TableCell>
              <TableCell sx={{ fontWeight: 700 }}>Working</TableCell>
              <TableCell sx={{ fontWeight: 700 }}>Shift timing</TableCell>
              <TableCell sx={{ fontWeight: 700 }}>Break</TableCell>
              <TableCell sx={{ fontWeight: 700 }}>Scheduled hours</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700 }}>Action</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {days.map((day) => (
              <TableRow key={day.weekday} sx={{ '&:last-child td': { borderBottom: 0 } }}>
                <TableCell sx={{ minWidth: 108, fontWeight: 600 }}>{WEEKDAYS.find(([key]) => key === day.weekday)?.[1]}</TableCell>
                <TableCell sx={{ minWidth: 115 }}>
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
                <TableCell sx={{ minWidth: 210 }}>
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
                  ) : <Typography variant="body2" color="text.secondary">—</Typography>}
                </TableCell>
                <TableCell sx={{ whiteSpace: 'nowrap', fontWeight: 600 }}>{formatDuration(scheduledSeconds(day))}</TableCell>
                <TableCell align="right" sx={{ whiteSpace: 'nowrap' }}>
                  {copied?.weekday === day.weekday ? (
                    <Button size="small" disabled>Copied</Button>
                  ) : copied ? (
                    <Button size="small" startIcon={<ClipboardPaste size={15} />} onClick={() => { onChange(updateDay(days, day.weekday, { ...copied, weekday: day.weekday })); setCopied(null) }}>Paste</Button>
                  ) : (
                    <Button size="small" startIcon={<Clipboard size={15} />} disabled={!day.is_working} onClick={() => setCopied({
                      weekday: day.weekday, is_working: day.is_working, start_time: day.start_time, end_time: day.end_time,
                      break_start_time: day.break_start_time, break_end_time: day.break_end_time,
                      break_enabled: day.break_enabled ?? Boolean(day.break_start_time && day.break_end_time),
                    })}>Copy</Button>
                  )}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
      <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" spacing={0.5}>
        <Typography variant="body2" color="text.secondary">Scheduled hours are planned shift time minus the planned break. Attendance hours remain separate.</Typography>
        <Typography variant="body2" fontWeight={700}>Weekly total: {formatDuration(weeklySeconds)}</Typography>
      </Stack>
    </Stack>
  )
}

