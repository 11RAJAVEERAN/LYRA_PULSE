import { parseIsoDate } from './dateRange'

const timeFormat = new Intl.DateTimeFormat('en-US', { hour: '2-digit', minute: '2-digit', hour12: true })
const shortDateFormat = new Intl.DateTimeFormat('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
const longDateFormat = new Intl.DateTimeFormat('en-GB', { weekday: 'short', day: '2-digit', month: 'short', year: 'numeric' })

export const NO_VALUE = '—'

// Backend timestamps are timezone-aware ISO-8601, so the browser formats them directly.
export function formatTime(iso) {
  if (!iso) return NO_VALUE
  const date = new Date(iso)
  return Number.isNaN(date.getTime()) ? NO_VALUE : timeFormat.format(date)
}

export const formatDate = (isoDate) => (isoDate ? shortDateFormat.format(parseIsoDate(isoDate)) : NO_VALUE)
export const formatLongDate = (isoDate) => (isoDate ? longDateFormat.format(parseIsoDate(isoDate)) : NO_VALUE)

export function formatDistance(meters) {
  if (meters === null || meters === undefined || Number.isNaN(Number(meters))) return NO_VALUE
  const value = Number(meters)
  return value >= 1000 ? `${(value / 1000).toFixed(2)} km` : `${Math.round(value * 10) / 10} m`
}

export const formatAccuracy = (meters) => (meters === null || meters === undefined ? NO_VALUE : `${Math.round(Number(meters) * 10) / 10} m`)

export const formatCoordinate = (value) => (Number.isFinite(value) ? value.toFixed(6) : NO_VALUE)

export const hasCoordinates = (point) =>
  Boolean(point) && Number.isFinite(point.latitude) && Number.isFinite(point.longitude)
  && Math.abs(point.latitude) <= 90 && Math.abs(point.longitude) <= 180

export function initials(name) {
  const parts = String(name ?? '').trim().split(/\s+/).filter(Boolean)
  return (parts[0]?.[0] ?? '?').concat(parts.length > 1 ? parts[parts.length - 1][0] : '').toUpperCase()
}
