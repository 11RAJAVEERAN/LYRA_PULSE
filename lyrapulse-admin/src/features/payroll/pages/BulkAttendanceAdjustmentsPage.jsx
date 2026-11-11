import { useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  Alert, Box, Button, Checkbox, CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle,
  FormControl, IconButton, InputLabel, LinearProgress, Menu, MenuItem, Paper, Select, Stack,
  Table, TableBody, TableCell, TableContainer, TableHead, TablePagination, TableRow, TextField,
  Tooltip, Typography,
} from '@mui/material'
import { Download, InfoOutlined, Refresh, RestartAlt, SaveOutlined, Settings, Search } from '@mui/icons-material'
import { PageHeader } from '../../../components/common/PageHeader'
import { colors } from '../../../theme/colors'
import { bulkAttendanceApi, downloadExcel } from '../api/bulkAttendanceApi'

const PAGE_SIZE = 50
const MAX_DAYS = 31
const pad = (value) => String(value).padStart(2, '0')
const dateString = (date) => `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
const defaultRange = () => {
  const today = new Date()
  return { start_date: dateString(new Date(today.getFullYear(), today.getMonth(), 1)), end_date: dateString(today) }
}
const cellKey = (employeeId, date) => `${employeeId}:${date}`
const friendlyError = (error) => {
  const data = error?.response?.data
  if (data?.detail) return data.detail
  if (data && typeof data === 'object') return Object.entries(data).map(([key, value]) => `${key}: ${Array.isArray(value) ? value.join(', ') : typeof value === 'string' ? value : JSON.stringify(value)}`).join(' · ')
  return error?.message || 'Something went wrong. Please try again.'
}

const CODE_STYLE = {
  FD: { label: 'Full Day', color: colors.successDark, background: colors.successBackground },
  A: { label: 'Absent', color: colors.textSecondary, background: colors.surfaceMuted },
  HD: { label: 'Half Day', color: colors.warningDark, background: colors.warningBackground },
  WO: { label: 'Week Off', color: colors.secondary, background: colors.secondarySoft },
}

function StickyCell({ children, left, width, header = false, sx = {}, ...props }) {
  return (
    <TableCell
      {...props}
      sx={{
        ...(left !== undefined ? { position: 'sticky', left, minWidth: width, width, maxWidth: width, zIndex: header ? 5 : 2, bgcolor: header ? '#EFF6FF' : 'background.paper' } : null),
        ...(header ? { top: 0, zIndex: left !== undefined ? 7 : 4, bgcolor: colors.infoBackground, fontWeight: 700 } : null),
        borderColor: 'divider', py: 0.75, px: 1.25, whiteSpace: 'nowrap', ...sx,
      }}
    >{children}</TableCell>
  )
}

export function BulkAttendanceAdjustmentsPage() {
  const queryClient = useQueryClient()
  const initialRange = useMemo(() => defaultRange(), [])
  const [draftRange, setDraftRange] = useState(initialRange)
  const [draftBranch, setDraftBranch] = useState('')
  const [filterState, setFilterState] = useState({ ...initialRange, branch: '' })
  const [page, setPage] = useState(0)
  const [changes, setChanges] = useState({})
  const [message, setMessage] = useState(null)
  const [error, setError] = useState('')
  const [infoOpen, setInfoOpen] = useState(false)
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [confirmText, setConfirmText] = useState('')
  const [columnsAnchor, setColumnsAnchor] = useState(null)
  const [columns, setColumns] = useState({ department: true, designation: true })

  const gridParams = useMemo(() => {
    const { branch, ...rangeParams } = filterState
    return { ...rangeParams, ...(branch ? { branch } : {}), page: page + 1, page_size: PAGE_SIZE }
  }, [filterState, page])
  const gridQuery = useQuery({
    queryKey: ['bulk-attendance-grid', gridParams],
    queryFn: ({ signal }) => bulkAttendanceApi.grid(gridParams, signal),
    staleTime: 0,
  })
  const codesQuery = useQuery({ queryKey: ['bulk-attendance-codes'], queryFn: ({ signal }) => bulkAttendanceApi.codes(signal) })
  const branchesQuery = useQuery({ queryKey: ['bulk-attendance-branches'], queryFn: ({ signal }) => bulkAttendanceApi.branches(signal) })
  const saveMutation = useMutation({ mutationFn: bulkAttendanceApi.save })
  const exportMutation = useMutation({ mutationFn: bulkAttendanceApi.export })

  const grid = gridQuery.data
  const rows = grid?.results ?? []
  const dates = grid?.dates ?? []
  const count = grid?.count ?? 0
  const pendingCount = Object.keys(changes).length
  const canEdit = codesQuery.data?.[0]?.editable ?? false
  const branchOptions = branchesQuery.data ?? []

  const changeCell = (row, date, code) => {
    const key = cellKey(row.employee_id, date)
    const original = row.cells.find((cell) => cell.date === date)?.code
    setChanges((current) => {
      const next = { ...current }
      if (code === original) delete next[key]
      else next[key] = { employee_id: row.employee_id, attendance_date: date, code }
      return next
    })
    setMessage(null)
  }

  const runSearch = () => {
    if (!draftRange.start_date || !draftRange.end_date) {
      setError('Choose both a From date and a To date.')
      return
    }
    if (draftRange.start_date > draftRange.end_date) {
      setError('From date must be on or before To date.')
      return
    }
    const dayCount = Math.round((new Date(`${draftRange.end_date}T00:00:00`) - new Date(`${draftRange.start_date}T00:00:00`)) / 86400000) + 1
    if (dayCount > MAX_DAYS) {
      setError(`Choose a date range of ${MAX_DAYS} days or fewer.`)
      return
    }
    if (pendingCount && !window.confirm('Searching with new filters will discard your unsaved attendance changes. Continue?')) return
    setError('')
    setChanges({})
    setPage(0)
    setFilterState({ ...draftRange, branch: draftBranch })
  }

  const refresh = () => {
    if (pendingCount && !window.confirm('Discard unsaved changes and reload attendance?')) return
    setChanges({})
    setMessage(null)
    gridQuery.refetch()
  }

  const confirmSave = () => {
    if (confirmText.trim().toUpperCase() !== 'CONFIRM') return
    setError('')
    const payload = Object.values(changes)
    saveMutation.mutate(payload, {
      onSuccess: (result) => {
        setChanges({})
        setConfirmOpen(false)
        setConfirmText('')
        setError('')
        setMessage(`Saved ${result?.saved ?? payload.length} attendance change(s).`)
        queryClient.invalidateQueries({ queryKey: ['bulk-attendance-grid'] })
      },
      onError: (saveError) => setError(friendlyError(saveError)),
    })
  }

  const exportExcel = () => {
    if (pendingCount && !window.confirm(`There are ${pendingCount} unsaved change(s). The Excel file contains saved data only. Export anyway?`)) return
    const params = { start_date: filterState.start_date, end_date: filterState.end_date, ...(filterState.branch ? { branch: filterState.branch } : {}) }
    exportMutation.mutate(params, {
      onSuccess: ({ blob, filename }) => downloadExcel(blob, filename || `Bulk_Attendance_Adjustments_${filterState.start_date.slice(0, 7)}.xlsx`),
      onError: (exportError) => setError(friendlyError(exportError)),
    })
  }

  const setDraftDate = (key, value) => setDraftRange((current) => ({ ...current, [key]: value }))
  const toggleColumn = (key) => setColumns((current) => ({ ...current, [key]: !current[key] }))
  const noResults = !gridQuery.isLoading && !gridQuery.isError && rows.length === 0
  const visibleFixedCols = [
    { key: 'employee_code', label: 'Employee ID', width: 112 },
    { key: 'employee_name', label: 'Employee Name', width: 205 },
    ...(columns.department ? [{ key: 'department', label: 'Department', width: 150 }] : []),
    ...(columns.designation ? [{ key: 'designation', label: 'Designation', width: 180 }] : []),
  ]

  return (
    <Box sx={{ minWidth: 0 }}>
      <PageHeader title="Bulk Attendance Adjustments" />
      <Paper variant="outlined" sx={{ p: { xs: 1.5, md: 2 }, mb: 2, borderRadius: 2 }}>
        <Stack direction={{ xs: 'column', lg: 'row' }} spacing={1.5} alignItems={{ xs: 'stretch', lg: 'center' }}>
          <Stack direction="row" spacing={1} alignItems="center">
            <TextField label="From date" type="date" size="small" value={draftRange.start_date} onChange={(event) => setDraftDate('start_date', event.target.value)} InputLabelProps={{ shrink: true }} inputProps={{ max: draftRange.end_date }} sx={{ width: { xs: '50%', sm: 170 } }} />
            <Typography color="text.secondary">to</Typography>
            <TextField label="To date" type="date" size="small" value={draftRange.end_date} onChange={(event) => setDraftDate('end_date', event.target.value)} InputLabelProps={{ shrink: true }} inputProps={{ max: dateString(new Date()) }} sx={{ width: { xs: '50%', sm: 170 } }} />
          </Stack>
          <FormControl size="small" sx={{ minWidth: { xs: '100%', lg: 220 } }}>
            <InputLabel id="adjustment-branch-label">Branch</InputLabel>
            <Select labelId="adjustment-branch-label" label="Branch" value={draftBranch} onChange={(event) => setDraftBranch(event.target.value)}>
              <MenuItem value="">All permitted branches</MenuItem>
              {branchOptions.map((branch) => <MenuItem key={branch.id} value={String(branch.id)}>{branch.name}</MenuItem>)}
            </Select>
          </FormControl>
          <Button variant="contained" startIcon={<Search />} onClick={runSearch} disabled={gridQuery.isFetching && !gridQuery.data}>Search</Button>
        </Stack>
      </Paper>

      <Paper variant="outlined" sx={{ borderRadius: 2, overflow: 'hidden' }}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={1} alignItems={{ xs: 'stretch', md: 'center' }} justifyContent="space-between" sx={{ p: 1.5 }}>
          <Stack direction="row" spacing={1} alignItems="center">
            <Tooltip title="Attendance code meanings and restrictions"><IconButton aria-label="Attendance code information" onClick={() => setInfoOpen(true)}><InfoOutlined /></IconButton></Tooltip>
            {pendingCount > 0 ? <Typography variant="body2" color="text.secondary">{pendingCount} unsaved change{pendingCount === 1 ? '' : 's'}</Typography> : <Typography variant="body2" color="text.secondary">{count.toLocaleString()} employees</Typography>}
          </Stack>
          <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
            <Button variant="contained" startIcon={saveMutation.isPending ? <CircularProgress size={16} color="inherit" /> : <SaveOutlined />} disabled={!canEdit || !pendingCount || saveMutation.isPending} onClick={() => { setConfirmText(''); setConfirmOpen(true) }}>
              Save Changes{pendingCount ? ` (${pendingCount})` : ''}
            </Button>
            <Button variant="outlined" startIcon={exportMutation.isPending ? <CircularProgress size={16} /> : <Download />} disabled={exportMutation.isPending || gridQuery.isLoading} onClick={exportExcel}>Export Excel</Button>
            <Button variant="outlined" startIcon={<Settings />} onClick={(event) => setColumnsAnchor(event.currentTarget)}>Columns</Button>
            <Button variant="outlined" startIcon={<RestartAlt />} onClick={() => { setColumns({ department: true, designation: true }); setColumnsAnchor(null) }}>Reset Columns</Button>
            <Tooltip title="Reload attendance"><span><IconButton aria-label="Refresh attendance" onClick={refresh} disabled={gridQuery.isFetching}><Refresh /></IconButton></span></Tooltip>
          </Stack>
        </Stack>
        <Menu anchorEl={columnsAnchor} open={Boolean(columnsAnchor)} onClose={() => setColumnsAnchor(null)}>
          <MenuItem onClick={() => toggleColumn('department')}><Checkbox size="small" checked={columns.department} />Department</MenuItem>
          <MenuItem onClick={() => toggleColumn('designation')}><Checkbox size="small" checked={columns.designation} />Designation</MenuItem>
          <MenuItem disabled><Checkbox size="small" checked disabled />Employee ID and Name (required)</MenuItem>
        </Menu>
        {error ? <Alert severity="error" onClose={() => setError('')} sx={{ mx: 1.5, mb: 1 }}>{error}</Alert> : null}
        {message ? <Alert severity="success" onClose={() => setMessage(null)} sx={{ mx: 1.5, mb: 1 }}>{message}</Alert> : null}
        {gridQuery.isFetching && gridQuery.data ? <LinearProgress /> : null}
        {gridQuery.isError && !gridQuery.data ? <Alert severity="error" sx={{ m: 2 }}>{friendlyError(gridQuery.error)}</Alert> : null}
        {noResults ? <Box sx={{ p: 6, textAlign: 'center' }}><Typography fontWeight={600}>No employees found</Typography><Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>Try a different date range or branch.</Typography></Box> : null}
        {!gridQuery.isError && !noResults ? (
          <TableContainer sx={{ maxHeight: 'calc(100vh - 330px)', minHeight: 320, overflow: 'auto', borderTop: 1, borderColor: 'divider' }}>
            <Table stickyHeader size="small" sx={{ width: 'max-content', minWidth: '100%', tableLayout: 'fixed' }}>
              <TableHead>
                <TableRow>
                  {visibleFixedCols.map((column, index) => {
                    const left = visibleFixedCols.slice(0, index).reduce((sum, item) => sum + item.width, 0)
                    return <StickyCell key={column.key} header left={left} width={column.width} sx={{ height: 42 }}>{column.label}</StickyCell>
                  })}
                  {dates.map((item) => (
                    <StickyCell key={item.date} header align="center" sx={{ minWidth: 76, width: 76, height: 42 }}>
                      <Typography variant="caption" fontWeight={700} display="block">{new Date(`${item.date}T00:00:00`).toLocaleDateString(undefined, { day: '2-digit', month: 'short' })}</Typography>
                      <Typography variant="caption" color="text.secondary">{item.weekday}</Typography>
                    </StickyCell>
                  ))}
                </TableRow>
              </TableHead>
              <TableBody>
                {gridQuery.isLoading ? Array.from({ length: 8 }, (_, index) => <TableRow key={index}><TableCell colSpan={visibleFixedCols.length + Math.max(dates.length, 1)}><LinearProgress /></TableCell></TableRow>) : rows.map((row) => (
                  <TableRow key={row.employee_id} hover>
                    {visibleFixedCols.map((column, index) => {
                      const left = visibleFixedCols.slice(0, index).reduce((sum, item) => sum + item.width, 0)
                      return <StickyCell key={column.key} left={left} width={column.width} sx={{ fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', boxShadow: index === visibleFixedCols.length - 1 ? 1 : undefined }}>{row[column.key]}</StickyCell>
                    })}
                    {row.cells.map((cell) => {
                      const key = cellKey(row.employee_id, cell.date)
                      if (!cell.editable) return <TableCell key={cell.date} align="center" sx={{ minWidth: 76, width: 76, color: 'text.disabled', borderColor: 'divider' }}>—</TableCell>
                      const pending = changes[key]
                      const code = pending?.code ?? cell.code
                      const style = CODE_STYLE[code] ?? CODE_STYLE.A
                      return (
                        <TableCell key={cell.date} align="center" sx={{ p: 0.5, minWidth: 76, width: 76, borderColor: 'divider', bgcolor: pending ? colors.surfaceMuted : undefined }}>
                          <Tooltip title={pending ? 'Unsaved change' : cell.adjusted ? 'Saved manual override' : style.label}>
                          <FormControl fullWidth size="small">
                            <Select
                              value={code}
                              displayEmpty
                              aria-label={`${row.employee_name} attendance ${cell.date}`}
                              onChange={(event) => changeCell(row, cell.date, event.target.value)}
                              disabled={!canEdit}
                              sx={{
                                height: 34, fontSize: 13, fontWeight: 700, color: pending ? 'text.primary' : cell.adjusted ? colors.primaryBlue : style.color,
                                bgcolor: pending ? colors.surfaceMuted : style.background,
                                '& .MuiSelect-select': { py: 0.5, pl: 1, pr: '24px !important', textAlign: 'left' },
                                '& fieldset': { borderColor: pending ? colors.borderStrong : 'transparent' },
                                '&:hover fieldset': { borderColor: colors.primaryBlue },
                              }}
                            >
                              {(codesQuery.data ?? []).map((option) => <MenuItem key={option.code} value={option.code}><Box><Typography variant="body2" fontWeight={700}>{option.code}</Typography><Typography variant="caption" color="text.secondary">{option.label}</Typography></Box></MenuItem>)}
                            </Select>
                          </FormControl>
                          </Tooltip>
                        </TableCell>
                      )
                    })}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        ) : null}
        <TablePagination
          component="div" count={count} page={page} rowsPerPage={PAGE_SIZE} rowsPerPageOptions={[PAGE_SIZE]}
          onPageChange={(_event, nextPage) => setPage(nextPage)}
          labelRowsPerPage="Employees per page"
          labelDisplayedRows={({ from, to, count: total }) => `${from}–${to} of ${total}`}
          sx={{ borderTop: 1, borderColor: 'divider' }}
        />
      </Paper>

      <Dialog open={infoOpen} onClose={() => setInfoOpen(false)} fullWidth maxWidth="sm">
        <DialogTitle>Attendance codes</DialogTitle>
        <DialogContent dividers>
          <Stack spacing={1.5}>
            {(codesQuery.data ?? []).map((code) => <Stack key={code.code} direction="row" spacing={1.5} alignItems="flex-start"><Box sx={{ minWidth: 42, px: 1, py: 0.5, borderRadius: 1, bgcolor: CODE_STYLE[code.code]?.background, color: CODE_STYLE[code.code]?.color, fontWeight: 700, textAlign: 'center' }}>{code.code}</Box><Box><Typography fontWeight={600}>{code.label}</Typography><Typography variant="body2" color="text.secondary">{code.description}</Typography><Typography variant="caption" color="text.secondary">{code.editable ? 'Editable by users with employee change permission.' : 'Read only.'}</Typography></Box></Stack>)}
          </Stack>
          <Alert severity="info" sx={{ mt: 2 }}>An existing punch is preserved as source evidence. This grid changes the payroll-facing day classification only. LYRA does not currently expose a separate punch-error flag, so Absent does not imply a punch error.</Alert>
        </DialogContent>
        <DialogActions><Button onClick={() => setInfoOpen(false)}>Close</Button></DialogActions>
      </Dialog>

      <Dialog open={confirmOpen} onClose={() => { if (!saveMutation.isPending) setConfirmOpen(false) }} fullWidth maxWidth="sm">
        <DialogTitle>Confirm Save Changes</DialogTitle>
        <DialogContent>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>You are saving {pendingCount} attendance classification change(s). Type <b>CONFIRM</b> to proceed.</Typography>
          <TextField autoFocus fullWidth label="Confirmation" value={confirmText} onChange={(event) => setConfirmText(event.target.value)} placeholder="Write CONFIRM here" />
          {saveMutation.isError ? <Alert severity="error" sx={{ mt: 2 }}>{friendlyError(saveMutation.error)}</Alert> : null}
          <Alert severity="warning" sx={{ mt: 2 }}>Review the date and employee cells carefully. Saved changes are added to the adjustment audit history.</Alert>
        </DialogContent>
        <DialogActions><Button onClick={() => setConfirmOpen(false)} disabled={saveMutation.isPending}>Go Back</Button><Button variant="contained" onClick={confirmSave} disabled={confirmText.trim().toUpperCase() !== 'CONFIRM' || saveMutation.isPending}>{saveMutation.isPending ? 'Saving…' : 'Proceed'}</Button></DialogActions>
      </Dialog>
    </Box>
  )
}
