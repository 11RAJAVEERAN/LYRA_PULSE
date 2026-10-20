// Local-date helpers for the Attendance filters. Dates are plain YYYY-MM-DD strings (the backend's format).
// The backend rejects future dates and ranges longer than 92 days, so the limits are mirrored here for UX only;
// the backend remains the authority.
export const MAX_RANGE_DAYS = 92

export const PERIODS = [
  { id: 'today', label: 'Today' },
  { id: 'week', label: 'This Week' },
  { id: 'month', label: 'This Month' },
  { id: 'custom', label: 'Custom' },
]

const pad = (value) => String(value).padStart(2, '0')

export function toIsoDate(date) {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

export function parseIsoDate(iso) {
  const [year, month, day] = String(iso).split('-').map(Number)
  return new Date(year, month - 1, day)
}

export function addDays(iso, days) {
  const date = parseIsoDate(iso)
  date.setDate(date.getDate() + days)
  return toIsoDate(date)
}

export function daysInclusive(start, end) {
  return Math.round((parseIsoDate(end) - parseIsoDate(start)) / 86400000) + 1
}

export const todayIso = () => toIsoDate(new Date())

// Weeks run Monday-Sunday. The end is capped at today because the backend rejects future dates.
export function getPeriodRange(period, now = new Date()) {
  const today = toIsoDate(now)
  if (period === 'week') {
    const mondayOffset = (now.getDay() + 6) % 7
    const monday = addDays(today, -mondayOffset)
    const sunday = addDays(monday, 6)
    return { start: monday, end: sunday > today ? today : sunday }
  }
  if (period === 'month') {
    return { start: toIsoDate(new Date(now.getFullYear(), now.getMonth(), 1)), end: today }
  }
  return { start: today, end: today }
}

// Returns an error message, or '' when the custom range is acceptable.
export function validateCustomRange(start, end) {
  if (!start || !end) return 'Select both a start and an end date.'
  if (start > end) return 'The start date must be on or before the end date.'
  if (end > todayIso()) return 'Future dates cannot be selected.'
  if (daysInclusive(start, end) > MAX_RANGE_DAYS) return `The range cannot exceed ${MAX_RANGE_DAYS} days.`
  return ''
}
