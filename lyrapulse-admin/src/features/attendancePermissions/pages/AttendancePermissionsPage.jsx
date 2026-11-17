import { useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  Alert, Box, Button, Checkbox, Chip, CircularProgress, Divider, FormControl, InputAdornment,
  Menu, MenuItem, Paper, Select, Snackbar, Stack, Switch, Table, TableBody, TableCell,
  TableContainer, TableHead, TableRow, TextField, Tooltip, Typography, useTheme,
} from '@mui/material'
import { alpha } from '@mui/material/styles'
import {
  Building2, ChevronLeft, ChevronRight, Fingerprint, MoreVertical, RefreshCw, Search,
  Settings, ShieldCheck, Smartphone, UserRound,
} from 'lucide-react'
import { EmptyState } from '../../../components/common/EmptyState'
import { LoadingState } from '../../../components/common/LoadingState'
import { ErrorState } from '../../../components/common/ErrorState'
import { attendancePermissionsApi } from '../api/attendancePermissionsApi'
import { authService } from '../../../services/authService'

const PAGE_SIZE = 25

/* Fields kept exactly as before (API keys unchanged) */
const fields = [
  ['mobile_gps_attendance_enabled', 'Mobile Attendance'],
  ['location_attendance_enabled', 'Location Verification'],
  ['photo_attendance_enabled', 'Photo Attendance'],
  ['biometric_attendance_enabled', 'Fingerprint Attendance'],
  ['auto_punch_out_enabled', 'Auto punch out'],
]

const controlSx = (C) => ({
  '& .MuiOutlinedInput-root': {
    height: 34,
    borderRadius: '8px',
    bgcolor: C.card,
    color: C.text,
    fontSize: C.caption,
    transition: 'box-shadow 150ms ease',
    '& fieldset': { borderColor: C.border },
    '&:hover fieldset': { borderColor: C.borderStrong },
    '&.Mui-focused fieldset': { borderColor: C.primary, borderWidth: 1.5 },
    '&.Mui-focused': { boxShadow: C.focusShadow },
  },
  '& .MuiOutlinedInput-input': { py: 0, fontSize: C.caption },
  '& .MuiSelect-select.MuiSelect-select': {
    py: 0,
    minHeight: 'unset',
    display: 'flex',
    alignItems: 'center',
  },
  '& .MuiSelect-icon': { color: C.muted, fontSize: '1.125rem' },
  '& .MuiInputAdornment-root': { mr: 0.75 },
})



const switchSx = (C) => ({
  width: 34,
  height: 20,
  p: 0,
  display: 'flex',
  '& .MuiSwitch-switchBase': {
    p: '3px',
    transitionDuration: '150ms',
    '&.Mui-checked': {
      transform: 'translateX(14px)',
      color: C.card,
      '& + .MuiSwitch-track': { backgroundColor: C.primary, opacity: 1, border: 0 },
    },
    '&.Mui-disabled': { opacity: 0.55 },
  },
  '& .MuiSwitch-thumb': {
    width: 14,
    height: 14,
    boxSizing: 'border-box',
    backgroundColor: C.card,
    boxShadow: C.controlShadow,
  },
  '& .MuiSwitch-track': {
    borderRadius: 10,
    backgroundColor: C.off,
    opacity: 1,
    transition: 'background-color 150ms ease',
  },
  '&:hover .MuiSwitch-track': { filter: 'brightness(0.97)' },
})



const headCellSx = (C) => ({
  bgcolor: C.headBg,
  color: C.navy,
  fontSize: C.caption,
  fontWeight: 600,
  height: 44,
  px: 2,
  whiteSpace: 'nowrap',
  borderBottom: `1px solid ${C.border}`,
})



const bodyCellSx = (C) => ({
  py: 1.25,
  px: 2,
  fontSize: C.body2,
  color: C.navy,
  borderBottom: `1px solid ${C.border}`,
  whiteSpace: 'nowrap',
})



/* Sticky (frozen) columns so Employee stays visible while scrolling horizontally */
const stickyHead = (C, left, extra = {}) => ({ position: 'sticky', left, zIndex: 3, bgcolor: C.headBg, ...extra })
const stickyBody = (C, left, extra = {}) => ({ position: 'sticky', left, zIndex: 2, bgcolor: C.card, ...extra })
const stickyEdge = (C) => ({ boxShadow: C.edgeShadow })

