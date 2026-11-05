import { useState } from 'react'
import { Box, Button, CircularProgress, Stack, TextField, ToggleButton, ToggleButtonGroup } from '@mui/material'
import { Download } from 'lucide-react'
import { MAX_RANGE_DAYS, PERIODS, addDays, todayIso, validateCustomRange } from '../utils/dateRange'

const toggleSx = {
  bgcolor: 'background.paper',
  '& .MuiToggleButton-root': {
    px: 1.75, py: 0.6, textTransform: 'none', fontWeight: 600, color: 'text.secondary', borderColor: 'divider',
    '&.Mui-selected': { color: 'primary.light', bgcolor: 'action.selected', '&:hover': { bgcolor: 'action.selected' } },
  },
}

export function AttendancePeriodControls({ range, onPeriodChange, onCustomRange, onExport, exporting }) {
  const [draft, setDraft] = useState({ start: range.start, end: range.end })
  const today = todayIso()
  const error = range.period === 'custom' ? validateCustomRange(draft.start, draft.end) : ''

  const updateDraft = (patch) => {
    const next = { ...draft, ...patch }
    setDraft(next)
    if (!validateCustomRange(next.start, next.end)) onCustomRange(next.start, next.end)
  }

  const selectPeriod = (_event, value) => {
    if (!value) return
    if (value === 'custom') setDraft({ start: range.start, end: range.end })
    onPeriodChange(value)
  }

  return (
    <Stack sx={{ alignItems: { xs: 'stretch', md: 'flex-end' }, gap: 1 }}>
      <Stack direction="row" sx={{ gap: 1.5, flexWrap: 'wrap', alignItems: 'center' }}>
        <ToggleButtonGroup exclusive size="small" value={range.period} onChange={selectPeriod} aria-label="Attendance period" sx={toggleSx}>
          {PERIODS.map((period) => (
            <ToggleButton key={period.id} value={period.id}>{period.label}</ToggleButton>
          ))}
        </ToggleButtonGroup>
        <Button
          variant="contained"
          onClick={onExport}
          disabled={exporting}
          startIcon={exporting ? <CircularProgress size={16} color="inherit" /> : <Download size={16} aria-hidden="true" />}
        >
          {exporting ? 'Exporting…' : 'Export Report'}
        </Button>
      </Stack>

      {range.period === 'custom' ? (
        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', alignItems: 'flex-start' }}>
          <TextField
            type="date" size="small" label="From" value={draft.start}
            onChange={(event) => updateDraft({ start: event.target.value })}
            error={Boolean(error)}
            slotProps={{ inputLabel: { shrink: true }, htmlInput: { max: draft.end && draft.end < today ? draft.end : today, min: draft.end ? addDays(draft.end, -(MAX_RANGE_DAYS - 1)) : undefined } }}
          />
          <TextField
            type="date" size="small" label="To" value={draft.end}
            onChange={(event) => updateDraft({ end: event.target.value })}
            error={Boolean(error)}
            helperText={error || `Up to ${MAX_RANGE_DAYS} days, no future dates`}
            slotProps={{ inputLabel: { shrink: true }, htmlInput: { max: today, min: draft.start || undefined } }}
          />
        </Box>
      ) : null}
    </Stack>
  )
}
