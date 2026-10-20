import { useMemo, useState } from 'react'
import { Alert, Box, LinearProgress, Paper, Snackbar, TablePagination } from '@mui/material'
import { EmptyState } from '../../../components/common/EmptyState'
import { ErrorState } from '../../../components/common/ErrorState'
import { PageHeader } from '../../../components/common/PageHeader'
import { PAGE_SIZE_OPTIONS, DEFAULT_PAGE_SIZE } from '../api/attendanceApi'
import { AttendanceDetailDrawer } from '../components/AttendanceDetailDrawer'
import { AttendanceFilters } from '../components/AttendanceFilters'
import { AttendancePeriodControls } from '../components/AttendancePeriodControls'
import { AttendanceSummaryCards } from '../components/AttendanceSummaryCards'
import { AttendanceTable } from '../components/AttendanceTable'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
import {
  downloadBlob, useAttendanceExport, useAttendanceFilterOptions, useAttendanceList, useAttendanceSummary,
} from '../hooks/useAttendanceQueries'
import { getPeriodRange } from '../utils/dateRange'
import { attendanceErrorMessage, exportErrorMessage } from '../utils/errors'

const EMPTY_FILTERS = { branch: '', department: '', designation: '', status: '' }
const EMPTY_OPTIONS = { branches: [], departments: [], designations: [] }

export function AttendancePage() {
  const [range, setRange] = useState(() => ({ period: 'today', ...getPeriodRange('today') }))
  const [search, setSearch] = useState('')
  const [filters, setFilters] = useState(EMPTY_FILTERS)
  const [pageSize, setPageSize] = useState(DEFAULT_PAGE_SIZE)
  const [selection, setSelection] = useState(null)
  const [drawerOpen, setDrawerOpen] = useState(false)
  const [exportError, setExportError] = useState('')

  const debouncedSearch = useDebouncedValue(search, 400)

  // Every filter/date/page-size change falls back to page 1 without an extra effect or a wasted request.
  const filterKey = JSON.stringify([range, debouncedSearch, filters, pageSize])
  const [pageState, setPageState] = useState({ key: filterKey, page: 1 })
  const page = pageState.key === filterKey ? pageState.page : 1

  const queryState = useMemo(
    () => ({ range: { start: range.start, end: range.end }, filters: { ...filters, search: debouncedSearch } }),
    [range, filters, debouncedSearch],
  )

  const summary = useAttendanceSummary(queryState)
  const list = useAttendanceList(queryState, page, pageSize)
  const optionsQuery = useAttendanceFilterOptions()
  const exporter = useAttendanceExport()

  const rows = list.data?.results ?? []
  const total = list.data?.count ?? 0
  const filtersActive = Boolean(debouncedSearch.trim() || filters.branch || filters.department || filters.designation || filters.status)

  const changePeriod = (period) => setRange({ period, ...(period === 'custom' ? { start: range.start, end: range.end } : getPeriodRange(period)) })
  const changeCustomRange = (start, end) => setRange({ period: 'custom', start, end })

  const changeFilter = (patch) => setFilters((current) => {
    const next = { ...current, ...patch }
    if ('branch' in patch) { next.department = ''; next.designation = '' }
    if ('department' in patch) next.designation = ''
    return next
  })

  const openRow = (row) => {
    setSelection({ employeeId: row.employee.id, date: row.attendance_date, row })
    setDrawerOpen(true)
  }

  const exportReport = () => {
    exporter.mutate(queryState, {
      onSuccess: ({ blob, filename }) => downloadBlob(blob, filename ?? `attendance-report-${range.start}-to-${range.end}.csv`),
      onError: async (error) => setExportError(await exportErrorMessage(error)),
    })
  }

  return (
    <Box>
      <PageHeader
        title="Attendance"
        subtitle="Track and manage employee attendance records"
        action={(
          <AttendancePeriodControls
            range={range} onPeriodChange={changePeriod} onCustomRange={changeCustomRange}
            onExport={exportReport} exporting={exporter.isPending}
          />
        )}
      />

      {summary.isError && !summary.data ? (
        <ErrorState message={attendanceErrorMessage(summary.error)} onRetry={() => summary.refetch()} retrying={summary.isFetching} />
      ) : (
        <AttendanceSummaryCards summary={summary.data} loading={summary.isLoading} range={range} />
      )}

      <Paper variant="outlined" sx={{ overflow: 'hidden' }}>
        <AttendanceFilters
          search={search} onSearch={setSearch} filters={filters} onFilter={changeFilter}
          options={optionsQuery.data ?? EMPTY_OPTIONS} optionsLoading={optionsQuery.isLoading}
        />
        <Box sx={{ height: 3 }}>{list.isPlaceholderData ? <LinearProgress aria-label="Updating attendance" /> : null}</Box>

        {list.isError && !list.data ? (
          <Box sx={{ px: 2, pb: 2 }}>
            <ErrorState message={attendanceErrorMessage(list.error)} onRetry={() => list.refetch()} retrying={list.isFetching} />
          </Box>
        ) : !list.isLoading && rows.length === 0 ? (
          <EmptyState
            compact
            title={filtersActive ? 'No employees match the selected filters' : 'No attendance records found'}
            description={filtersActive ? 'Try changing or clearing the filters.' : 'There are no attendance records for the selected period.'}
          />
        ) : (
          <Box sx={{ opacity: list.isPlaceholderData ? 0.6 : 1, transition: 'opacity 120ms' }}>
            <AttendanceTable rows={rows} loading={list.isLoading} showDate={range.start !== range.end} onOpen={openRow} />
          </Box>
        )}

        <TablePagination
          component="div" count={total} page={page - 1} rowsPerPage={pageSize} rowsPerPageOptions={PAGE_SIZE_OPTIONS}
          onPageChange={(_event, nextPage) => setPageState({ key: filterKey, page: nextPage + 1 })}
          onRowsPerPageChange={(event) => setPageSize(Number(event.target.value))}
          labelRowsPerPage="Rows"
          labelDisplayedRows={({ from, to, count }) => `Showing ${from}–${to} of ${count} records`}
          sx={{ borderTop: 1, borderColor: 'divider' }}
        />
      </Paper>

      <AttendanceDetailDrawer open={drawerOpen} selection={selection} onClose={() => setDrawerOpen(false)} />

      <Snackbar open={Boolean(exportError)} autoHideDuration={6000} onClose={() => setExportError('')}>
        <Alert severity="error" onClose={() => setExportError('')} sx={{ width: '100%' }}>{exportError}</Alert>
      </Snackbar>
    </Box>
  )
}