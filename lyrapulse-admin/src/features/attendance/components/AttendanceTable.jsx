import { Avatar, Box, IconButton, Skeleton, Stack, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Tooltip, Typography } from '@mui/material'
import { BadgeCheck, MapPinOff, EllipsisVertical } from 'lucide-react'
import { StatusChip } from '../../../components/common/StatusChip'
import { NO_VALUE, formatDate, formatTime, initials } from '../utils/format'

const cellSx = { py: 1.25 }

function VerifiedNote({ verified }) {
  if (verified === null || verified === undefined) return null
  const Icon = verified ? BadgeCheck : MapPinOff
  return (
    <Stack direction="row" sx={{ alignItems: 'center', gap: 0.5, color: verified ? 'success.main' : 'warning.dark', mt: 0.25 }}>
      <Icon size={12} aria-hidden="true" />
      <Typography variant="caption" sx={{ lineHeight: 1.2 }}>{verified ? 'Verified' : 'Not verified'}</Typography>
    </Stack>
  )
}

function TimeCell({ time, verified }) {
  if (!time) return <Typography variant="body2" color="text.secondary">{NO_VALUE}</Typography>
  return (
    <Box>
      <Typography variant="body2" sx={{ fontWeight: 600 }}>{formatTime(time)}</Typography>
      <VerifiedNote verified={verified} />
    </Box>
  )
}

function SkeletonRows({ columns }) {
  return Array.from({ length: 6 }, (_, row) => (
    <TableRow key={row}>
      {Array.from({ length: columns }, (_cell, cell) => (
        <TableCell key={cell} sx={cellSx}><Skeleton variant="text" width={cell === 0 ? 140 : 70} /></TableCell>
      ))}
    </TableRow>
  ))
}

export function AttendanceTable({ rows, loading, showDate, onOpen }) {
  const columnCount = showDate ? 10 : 9

  return (
    <TableContainer sx={{ border: 0, borderRadius: 0 }}>
      <Table size="small" sx={{ minWidth: 900 }} aria-label="Attendance records">
        <TableHead>
          <TableRow>
            <TableCell>Employee</TableCell>
            {showDate ? <TableCell>Date</TableCell> : null}
            <TableCell>Branch</TableCell>
            <TableCell>Department</TableCell>
            <TableCell>Designation</TableCell>
            <TableCell>Check In</TableCell>
            <TableCell>Check Out</TableCell>
            <TableCell>Working Hours</TableCell>
            <TableCell>Status</TableCell>
            <TableCell align="right">Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {loading ? <SkeletonRows columns={columnCount} /> : rows.map((row) => {
            const { employee } = row
            return (
              <TableRow
                key={`${employee.id}-${row.attendance_date}`} hover onClick={() => onOpen(row)}
                sx={{ cursor: 'pointer' }}
              >
                <TableCell sx={cellSx}>
                  <Stack direction="row" sx={{ alignItems: 'center', gap: 1.25 }}>
                    <Avatar src={employee.profile_photo ?? undefined} alt="" sx={{ width: 34, height: 34 }}>{initials(employee.name)}</Avatar>
                    <Box sx={{ minWidth: 0 }}>
                      <Typography variant="body2" sx={{ fontWeight: 600, lineHeight: 1.3 }} noWrap>{employee.name}</Typography>
                      <Typography variant="caption" color="text.secondary">{employee.employee_code}</Typography>
                    </Box>
                  </Stack>
                </TableCell>
                {showDate ? <TableCell sx={{ ...cellSx, whiteSpace: 'nowrap' }}>{formatDate(row.attendance_date)}</TableCell> : null}
                <TableCell sx={cellSx}>{row.branch?.name ?? NO_VALUE}</TableCell>
                <TableCell sx={cellSx}>{row.department?.name ?? NO_VALUE}</TableCell>
                <TableCell sx={cellSx}>{row.designation?.name ?? NO_VALUE}</TableCell>
                <TableCell sx={cellSx}><TimeCell time={row.check_in_at} verified={row.check_in_location_verified} /></TableCell>
                <TableCell sx={cellSx}><TimeCell time={row.check_out_at} verified={row.has_check_out ? row.check_out_location_verified : null} /></TableCell>
                <TableCell sx={cellSx}>{row.working_hours_display ?? NO_VALUE}</TableCell>
                <TableCell sx={cellSx}><StatusChip label={row.status === 'PRESENT' ? 'Present' : 'Absent'} /></TableCell>
                <TableCell sx={cellSx} align="right">
                  <Tooltip title="View attendance details">
                    <IconButton
                      size="small" aria-label={`View attendance details for ${employee.name} on ${formatDate(row.attendance_date)}`}
                      onClick={(event) => { event.stopPropagation(); onOpen(row) }}
                    >
                      <EllipsisVertical size={18} aria-hidden="true" />
                    </IconButton>
                  </Tooltip>
                </TableCell>
              </TableRow>
            )
          })}
        </TableBody>
      </Table>
    </TableContainer>
  )
}
