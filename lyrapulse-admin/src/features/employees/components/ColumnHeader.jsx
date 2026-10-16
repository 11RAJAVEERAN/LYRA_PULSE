import { useMemo, useState } from 'react'
import { Box, Button, Checkbox, FormControlLabel, IconButton, Popover, Stack, TableCell, TextField, Typography } from '@mui/material'
import { ArrowDown, ArrowUp, ArrowUpDown, Funnel } from 'lucide-react'
import { SearchInput } from '../../../components/common/SearchInput'
import { isFilterActive } from '../employeeColumns'

// Shared by every header cell (including the static Actions column) so the header row reads as one band.
export const headCellSx = {
  whiteSpace: 'nowrap',
  py: 1,
  px: 1.5,
  bgcolor: 'info.light',
  color: 'primary.main',
  fontSize: '0.8125rem',
  fontWeight: 650,
  letterSpacing: 0,
  textTransform: 'none',
  borderBottom: '1px solid',
  borderColor: 'divider',
}

const iconButtonSx = (active) => ({
  p: 0.5,
  color: active ? 'secondary.main' : 'text.secondary',
  bgcolor: active ? 'secondary.light' : 'transparent',
  '&:hover': { bgcolor: active ? 'secondary.light' : 'action.hover', color: active ? 'secondary.main' : 'text.primary' },
})

const popoverPaperSx = { mt: 0.5, borderRadius: 2, border: '1px solid', borderColor: 'divider', overflow: 'hidden' }

const emptyDraft = (column) => (column.filter === 'select' ? [] : column.filter === 'date' ? {} : '')
const normalize = (column, value) => {
  if (column.filter === 'select') return [...(Array.isArray(value) ? value : [])].sort()
  if (column.filter === 'date') return { from: value?.from || '', to: value?.to || '' }
  return String(value ?? '').trim()
}

function OptionList({ column, options, draft, setDraft }) {
  const [optionQuery, setOptionQuery] = useState('')
  const needle = optionQuery.trim().toLowerCase()
  const visible = useMemo(
    () => options.filter((option) => `${option.label} ${option.sublabel ?? ''}`.toLowerCase().includes(needle)),
    [options, needle],
  )
  const visibleValues = visible.map((option) => option.value)
  const selectedVisible = visibleValues.filter((value) => draft.includes(value)).length
  const allSelected = visible.length > 0 && selectedVisible === visible.length

  const toggle = (value) => setDraft(draft.includes(value) ? draft.filter((item) => item !== value) : [...draft, value])
  const toggleAll = () => setDraft(allSelected ? draft.filter((value) => !visibleValues.includes(value)) : [...new Set([...draft, ...visibleValues])])

  return (
    <>
      <Box sx={{ p: 1.5, pb: 1 }}>
        <SearchInput value={optionQuery} onChange={setOptionQuery} label={`Search ${column.label}`} placeholder={`Search by ${column.label.toLowerCase()}`} />
      </Box>
      <Box sx={{ maxHeight: 260, overflowY: 'auto', borderTop: '1px solid', borderBottom: '1px solid', borderColor: 'divider', py: 0.5 }}>
        {visible.length === 0 ? (
          <Typography variant="body2" color="text.secondary" sx={{ px: 2, py: 1.5 }}>No options</Typography>
        ) : (
          <>
            <FormControlLabel
              sx={{ display: 'flex', mx: 0, pl: 1, pr: 1.5, '&:hover': { bgcolor: 'action.hover' } }}
              control={<Checkbox size="small" checked={allSelected} indeterminate={selectedVisible > 0 && !allSelected} onChange={toggleAll} />}
              label={<Typography variant="body2" sx={{ fontWeight: 600 }}>Select All</Typography>}
            />
            {visible.map((option) => (
              <FormControlLabel
                key={option.value}
                sx={{ display: 'flex', mx: 0, pl: 1, pr: 1.5, '&:hover': { bgcolor: 'action.hover' } }}
                control={<Checkbox size="small" checked={draft.includes(option.value)} onChange={() => toggle(option.value)} />}
                label={(
                  <Box sx={{ py: 0.25 }}>
                    <Typography variant="body2" sx={{ lineHeight: 1.35 }}>{option.label}</Typography>
                    {option.sublabel ? <Typography variant="caption" color="text.secondary" sx={{ display: 'block', lineHeight: 1.3 }}>{option.sublabel}</Typography> : null}
                  </Box>
                )}
              />
            ))}
          </>
        )}
      </Box>
    </>
  )
}

