import { useMemo, useState } from 'react'
import { Box, Button, Drawer, IconButton, Stack, Switch, Typography } from '@mui/material'
import { X } from 'lucide-react'
import { SearchInput } from '../../../components/common/SearchInput'
import { COLUMNS, REQUIRED_COLUMN_IDS, normalizeVisibleIds } from '../employeeColumns'

const sameSet = (a, b) => a.length === b.length && a.every((id) => b.includes(id))

// Draft state lives here and is discarded when the panel closes; only Save calls onSave.
function Panel({ visibleIds, defaultIds, onSave, onClose }) {
  const [draft, setDraft] = useState(visibleIds)
  const [query, setQuery] = useState('')

  const shown = useMemo(() => COLUMNS.filter((column) => column.label.toLowerCase().includes(query.trim().toLowerCase())), [query])
  const dirty = !sameSet(draft, visibleIds)
  const atDefault = sameSet(draft, defaultIds)

  const toggle = (id) => setDraft((current) => normalizeVisibleIds(current.includes(id) ? current.filter((item) => item !== id) : [...current, id]))

  return (
    <Box role="dialog" aria-label="Edit columns" sx={{ width: { xs: '100vw', sm: 400 }, maxWidth: '100vw', height: '100%', display: 'flex', flexDirection: 'column' }}>
      <Stack direction="row" sx={{ alignItems: 'center', justifyContent: 'space-between', px: 2.5, py: 1.5, bgcolor: 'info.light', borderBottom: '1px solid', borderColor: 'divider' }}>
        <Box>
          <Typography variant="h6" component="h2">Edit columns</Typography>
          <Typography variant="caption" color="text.secondary">{draft.length} of {COLUMNS.length} columns visible</Typography>
        </Box>
        <IconButton onClick={onClose} aria-label="Close without saving"><X size={18} aria-hidden="true" /></IconButton>
      </Stack>

      <Box sx={{ px: 2.5, py: 1.5 }}>
        <SearchInput value={query} onChange={setQuery} label="Search columns" placeholder="Search columns" />
      </Box>

      <Box component="ul" sx={{ listStyle: 'none', m: 0, p: 0, flex: 1, overflowY: 'auto', borderTop: '1px solid', borderColor: 'divider' }}>
        {shown.length === 0 ? <Typography variant="body2" color="text.secondary" sx={{ p: 2.5 }}>No columns match “{query}”.</Typography> : null}
        {shown.map((column) => {
          const locked = REQUIRED_COLUMN_IDS.includes(column.id)
          return (
            <Box component="li" key={column.id} sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', px: 2.5, minHeight: 44, borderBottom: '1px solid', borderColor: 'divider', '&:hover': { bgcolor: 'action.hover' } }}>
              <Box sx={{ minWidth: 0 }}>
                <Typography variant="body2" sx={{ color: locked ? 'text.secondary' : 'text.primary' }}>{column.label}</Typography>
                {locked ? <Typography variant="caption" color="text.secondary">Always shown</Typography> : null}
              </Box>
              <Switch checked={draft.includes(column.id)} disabled={locked} onChange={() => toggle(column.id)} slotProps={{ input: { 'aria-label': `Show ${column.label} column` } }} />
            </Box>
          )
        })}
      </Box>

      <Stack direction="row" sx={{ justifyContent: 'space-between', gap: 1, px: 2.5, py: 1.5, bgcolor: 'info.light', borderTop: '1px solid', borderColor: 'divider' }}>
        <Button variant="outlined" onClick={() => setDraft(defaultIds)} disabled={atDefault}>Reset to default</Button>
        <Stack direction="row" sx={{ gap: 1 }}>
          <Button onClick={onClose}>Cancel</Button>
          <Button variant="contained" onClick={() => onSave(draft)} disabled={!dirty}>Save</Button>
        </Stack>
      </Stack>
    </Box>
  )
}

export function EditColumnsDrawer({ open, onClose, ...panelProps }) {
  return (
    // The shared MUI Drawer theme is the navy sidebar style, so this content panel opts back into the surface colors.
    <Drawer anchor="right" open={open} onClose={onClose} slotProps={{ paper: { sx: { bgcolor: 'background.paper', color: 'text.primary' } } }}>
      <Panel {...panelProps} onClose={onClose} />
    </Drawer>
  )
}