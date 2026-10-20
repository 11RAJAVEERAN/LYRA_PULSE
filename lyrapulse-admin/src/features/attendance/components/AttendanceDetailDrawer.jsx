import { useState } from 'react'
import { Avatar, Box, ButtonBase, Dialog, DialogContent, DialogTitle, Divider, Drawer, IconButton, Skeleton, Stack, Typography } from '@mui/material'
import { BadgeCheck, Clock, ImageOff, MapPinOff, Maximize2, X } from 'lucide-react'
import { ErrorState } from '../../../components/common/ErrorState'
import { StatusChip } from '../../../components/common/StatusChip'
import { useAttendanceDetail } from '../hooks/useAttendanceQueries'
import { attendanceErrorMessage } from '../utils/errors'
import { todayIso } from '../utils/dateRange'
import { NO_VALUE, formatAccuracy, formatCoordinate, formatDistance, formatLongDate, formatTime, initials } from '../utils/format'
import { AttendanceLocationSection } from './AttendanceLocationSection'

function VerificationLine({ verified }) {
  if (verified === null || verified === undefined) return null
  const Icon = verified ? BadgeCheck : MapPinOff
  return (
    <Stack direction="row" sx={{ alignItems: 'center', gap: 0.5, color: verified ? 'success.main' : 'warning.dark' }}>
      <Icon size={14} aria-hidden="true" />
      <Typography variant="caption" sx={{ fontWeight: 600 }}>{verified ? 'Verified' : 'Not verified'}</Typography>
    </Stack>
  )
}

function CheckCard({ title, data, emptyLabel }) {
  return (
    <Box sx={{ flex: 1, minWidth: 0, p: 1.5, border: 1, borderColor: 'divider', borderRadius: 1.5 }}>
      <Typography variant="caption" color="text.secondary">{title}</Typography>
      {data ? (
        <>
          <Typography variant="h6" component="p" sx={{ color: 'success.dark', lineHeight: 1.3 }}>{formatTime(data.time)}</Typography>
          <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>{formatDistance(data.distance_from_branch_m)} from branch</Typography>
          <VerificationLine verified={data.location_verified} />
        </>
      ) : (
        <Typography variant="body2" color="text.secondary" sx={{ mt: 0.75 }}>{emptyLabel}</Typography>
      )}
    </Box>
  )
}

