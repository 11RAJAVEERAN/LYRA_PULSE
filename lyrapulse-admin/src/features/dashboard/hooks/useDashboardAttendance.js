import { useMemo } from 'react'
import { useQueries } from '@tanstack/react-query'
import { attendanceApi } from '../../attendance/api/attendanceApi'
import { attendanceKeys, useTodayAttendanceSummary } from '../../attendance/hooks/useAttendanceQueries'
import { addDays, parseIsoDate } from '../../attendance/utils/dateRange'

const TREND_DAYS = 7
const weekdayFormat = new Intl.DateTimeFormat('en-US', { weekday: 'short' })

// Real Dashboard attendance data, all from the existing Attendance Admin summary API (the source of truth).
//  - `today`: live counts, silently refetched every 5 seconds (see useTodayAttendanceSummary).
//  - `trend`: one single-date summary per day for the last 7 days, so each point is exactly what the Attendance
//    page shows for that day. The 6 earlier days are fixed history: fetched once, never polled. The dates are
//    anchored to the server's "today" (returned by the API) so the browser's timezone can never request a future date.
export function useDashboardAttendance() {
  const today = useTodayAttendanceSummary()
  const todayDate = today.data?.date

  const pastDays = useMemo(
    () => (todayDate ? Array.from({ length: TREND_DAYS - 1 }, (_, index) => addDays(todayDate, index - (TREND_DAYS - 1))) : []),
    [todayDate],
  )

  // `combine` output is structurally shared, so it keeps the same identity until a value really changes.
  const past = useQueries({
    queries: pastDays.map((date) => {
      const params = { date }
      return { queryKey: attendanceKeys.summary(params), queryFn: ({ signal }) => attendanceApi.summary(params, signal) }
    }),
    combine: (results) => ({ data: results.map((result) => result.data), failed: results.some((result) => result.isError) }),
  })

  const trend = useMemo(() => {
    if (!today.data || pastDays.length === 0 || past.data.some((summary) => !summary)) return undefined
    const rows = pastDays.map((date, index) => ({ date, ...past.data[index] }))
    return [...rows, today.data].map(({ date, present, absent }) => ({ day: weekdayFormat.format(parseIsoDate(date)), present, absent }))
  }, [today.data, pastDays, past.data])

  const trendFailed = past.failed || (today.isError && !today.data)

  return { today, trend, trendLoading: !trend && !trendFailed }
}