const checkboxSx = (C) => ({
  p: '6px',
  color: C.disabled,
  '& .MuiSvgIcon-root': { fontSize: 18 },
  '&.Mui-checked, &.MuiCheckbox-indeterminate': { color: C.primary },
})



function errorText(error) {
  const data = error?.response?.data
  if (data?.detail) return data.detail

  if (data?.errors) {
    return Object.entries(data.errors)
      .map(([field, messages]) => `${field}: ${Array.isArray(messages) ? messages.join(' ') : messages}`)
      .join(' ')
  }

  if (error?.response?.status === 401) return 'Your session has expired. Sign in again to continue.'
  if (error?.response?.status === 403) return 'You are not authorized to manage these attendance permissions.'
  if (error?.response?.status === 404) return 'The employee is no longer available in your authorized branch scope.'

  return data?.message ?? error?.message ?? 'The request could not be completed.'
}

/* Compact numbered pagination: up to 5 page buttons around the current page */
function pageWindow(page, totalPages) {
  const size = Math.min(5, totalPages)
  const start = Math.max(0, Math.min(page - 2, totalPages - size))
  return Array.from({ length: size }, (_, index) => start + index)
}

const pageButtonSx = (C, active) => ({
  minWidth: 28,
  width: 28,
  height: 28,
  p: 0,
  borderRadius: '50%',
  fontSize: C.caption,
  fontWeight: 600,
  boxShadow: 'none',
  textTransform: 'none',
  bgcolor: active ? C.primary : C.hover,
  color: active ? C.card : C.navy,
  '&:hover': { bgcolor: active ? C.primaryDark : C.border, boxShadow: 'none' },
})

const arrowButtonSx = (C) => ({
  minWidth: 28,
  width: 28,
  height: 28,
  p: 0,
  borderRadius: '8px',
  color: C.navy,
  borderColor: C.border,
  bgcolor: C.card,
  '&:hover': { borderColor: C.primary, bgcolor: C.active },
  '&.Mui-disabled': { color: C.disabled, borderColor: C.border },
})