function PhotoCard({ title, data, emptyLabel, onPreview }) {
  const [failed, setFailed] = useState(false)
  const src = data?.photo

  return (
    <Box component="section" aria-label={title}>
      <Typography variant="subtitle2" sx={{ mb: 1 }}>{title}</Typography>
      {!data ? (
        <Typography variant="body2" color="text.secondary">{emptyLabel}</Typography>
      ) : (
        <Stack direction="row" sx={{ gap: 1.5, p: 1, border: 1, borderColor: 'divider', borderRadius: 1.5 }}>
          {src && !failed ? (
            <ButtonBase
              onClick={() => onPreview({ src, title })} aria-label={`View ${title.toLowerCase()} larger`}
              sx={{ position: 'relative', width: 96, height: 96, flexShrink: 0, borderRadius: 1, overflow: 'hidden' }}
            >
              <Box component="img" src={src} alt={`${title} proof`} loading="lazy" onError={() => setFailed(true)} sx={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              <Box aria-hidden="true" sx={{ position: 'absolute', right: 4, bottom: 4, display: 'grid', placeItems: 'center', width: 22, height: 22, borderRadius: 0.75, bgcolor: 'background.paper', color: 'text.primary' }}>
                <Maximize2 size={12} />
              </Box>
            </ButtonBase>
          ) : (
            <Stack sx={{ width: 96, height: 96, flexShrink: 0, alignItems: 'center', justifyContent: 'center', gap: 0.5, borderRadius: 1, bgcolor: 'background.default', color: 'text.secondary' }}>
              <ImageOff size={20} aria-hidden="true" />
              <Typography variant="caption">{src ? 'Photo unavailable' : 'No photo'}</Typography>
            </Stack>
          )}
          <Stack sx={{ justifyContent: 'center', gap: 0.25, minWidth: 0 }}>
            <Typography variant="caption">Lat: {formatCoordinate(data.latitude)}</Typography>
            <Typography variant="caption">Long: {formatCoordinate(data.longitude)}</Typography>
            <Typography variant="caption">Accuracy: {formatAccuracy(data.accuracy_m)}</Typography>
            <Typography variant="caption">Time: {formatTime(data.time)}</Typography>
          </Stack>
        </Stack>
      )}
    </Box>
  )
}

export function AttendanceDetailDrawer({ open, selection, onClose }) {
  const [preview, setPreview] = useState(null)
  const query = useAttendanceDetail(selection, open)
  const detail = query.data
  const row = selection?.row
  const employee = detail?.employee ?? row?.employee
  const status = detail?.status ?? row?.status
  const isToday = selection?.date === todayIso()

  return (
    <>
      <Drawer
        anchor="right" open={open} onClose={onClose}
        slotProps={{ paper: { sx: { width: { xs: '100%', sm: 440 }, maxWidth: '100%', bgcolor: 'background.paper', color: 'text.primary', borderLeft: 1, borderColor: 'divider' }, 'aria-label': 'Attendance details' } }}
      >
        <Stack direction="row" sx={{ alignItems: 'center', gap: 1.5, p: 2.5, borderBottom: 1, borderColor: 'divider' }}>
          <Avatar src={employee?.profile_photo ?? undefined} alt="" sx={{ width: 52, height: 52 }}>{initials(employee?.name)}</Avatar>
          <Box sx={{ flex: 1, minWidth: 0 }}>
            <Typography variant="h6" component="h2" noWrap>{employee?.name ?? NO_VALUE}</Typography>
            <Typography variant="body2" color="text.secondary">{employee?.employee_code}</Typography>
            {status ? <Box sx={{ mt: 0.5 }}><StatusChip label={status === 'PRESENT' ? 'Present' : 'Absent'} /></Box> : null}
          </Box>
          <IconButton onClick={onClose} aria-label="Close attendance details"><X size={20} aria-hidden="true" /></IconButton>
        </Stack>

        <Box sx={{ flex: 1, overflowY: 'auto', p: 2.5 }}>
          {query.isError && !detail ? (
            <ErrorState message={attendanceErrorMessage(query.error)} onRetry={() => query.refetch()} retrying={query.isFetching} />
          ) : query.isLoading ? (
            <Stack sx={{ gap: 2 }} aria-busy="true">
              <Skeleton variant="text" width={180} />
              <Stack direction="row" sx={{ gap: 1.5 }}><Skeleton variant="rounded" height={92} sx={{ flex: 1 }} /><Skeleton variant="rounded" height={92} sx={{ flex: 1 }} /></Stack>
              <Skeleton variant="rounded" height={96} />
              <Skeleton variant="rounded" height={240} />
            </Stack>
          ) : detail ? (
            <Stack sx={{ gap: 2.5 }}>
              <Stack direction="row" sx={{ justifyContent: 'space-between', alignItems: 'baseline' }}>
                <Typography variant="subtitle1" component="h3">{isToday ? "Today's Attendance" : 'Attendance Details'}</Typography>
                <Typography variant="body2" color="text.secondary">{formatLongDate(detail.attendance_date)}</Typography>
              </Stack>

              {!detail.check_in ? (
                <Box sx={{ py: 4, textAlign: 'center', border: 1, borderStyle: 'dashed', borderColor: 'divider', borderRadius: 1.5 }}>
                  <Typography variant="subtitle2">Absent</Typography>
                  <Typography variant="body2" color="text.secondary">No attendance record for this date.</Typography>
                </Box>
              ) : (
                <>
                  <Stack direction="row" sx={{ gap: 1.5 }}>
                    <CheckCard title="Check In" data={detail.check_in} />
                    <CheckCard title="Check Out" data={detail.check_out} emptyLabel="Not checked out" />
                  </Stack>

                  <Stack direction="row" sx={{ alignItems: 'center', justifyContent: 'space-between', px: 1.5, py: 1, borderRadius: 1.5, bgcolor: 'background.default' }}>
                    <Stack direction="row" sx={{ alignItems: 'center', gap: 0.75, color: 'text.secondary' }}>
                      <Clock size={15} aria-hidden="true" />
                      <Typography variant="body2">Working Hours</Typography>
                    </Stack>
                    <Typography variant="subtitle2">{detail.working_hours_display ?? NO_VALUE}</Typography>
                  </Stack>

                  <PhotoCard key={`in-${detail.employee.id}-${detail.attendance_date}`} title="Check In Photo" data={detail.check_in} onPreview={setPreview} />
                  <PhotoCard key={`out-${detail.employee.id}-${detail.attendance_date}`} title="Check Out Photo" data={detail.check_out} emptyLabel="No check-out photo" onPreview={setPreview} />
                  <Divider />
                  <AttendanceLocationSection detail={detail} />
                </>
              )}
            </Stack>
          ) : null}
        </Box>
      </Drawer>

      <Dialog open={Boolean(preview)} onClose={() => setPreview(null)} maxWidth="md" fullWidth>
        <DialogTitle sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          {preview?.title}
          <IconButton onClick={() => setPreview(null)} aria-label="Close photo preview"><X size={18} aria-hidden="true" /></IconButton>
        </DialogTitle>
        <DialogContent>
          {preview ? <Box component="img" src={preview.src} alt={`${preview.title} proof`} sx={{ display: 'block', width: '100%', maxHeight: '75vh', objectFit: 'contain' }} /> : null}
        </DialogContent>
      </Dialog>
    </>
  )
}
