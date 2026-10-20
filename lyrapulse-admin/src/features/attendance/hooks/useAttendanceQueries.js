import { keepPreviousData, useMutation, useQuery } from '@tanstack/react-query'
import { attendanceApi, buildFilterParams, buildSummaryParams } from '../api/attendanceApi'

// Silent background polling for the live Attendance screen. The previous data stays on screen while a refetch runs
// (keepPreviousData / cached data), so nothing flashes. staleTime: 0 is needed for refetchOnWindowFocus to actually
// refetch, because the app-wide default staleTime is 5 minutes. TanStack pauses the interval while the tab is hidden.
export const ATTENDANCE_REFRESH_MS = 5000
const LIVE_REFRESH = { refetchInterval: ATTENDANCE_REFRESH_MS, refetchOnWindowFocus: true, staleTime: 0 }

// Query keys contain every parameter that changes the result, so a filter change never shows stale data.
export const attendanceKeys = {
  all: ['attendance'],
  summary: (params) => ['attendance', 'summary', params],
  list: (params) => ['attendance', 'list', params],
  detail: (employeeId, date) => ['attendance', 'detail', employeeId, date],
  options: ['attendance', 'filter-options'],
}

export function useAttendanceSummary(state) {
  const params = buildSummaryParams(state)
  return useQuery({
    queryKey: attendanceKeys.summary(params),
    queryFn: ({ signal }) => attendanceApi.summary(params, signal),
    placeholderData: keepPreviousData,
    ...LIVE_REFRESH,
  })
}

// Dashboard "today" counts. No date is sent, so the server resolves its own today (and the query rolls over to the
// new day at midnight on its own); scoping to the signed-in user's organization/branches is done by the backend.
export function useTodayAttendanceSummary() {
  return useQuery({
    queryKey: attendanceKeys.summary({}),
    queryFn: ({ signal }) => attendanceApi.summary({}, signal),
    ...LIVE_REFRESH,
  })
}

export function useAttendanceList(state, page, pageSize) {
  const params = { ...buildFilterParams(state), page, page_size: pageSize }
  return useQuery({
    queryKey: attendanceKeys.list(params),
    queryFn: ({ signal }) => attendanceApi.list(params, signal),
    placeholderData: keepPreviousData,
    ...LIVE_REFRESH,
  })
}

// Only fetched (and polled) while the drawer is open on a row; closing it stops the polling.
export function useAttendanceDetail(selection, open) {
  return useQuery({
    queryKey: attendanceKeys.detail(selection?.employeeId, selection?.date),
    queryFn: ({ signal }) => attendanceApi.detail(selection.employeeId, selection.date, signal),
    enabled: Boolean(selection) && open,
    retry: false,
    ...LIVE_REFRESH,
  })
}

export function useAttendanceFilterOptions() {
  return useQuery({
    queryKey: attendanceKeys.options,
    queryFn: ({ signal }) => attendanceApi.filterOptions(signal),
  })
}

export function useAttendanceExport() {
  return useMutation({
    mutationFn: (state) => attendanceApi.exportCsv(buildFilterParams(state)),
  })
}

export function downloadBlob(blob, filename) {
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  link.remove()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}