export function AttendancePermissionsPage() {
  const theme = useTheme()
  const C = {
    primary: theme.palette.primary.light,
    primaryDark: theme.palette.info.dark,
    primaryBorder: alpha(theme.palette.primary.light, 0.32),
    navy: theme.palette.text.primary,
    text: theme.palette.text.primary,
    muted: theme.palette.text.secondary,
    page: theme.palette.background.default,
    card: theme.palette.background.paper,
    border: theme.palette.divider,
    borderStrong: theme.palette.action.disabled,
    active: theme.palette.action.selected,
    off: theme.palette.action.disabled,
    disabled: theme.palette.action.disabled,
    headBg: theme.palette.action.hover,
    hover: theme.palette.action.hover,
    selectedRow: alpha(theme.palette.primary.light, 0.06),
    selectedRowHover: alpha(theme.palette.primary.light, 0.10),
    focusShadow: '0 0 0 3px ' + alpha(theme.palette.primary.light, 0.10),
    controlShadow: theme.shadows[1],
    cardShadow: theme.shadows[1],
    edgeShadow: '6px 0 8px -6px ' + alpha(theme.palette.text.primary, 0.14),
    caption: theme.typography.caption.fontSize,
    body1: theme.typography.body1.fontSize,
    body2: theme.typography.body2.fontSize,
    overline: theme.typography.overline.fontSize,
    h5: theme.typography.h5.fontSize,
    h4: theme.typography.h4.fontSize,
  }
  const queryClient = useQueryClient()
  const user = authService.getCurrentUser()

  const [search, setSearch] = useState('')
  const [method, setMethod] = useState('all')
  const [branch, setBranch] = useState('all')
  const [page, setPage] = useState(0)
  const [selected, setSelected] = useState([])
  const [notice, setNotice] = useState(null)
  const [rowMenu, setRowMenu] = useState(null) // { anchor, rowId }
  const [bulkMenu, setBulkMenu] = useState(null) // { anchor, enable }

  const params = useMemo(() => ({
    search: search.trim() || undefined,
    method,
    branch: branch === 'all' ? undefined : branch,
    page: page + 1,
    page_size: PAGE_SIZE,
  }), [search, method, branch, page])

  const query = useQuery({
    queryKey: ['attendance-permissions', user?.id, params],
    queryFn: () => attendancePermissionsApi.list(params),
  })

  const branchQuery = useQuery({
    queryKey: ['attendance-permission-branches', user?.id],
    queryFn: attendancePermissionsApi.branches,
  })

  const refresh = () =>
    queryClient.invalidateQueries({
      queryKey: ['attendance-permissions', user?.id],
    })

  const save = useMutation({
    mutationFn: ({ employeeId, permissions }) =>
      attendancePermissionsApi.update(employeeId, permissions),

    onSuccess: async () => {
      await refresh()
      setNotice({ severity: 'success', message: 'Attendance permission saved.' })
    },

    onError: (error) =>
      setNotice({ severity: 'error', message: errorText(error) }),
  })

  const bulk = useMutation({
    mutationFn: ({ ids, permissions }) =>
      attendancePermissionsApi.bulkUpdate(ids, permissions),

    onSuccess: async () => {
      const updatedCount = selected.length
      setSelected([])
      await refresh()
      setNotice({
        severity: 'success',
        message: `Permissions updated for ${updatedCount} employees.`,
      })
    },

    onError: (error) =>
      setNotice({ severity: 'error', message: errorText(error) }),
  })

  const rows = query.data?.results ?? []
  const totalCount = query.data?.count ?? 0
  const totalPages = Math.max(1, Math.ceil(totalCount / PAGE_SIZE))
  const rangeStart = totalCount === 0 ? 0 : page * PAGE_SIZE + 1
  const rangeEnd = Math.min(totalCount, page * PAGE_SIZE + rows.length)

  const allOnPage = rows.length > 0 && rows.every((row) => selected.includes(row.id))
  const someOnPage = rows.some((row) => selected.includes(row.id))
  const busy = save.isPending || bulk.isPending

  const menuRow = rowMenu ? rows.find((row) => row.id === rowMenu.rowId) : null

  const toggleSelected = (id) =>
    setSelected((current) =>
      current.includes(id)
        ? current.filter((value) => value !== id)
        : [...current, id]
    )

  const updateOne = (row, field, value) =>
    save.mutate({ employeeId: row.id, permissions: { [field]: value } })

  const runBulk = (field, value) => {
    setBulkMenu(null)
    bulk.mutate({ ids: selected, permissions: { [field]: value } })
  }

  const clearFilters = () => {
    setSearch('')
    setMethod('all')
    setBranch('all')
    setPage(0)
  }

  const changePage = (next) => {
    setPage(next)
    setSelected([])
  }

  return (
    <Box sx={{ width: '100%', minWidth: 0, maxWidth: '100%', fontFamily: theme.typography.fontFamily }}>
      {/* ---------- Simple page header ---------- */}
      <Stack direction="row" spacing={1.75} alignItems="center" sx={{ mb: 2.5 }}>
        <Box
          aria-hidden="true"
          sx={{
            width: 44,
            height: 44,
            flex: '0 0 44px',
            display: 'grid',
            placeItems: 'center',
            borderRadius: '12px',
            border: `1px solid ${C.border}`,
            bgcolor: C.card,
            color: C.primary,
          }}
        >
          <UserRound size={22} strokeWidth={1.75} />
        </Box>

        <Box sx={{ minWidth: 0 }}>
          <Typography
            component="h1"
            sx={{
              color: C.navy,
              fontSize: { xs: C.h5, sm: C.h4 },
              fontWeight: 700,
              lineHeight: 1.25,
              letterSpacing: '-0.01em',
            }}
          >
            Attendance Permission
          </Typography>
          {/* <Typography sx={{ color: C.muted, fontSize: C.body1, mt: 0.25 }}>
            Manage employee attendance access and verification settings.
          </Typography> */}
        </Box>
      </Stack>

      {branchQuery.isError ? (
        <Alert severity="error" sx={{ mb: 2 }}>
          {errorText(branchQuery.error)}
        </Alert>
      ) : null}

      {/* ---------- Search & filters (single row on desktop) ---------- */}
      <Paper
        elevation={0}
        sx={{
          p: { xs: 1.25, sm: 1.5 },
          mb: 2,
          borderRadius: '12px',
          border: `1px solid ${C.border}`,
          bgcolor: C.card,
          boxShadow: C.cardShadow,
        }}
      >
        <Stack
          direction={{ xs: 'column', md: 'row' }}
          spacing={1.5}
          alignItems={{ xs: 'stretch', md: 'center' }}
        >
          <TextField
            size="small"
            value={search}
            onChange={(event) => {
              setSearch(event.target.value)
              setPage(0)
            }}
            placeholder="Search employees by name or ID..."
            inputProps={{ 'aria-label': 'Search employees by name or ID' }}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start" sx={{ color: C.navy }}>
                  <Search size={16} aria-hidden="true" />
                </InputAdornment>
              ),
            }}
            sx={{ ...controlSx(C), flex: '1 1 auto', minWidth: 0 }}
          />

          <FormControl size="small" sx={{ ...controlSx(C), flex: { md: '0 0 190px' } }}>
            <Select
              value={method}
              onChange={(event) => {
                setMethod(event.target.value)
                setPage(0)
              }}
              inputProps={{ 'aria-label': 'Attendance method' }}
              startAdornment={
                <InputAdornment position="start" sx={{ color: C.navy }}>
                  <Settings size={16} aria-hidden="true" />
                </InputAdornment>
              }
            >
              <MenuItem value="all">All Methods</MenuItem>
              <MenuItem value="mobile">Mobile</MenuItem>
              <MenuItem value="biometric">Fingerprint</MenuItem>
              <MenuItem value="none">Not enabled</MenuItem>
            </Select>
          </FormControl>

          <Divider
            orientation="vertical"
            flexItem
            sx={{ display: { xs: 'none', md: 'block' }, borderColor: C.border }}
          />

          <FormControl size="small" sx={{ ...controlSx(C), flex: { md: '0 0 190px' } }}>
            <Select
              value={branch}
              onChange={(event) => {
                setBranch(event.target.value)
                setPage(0)
              }}
              inputProps={{ 'aria-label': 'Branch' }}
              startAdornment={
                <InputAdornment position="start" sx={{ color: C.navy }}>
                  <Building2 size={16} aria-hidden="true" />
                </InputAdornment>
              }
            >
              <MenuItem value="all">All Branches</MenuItem>
              {(branchQuery.data ?? []).map((item) => (
                <MenuItem key={item.id} value={String(item.id)}>
                  {item.name}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <Button
            variant="outlined"
            startIcon={<RefreshCw size={15} aria-hidden="true" />}
            onClick={clearFilters}
            sx={{
              height: 32,
              px: 1.5,
              flexShrink: 0,
              borderRadius: '8px',
              textTransform: 'none',
              fontSize: C.caption,
              fontWeight: 500,
              '& .MuiButton-startIcon': { mr: 0.75, ml: 0 },
              color: C.primary,
              bgcolor: C.card,
              borderColor: C.primaryBorder,
              boxShadow: 'none',
              '&:hover': { borderColor: C.primary, bgcolor: C.active, boxShadow: 'none' },
            }}
          >
            Reset
          </Button>
        </Stack>

        {/* Bulk actions – same capabilities as before, shown only when rows are selected */}
        {selected.length > 0 || busy ? (
          <Stack
            direction="row"
            spacing={1}
            mt={1.5}
            alignItems="center"
            flexWrap="wrap"
            useFlexGap
          >
            {selected.length > 0 ? (
              <>
                <Chip
                  icon={<ShieldCheck size={14} />}
                  label={`${selected.length} selected`}
                  sx={{
                    height: 28,
                    fontSize: C.caption,
                    fontWeight: 600,
                    color: C.primary,
                    bgcolor: C.active,
                    '& .MuiChip-icon': { color: C.primary },
                  }}
                />
                <Button
                  variant="contained"
                  disabled={bulk.isPending}
                  onClick={(event) => setBulkMenu({ anchor: event.currentTarget, enable: true })}
                  sx={{
                    height: 30, px: 1.5, fontSize: C.caption, borderRadius: '8px', textTransform: 'none', fontWeight: 500,
                    bgcolor: C.primary, boxShadow: 'none', '&:hover': { bgcolor: C.primaryDark, boxShadow: 'none' },
                  }}
                >
                  Enable…
                </Button>
                <Button
                  variant="outlined"
                  disabled={bulk.isPending}
                  onClick={(event) => setBulkMenu({ anchor: event.currentTarget, enable: false })}
                  sx={{
                    height: 30, px: 1.5, fontSize: C.caption, borderRadius: '8px', textTransform: 'none', fontWeight: 500,
                    color: C.primary, borderColor: C.primaryBorder, '&:hover': { borderColor: C.primary, bgcolor: C.active },
                  }}
                >
                  Disable…
                </Button>
              </>
            ) : null}

            {busy ? (
              <Chip
                icon={<CircularProgress size={14} />}
                label="Saving permissions"
                variant="outlined"
                sx={{ height: 28, fontSize: C.caption, borderColor: C.border }}
              />
            ) : null}
          </Stack>
        ) : null}
      </Paper>

      <Menu
        anchorEl={bulkMenu?.anchor}
        open={Boolean(bulkMenu)}
        onClose={() => setBulkMenu(null)}
      >
        {fields.map(([field, label]) => (
          <MenuItem key={field} onClick={() => runBulk(field, bulkMenu?.enable ?? true)}>
            {bulkMenu?.enable ? 'Enable' : 'Disable'} {label}
          </MenuItem>
        ))}
      </Menu>

      {/* ---------- Table ---------- */}
      {query.isLoading ? (
        <LoadingState />
      ) : query.isError ? (
        <ErrorState message={errorText(query.error)} onRetry={() => query.refetch()} />
      ) : rows.length === 0 ? (
        <EmptyState
          title="No employees found"
          description="Try another search or branch filter."
        />
      ) : (
        <Paper
          elevation={0}
          sx={{
            width: '100%',
            minWidth: 0,
            maxWidth: '100%',
            overflow: 'hidden',
            borderRadius: '16px',
            border: `1px solid ${C.border}`,
            bgcolor: C.card,
            boxShadow: C.cardShadow,
          }}
        >
          <TableContainer
            sx={{
              width: '100%',
              overflowX: 'auto',
              scrollbarWidth: 'thin',
              scrollbarColor: `${C.off} transparent`,
              '&::-webkit-scrollbar': { height: 8 },
              '&::-webkit-scrollbar-track': { background: 'transparent' },
              '&::-webkit-scrollbar-thumb': { backgroundColor: C.off, borderRadius: 8 },
              '&:hover::-webkit-scrollbar-thumb': { backgroundColor: C.disabled },
            }}
          >
            <Table
              aria-label="Employee attendance permissions"
              sx={{ width: '100%', minWidth: 1910, tableLayout: 'auto', borderCollapse: 'separate' }}
            >
              <TableHead>
                <TableRow>
                  <TableCell
                    padding="checkbox"
                    sx={{ ...headCellSx(C), ...stickyHead(C,0), width: 44, minWidth: 44, pl: 1 }}
                  >
                    <Checkbox
                      checked={allOnPage}
                      indeterminate={!allOnPage && someOnPage}
                      sx={checkboxSx(C)}
                      onChange={(event) =>
                        setSelected((current) =>
                          event.target.checked
                            ? [...new Set([...current, ...rows.map((row) => row.id)])]
                            : current.filter((id) => !rows.some((row) => row.id === id))
                        )
                      }
                      inputProps={{ 'aria-label': 'Select all employees on this page' }}
                    />
                  </TableCell>
                  <TableCell sx={{ ...headCellSx(C), ...stickyHead(C,44, stickyEdge(C)), minWidth: 230 }}>
                    Employee
                  </TableCell>
                  <TableCell sx={{ ...headCellSx(C), minWidth: 170 }}>Role / Designation</TableCell>
                  <TableCell sx={{ ...headCellSx(C), minWidth: 210 }}>Attendance Method</TableCell>
                  {fields.map(([field, label]) => (
                    <TableCell key={field} align="center" sx={{ ...headCellSx(C), minWidth: 160 }}>
                      {label}
                    </TableCell>
                  ))}
                  <TableCell align="center" sx={{ ...headCellSx(C), minWidth: 150 }}>
                    Face Verification
                  </TableCell>
                  <TableCell sx={{ ...headCellSx(C), minWidth: 260 }}>Fingerprint Device</TableCell>
                  <TableCell align="center" sx={{ ...headCellSx(C), minWidth: 90 }}>
                    Actions
                  </TableCell>
                </TableRow>
              </TableHead>

              <TableBody>
                {rows.map((row) => {
                  const methodLabel = row.attendance_method?.replace('Biometric', 'Fingerprint')
                  const hasFingerprint = methodLabel?.toLowerCase().includes('fingerprint')
                  const hasMobile = methodLabel?.toLowerCase().includes('mobile')
                  const MethodIcon = hasFingerprint ? Fingerprint : hasMobile ? Smartphone : null
                  const isSelected = selected.includes(row.id)

                  return (
                    <TableRow
                      key={row.id}
                      hover
                      selected={isSelected}
                      sx={{
                        height: 64,
                        '&:last-child .MuiTableCell-root': { borderBottom: 0 },
                        '&.Mui-selected, &.Mui-selected:hover': { bgcolor: C.selectedRow },
                        '&.Mui-selected > .MuiTableCell-root': { bgcolor: C.selectedRow },
                        '&:hover > .MuiTableCell-root': { bgcolor: C.hover },
                        '&.Mui-selected:hover > .MuiTableCell-root': { bgcolor: C.selectedRowHover },
                      }}
                    >
                      <TableCell
                        padding="checkbox"
                        sx={{ ...bodyCellSx(C), ...stickyBody(C,0), width: 44, minWidth: 44, pl: 1 }}
                      >
                        <Checkbox
                          checked={isSelected}
                          sx={checkboxSx(C)}
                          onChange={() => toggleSelected(row.id)}
                          inputProps={{ 'aria-label': `Select ${row.name}` }}
                        />
                      </TableCell>

                      <TableCell sx={{ ...bodyCellSx(C), ...stickyBody(C,44, stickyEdge(C)), minWidth: 230 }}>
                        <Typography
                          noWrap
                          sx={{ fontWeight: 700, color: C.navy, fontSize: C.body2, lineHeight: 1.3 }}
                        >
                          {row.name}
                        </Typography>
                      </TableCell>

                      <TableCell sx={{ ...bodyCellSx(C), minWidth: 170 }}>{row.role || '—'}</TableCell>

                      <TableCell sx={{ ...bodyCellSx(C), minWidth: 210 }}>
                        <Chip
                          size="small"
                          icon={MethodIcon ? <MethodIcon size={14} aria-hidden="true" /> : undefined}
                          label={methodLabel}
                          sx={{
                            height: 26,
                            borderRadius: '8px',
                            fontSize: C.overline,
                            fontWeight: 600,
                            bgcolor: hasFingerprint || hasMobile ? C.active : C.hover,
                            color: hasFingerprint || hasMobile ? C.primary : C.muted,
                            '& .MuiChip-icon': { color: 'inherit', ml: 0.75 },
                          }}
                        />
                      </TableCell>

                      {fields.map(([field, label]) => {
                        const message =
                          field === 'auto_punch_out_enabled'
                            ? 'Saved as configuration; automatic execution requires a scheduler.'
                            : `${label} permission`

                        return (
                          <TableCell key={field} align="center" sx={{ ...bodyCellSx(C), minWidth: 160 }}>
                            <Tooltip title={message}>
                              <Box
                                component="span"
                                sx={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}
                              >
                                <Switch
                                  size="small"
                                  checked={Boolean(row[field])}
                                  disabled={busy}
                                  onChange={(event) => updateOne(row, field, event.target.checked)}
                                  inputProps={{ 'aria-label': `${label} for ${row.name}` }}
                                  sx={switchSx(C)}
                                />
                              </Box>
                            </Tooltip>
                          </TableCell>
                        )
                      })}

                      <TableCell align="center" sx={{ ...bodyCellSx(C), minWidth: 150 }}>
                        <Tooltip title="Secure face matching and liveness verification are not configured. Photo capture is not face verification.">
                          <Chip
                            size="small"
                            variant="outlined"
                            label="Unavailable"
                            sx={{
                              height: 24,
                              fontSize: C.overline,
                              borderRadius: '8px',
                              color: C.muted,
                              borderColor: C.border,
                              fontWeight: 600,
                            }}
                          />
                        </Tooltip>
                      </TableCell>

                      <TableCell sx={{ ...bodyCellSx(C), minWidth: 260 }}>
                        {row.biometric_devices?.length ? (
                          <Stack direction="row" spacing={0.5} useFlexGap sx={{ flexWrap: 'nowrap' }}>
                            {row.biometric_devices.map((device) => (
                              <Chip
                                key={device.id}
                                size="small"
                                icon={<Fingerprint size={13} aria-hidden="true" />}
                                label={device.name}
                                sx={{
                                  height: 26,
                                  fontSize: C.overline,
                                  borderRadius: '8px',
                                  fontWeight: 600,
                                  bgcolor: C.active,
                                  color: C.primary,
                                  '& .MuiChip-icon': { color: 'inherit', ml: 0.75 },
                                }}
                              />
                            ))}
                          </Stack>
                        ) : (
                          <Typography sx={{ color: C.muted, fontSize: C.body2 }}>
                            No assigned fingerprint device
                          </Typography>
                        )}
                      </TableCell>

                      <TableCell align="center" sx={{ ...bodyCellSx(C), minWidth: 90 }}>
                        <Tooltip title="More actions">
                          <span>
                            <Button
                              aria-label={`More actions for ${row.name}`}
                              aria-haspopup="menu"
                              onClick={(event) => setRowMenu({ anchor: event.currentTarget, rowId: row.id })}
                              sx={{
                                minWidth: 28,
                                width: 28,
                                height: 28,
                                p: 0,
                                borderRadius: '8px',
                                color: C.navy,
                                '&:hover': { bgcolor: C.active },
                              }}
                            >
                              <MoreVertical size={17} aria-hidden="true" />
                            </Button>
                          </span>
                        </Tooltip>
                      </TableCell>
                    </TableRow>
                  )
                })}
              </TableBody>
            </Table>
          </TableContainer>

          {/* ---------- Pagination ---------- */}
          <Stack
            direction={{ xs: 'column', sm: 'row' }}
            spacing={1.5}
            alignItems={{ xs: 'flex-start', sm: 'center' }}
            justifyContent="space-between"
            sx={{ px: 2, py: 1.25, borderTop: `1px solid ${C.border}` }}
          >
            <Typography sx={{ color: C.navy, fontSize: C.caption }}>
              Showing {rangeStart} – {rangeEnd} of {totalCount} employees
            </Typography>

            <Stack direction="row" spacing={0.75} alignItems="center" component="nav" aria-label="Pagination">
              <Button
                variant="outlined"
                aria-label="Previous page"
                disabled={page === 0}
                onClick={() => changePage(page - 1)}
                sx={arrowButtonSx(C)}
              >
                <ChevronLeft size={16} aria-hidden="true" />
              </Button>

              {pageWindow(page, totalPages).map((index) => (
                <Button
                  key={index}
                  aria-label={`Page ${index + 1}`}
                  aria-current={index === page ? 'page' : undefined}
                  onClick={() => changePage(index)}
                  sx={pageButtonSx(C, index === page)}
                >
                  {index + 1}
                </Button>
              ))}

              <Button
                variant="outlined"
                aria-label="Next page"
                disabled={page >= totalPages - 1}
                onClick={() => changePage(page + 1)}
                sx={arrowButtonSx(C)}
              >
                <ChevronRight size={16} aria-hidden="true" />
              </Button>
            </Stack>
          </Stack>
        </Paper>
      )}

      {/* ---------- Row actions menu ---------- */}
      <Menu
        anchorEl={rowMenu?.anchor}
        open={Boolean(rowMenu && menuRow)}
        onClose={() => setRowMenu(null)}
        slotProps={{ paper: { sx: { minWidth: 190, borderRadius: '12px', border: `1px solid ${C.border}` } } }}
      >
        {menuRow ? (
          <MenuItem
            onClick={() => {
              toggleSelected(menuRow.id)
              setRowMenu(null)
            }}
          >
            {selected.includes(menuRow.id) ? 'Deselect employee' : 'Select employee'}
          </MenuItem>
        ) : null}
      </Menu>

      <Snackbar
        open={Boolean(notice)}
        autoHideDuration={4500}
        onClose={() => setNotice(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        {notice && (
          <Alert severity={notice.severity} onClose={() => setNotice(null)} variant="filled">
            {notice.message}
          </Alert>
        )}
      </Snackbar>
    </Box>
  )
}
