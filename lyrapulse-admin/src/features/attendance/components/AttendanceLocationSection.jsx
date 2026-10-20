import { Suspense, lazy, useMemo } from 'react'
import { Box, Skeleton, Stack, Typography } from '@mui/material'
import { MapPinOff } from 'lucide-react'
import { formatCoordinate, hasCoordinates } from '../utils/format'

// Leaflet is only downloaded when a drawer actually shows a location.
const AttendanceMap = lazy(() => import('./AttendanceMap').then((module) => ({ default: module.AttendanceMap })))

// Marker coordinates come straight from the API: branch config, and the phone GPS stored at check-in / check-out.
function buildPoints(detail) {
  const branch = detail?.attendance_branch
  const points = []
  if (hasCoordinates(branch)) {
    points.push({ kind: 'branch', title: `Branch: ${branch.name}`, latitude: branch.latitude, longitude: branch.longitude })
  }
  if (hasCoordinates(detail?.check_in)) {
    points.push({ kind: 'checkIn', title: 'Check-in location', ...detail.check_in })
  }
  if (hasCoordinates(detail?.check_out)) {
    points.push({ kind: 'checkOut', title: 'Check-out location', ...detail.check_out })
  }
  return points
}

const LEGEND = {
  branch: { label: 'Branch', color: 'primary.main' },
  checkIn: { label: 'Check-in', color: 'success.main' },
  checkOut: { label: 'Check-out', color: 'info.main' },
}

export function AttendanceLocationSection({ detail }) {
  const points = useMemo(() => buildPoints(detail), [detail])

  return (
    <Box component="section" aria-label="Attendance location">
      <Typography variant="subtitle2" sx={{ mb: 1 }}>Location on Map</Typography>
      {points.length === 0 ? (
        <Stack sx={{ alignItems: 'center', gap: 0.75, py: 3, border: 1, borderColor: 'divider', borderRadius: 1.5, bgcolor: 'background.default', color: 'text.secondary' }}>
          <MapPinOff size={20} aria-hidden="true" />
          <Typography variant="body2">Location data unavailable</Typography>
        </Stack>
      ) : (
        <>
          <Suspense fallback={<Skeleton variant="rounded" height={240} />}>
            <AttendanceMap points={points} />
          </Suspense>
          <Stack direction="row" sx={{ gap: 2, mt: 1, flexWrap: 'wrap' }} aria-label="Map legend">
            {points.map((point) => (
              <Stack key={point.kind} direction="row" sx={{ alignItems: 'center', gap: 0.75 }}>
                <Box aria-hidden="true" sx={{ width: 10, height: 10, borderRadius: '50%', bgcolor: LEGEND[point.kind].color }} />
                <Typography variant="caption" color="text.secondary">{LEGEND[point.kind].label}</Typography>
              </Stack>
            ))}
          </Stack>
          {hasCoordinates(detail?.attendance_branch) ? (
            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 0.5 }}>
              {detail.attendance_branch.name} attendance location: {formatCoordinate(detail.attendance_branch.latitude)}, {formatCoordinate(detail.attendance_branch.longitude)}
            </Typography>
          ) : null}
        </>
      )}
    </Box>
  )
}