// Edits a draft; nothing reaches the table until Apply. Mounted only while the popover is open, so reopening starts from the applied value.
function FilterPanel({ column, applied, options, onApply, onClose }) {
  const [draft, setDraft] = useState(() => applied ?? emptyDraft(column))
  const changed = JSON.stringify(normalize(column, draft)) !== JSON.stringify(normalize(column, applied))
  const invalidRange = column.filter === 'date' && Boolean(draft?.from && draft?.to && draft.from > draft.to)
  const apply = () => { onApply(isFilterActive(column, draft) ? draft : undefined); onClose() }

  let body
  if (column.filter === 'select') {
    body = <OptionList column={column} options={options ?? []} draft={Array.isArray(draft) ? draft : []} setDraft={setDraft} />
  } else if (column.filter === 'date') {
    const range = draft ?? {}
    const specific = range.from && range.from === range.to ? range.from : ''
    body = (
      <Stack sx={{ gap: 1.5, p: 1.5 }}>
        {(options ?? []).length > 0 ? (
          <TextField
            select
            size="small"
            label="Specific date"
            value={specific}
            onChange={(event) => setDraft(event.target.value ? { from: event.target.value, to: event.target.value } : {})}
            slotProps={{ inputLabel: { shrink: true }, select: { native: true } }}
          >
            <option value="">Any available date</option>
            {options.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
          </TextField>
        ) : null}
        <Typography variant="caption" color="text.secondary">Or choose a range</Typography>
        <TextField size="small" type="date" label="From" value={range.from ?? ''} onChange={(event) => setDraft({ ...range, from: event.target.value })} error={invalidRange} slotProps={{ inputLabel: { shrink: true } }} />
        <TextField size="small" type="date" label="To" value={range.to ?? ''} onChange={(event) => setDraft({ ...range, to: event.target.value })} error={invalidRange} helperText={invalidRange ? 'The end date must be on or after the start date.' : undefined} slotProps={{ inputLabel: { shrink: true } }} />
        <Typography variant="caption" color="text.secondary">Employees with no date are hidden while this filter is active.</Typography>
      </Stack>
    )
  } else {
    body = (
      <Box sx={{ p: 1.5 }}>
        <TextField
          autoFocus
          size="small"
          fullWidth
          value={draft ?? ''}
          onChange={(event) => setDraft(event.target.value)}
          onKeyDown={(event) => { if (event.key === 'Enter' && changed) apply() }}
          placeholder={`Search ${column.label.toLowerCase()}`}
          slotProps={{ htmlInput: { 'aria-label': `Filter ${column.label}` } }}
        />
      </Box>
    )
  }

  return (
    <Box sx={{ width: 300, maxWidth: '100%' }}>
      {body}
      <Stack direction="row" sx={{ alignItems: 'center', gap: 1, px: 1.5, py: 1.25, bgcolor: 'background.default' }}>
        <Button size="small" onClick={() => setDraft(emptyDraft(column))} disabled={!isFilterActive(column, draft)} sx={{ mr: 'auto' }}>Clear All</Button>
        <Button size="small" variant="outlined" onClick={onClose}>Cancel</Button>
        <Button size="small" variant="contained" onClick={apply} disabled={!changed || invalidRange}>Apply</Button>
      </Stack>
    </Box>
  )
}

// Sort choices for a column that can be sorted by more than one key (Employee: name or code). Clicking the active arrow again clears it.
function SortPanel({ column, sort, onSortTo, onClose }) {
  return (
    <Box sx={{ width: 320, maxWidth: '100%', p: 2 }}>
      <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 1 }}>Sort “{column.label}” column by</Typography>
      {column.sortOptions.map((option, index) => (
        <Stack key={option.id} direction="row" sx={{ alignItems: 'center', justifyContent: 'space-between', gap: 2, py: 1.25, borderTop: index ? '1px solid' : 0, borderColor: 'divider' }}>
          <Box sx={{ minWidth: 0 }}>
            <Typography variant="body2" sx={{ fontWeight: 650 }}>{option.label}</Typography>
            <Typography variant="caption" color="text.secondary">{option.hint}</Typography>
          </Box>
          <Stack direction="row" sx={{ gap: 0.5, flexShrink: 0 }}>
            {[['asc', ArrowUp, 'ascending'], ['desc', ArrowDown, 'descending']].map(([dir, Icon, word]) => {
              const active = sort?.id === option.id && sort.dir === dir
              return (
                <IconButton
                  key={dir}
                  size="small"
                  aria-pressed={active}
                  aria-label={`Sort by ${option.label} ${word}`}
                  onClick={() => { onSortTo(option.id, active ? null : dir); onClose() }}
                  sx={{ ...iconButtonSx(active), p: 0.75, border: '1px solid', borderColor: active ? 'secondary.main' : 'divider' }}
                >
                  <Icon size={15} aria-hidden="true" />
                </IconButton>
              )
            })}
          </Stack>
        </Stack>
      ))}
    </Box>
  )
}

// Table header cell: sort control | filter control, each opening a popover where the column needs one.
export function ColumnHeader({ column, sort, onSort, onSortTo, filterValue, onFilterChange, options }) {
  const [filterAnchor, setFilterAnchor] = useState(null)
  const [sortAnchor, setSortAnchor] = useState(null)
  const sortKeys = column.sortOptions ?? [{ id: column.id }]
  const activeSort = sort && sortKeys.some((key) => key.id === sort.id) ? sort : null
  const direction = activeSort?.dir ?? null
  const filterActive = isFilterActive(column, filterValue)
  const SortIcon = direction === 'asc' ? ArrowUp : direction === 'desc' ? ArrowDown : ArrowUpDown
  const nextSort = direction === 'asc' ? 'descending' : direction === 'desc' ? 'default order' : 'ascending'
  const multiSort = Boolean(column.sortOptions)

  return (
    <TableCell aria-sort={direction === 'asc' ? 'ascending' : direction === 'desc' ? 'descending' : undefined} sx={headCellSx}>
      <Box sx={{ display: 'inline-flex', alignItems: 'center', gap: 0.5 }}>
        <span>{column.label}</span>
        {column.sort ? (
          <IconButton
            size="small"
            onClick={(event) => (multiSort ? setSortAnchor(event.currentTarget) : onSort(column.id))}
            aria-label={multiSort ? `Sort ${column.label} column` : `Sort by ${column.label}, next: ${nextSort}`}
            aria-haspopup={multiSort ? 'dialog' : undefined}
            sx={iconButtonSx(Boolean(direction))}
          >
            <SortIcon size={15} aria-hidden="true" />
          </IconButton>
        ) : null}
        {column.sort && column.filter ? <Box aria-hidden="true" sx={{ width: '1px', height: 16, bgcolor: 'divider' }} /> : null}
        {column.filter ? (
          <IconButton size="small" onClick={(event) => setFilterAnchor(event.currentTarget)} aria-label={`Filter ${column.label}${filterActive ? ' (active)' : ''}`} aria-haspopup="dialog" sx={iconButtonSx(filterActive)}>
            <Funnel size={15} aria-hidden="true" />
          </IconButton>
        ) : null}
      </Box>

      {multiSort ? (
        <Popover
          open={Boolean(sortAnchor)}
          anchorEl={sortAnchor}
          onClose={() => setSortAnchor(null)}
          anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
          slotProps={{ paper: { sx: popoverPaperSx, role: 'dialog', 'aria-label': `${column.label} sort` } }}
        >
          <SortPanel column={column} sort={sort} onSortTo={onSortTo} onClose={() => setSortAnchor(null)} />
        </Popover>
      ) : null}

      <Popover
        open={Boolean(filterAnchor)}
        anchorEl={filterAnchor}
        onClose={() => setFilterAnchor(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
        slotProps={{ paper: { sx: popoverPaperSx, role: 'dialog', 'aria-label': `${column.label} filter` } }}
      >
        <FilterPanel column={column} applied={filterValue} options={options} onApply={(next) => onFilterChange(column.id, next)} onClose={() => setFilterAnchor(null)} />
      </Popover>
    </TableCell>
  )
}