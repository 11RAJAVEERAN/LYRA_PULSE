import { keepPreviousData, useQuery } from '@tanstack/react-query'
import {
  Avatar, Box, ButtonBase, Card, CardContent, Grid, Skeleton, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Typography, alpha,
} from '@mui/material'
import { Activity, CalendarCheck2, ChevronRight, Clock3, FileText, Inbox, UserPlus, Users } from 'lucide-react'
import { Link } from 'react-router-dom'
import { AttendanceChart } from '../../../components/charts/AttendanceChart'
import { ErrorState } from '../../../components/common/ErrorState'
import { PageHeader } from '../../../components/common/PageHeader'
import { StatusChip } from '../../../components/common/StatusChip'
import { authService } from '../../../services/authService'
import { attendanceApi } from '../../attendance/api/attendanceApi'
import { ATTENDANCE_REFRESH_MS, attendanceKeys } from '../../attendance/hooks/useAttendanceQueries'
import { attendanceErrorMessage } from '../../attendance/utils/errors'
import { NO_VALUE, formatDate, formatTime, initials } from '../../attendance/utils/format'
import { StatsCard } from '../components/StatsCard'
import { useDashboardAttendance } from '../hooks/useDashboardAttendance'

const UNAVAILABLE = '—'
const RECENT_ATTENDANCE_LIMIT = 5

// Shared spacing for every Dashboard row and card.
const GRID_SPACING = 2.5

function SectionCard({ title, action, children }) {
  return (
    <Card sx={{ height: '100%' }}>
      <CardContent sx={{ p: 2.5, '&:last-child': { pb: 2.5 }, height: '100%', display: 'flex', flexDirection: 'column', boxSizing: 'border-box' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 2, mb: 2, minHeight: 24 }}>
          <Typography variant="h6" component="h2">
            {title}
          </Typography>
          {action}
        </Box>
        {children}
      </CardContent>
    </Card>
  )
}

// Light, centred placeholder used when a section has nothing to show (or no data source yet).
function CompactEmpty({ icon: Icon, title, description }) {
  return (
    <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 0.75, py: 3, px: 2, textAlign: 'center' }}>
      <Box
        aria-hidden="true"
        sx={{ display: 'grid', placeItems: 'center', width: 40, height: 40, borderRadius: 1, backgroundColor: 'action.hover', color: 'text.secondary', mb: 0.5 }}
      >
        <Icon size={20} />
      </Box>
      <Typography variant="body2" sx={{ fontWeight: 600 }}>
        {title}
      </Typography>
      <Typography variant="caption" color="text.secondary" sx={{ maxWidth: 320 }}>
        {description}
      </Typography>
    </Box>
  )
}

function QuickAction({ label, description, icon: Icon, to, disabledReason }) {
  const disabled = Boolean(disabledReason)

  return (
    <ButtonBase
      {...(disabled ? { disabled: true } : { component: Link, to })}
      sx={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        width: '100%',
        px: 1.5,
        py: 1.25,
        borderRadius: 1,
        border: 1,
        borderColor: 'divider',
        backgroundColor: 'background.paper',
        textAlign: 'left',
        color: 'text.primary',
        transition: 'background-color 150ms ease, border-color 150ms ease',
        '&:hover': { backgroundColor: 'action.hover' },
        '&.Mui-focusVisible': { outline: 2, outlineStyle: 'solid', outlineColor: 'info.main', outlineOffset: 2 },
        '&.Mui-disabled': { backgroundColor: 'transparent' },
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, minWidth: 0 }}>
        <Box
          aria-hidden="true"
          sx={(theme) => ({
            display: 'grid',
            placeItems: 'center',
            width: 36,
            height: 36,
            flexShrink: 0,
            borderRadius: 1,
            backgroundColor: disabled ? theme.palette.action.hover : alpha(theme.palette.info.main, 0.1),
            color: disabled ? theme.palette.text.disabled : theme.palette.info.main,
          })}
        >
          <Icon size={18} />
        </Box>
        <Box sx={{ minWidth: 0 }}>
          <Typography variant="body2" sx={{ fontWeight: 600, color: disabled ? 'text.secondary' : 'text.primary' }} noWrap>
            {label}
          </Typography>
          <Typography variant="caption" color={disabled ? 'text.disabled' : 'text.secondary'} sx={{ display: 'block' }} noWrap>
            {disabled ? disabledReason : description}
          </Typography>
        </Box>
      </Box>
      {disabled ? null : <ChevronRight size={16} aria-hidden="true" style={{ flexShrink: 0 }} />}
    </ButtonBase>
  )
}

function RecentAttendanceTable({ rows }) {
  return (
    <TableContainer sx={{ border: 0, borderRadius: 0 }}>
      <Table size="small" sx={{ minWidth: 440 }} aria-label="Recent attendance">
        <TableHead>
          <TableRow>
            <TableCell>Employee</TableCell>
            <TableCell>Check-in</TableCell>
            <TableCell>Check-out</TableCell>
            <TableCell>Status</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {rows.map((row) => {
            const { employee } = row
            return (
              <TableRow key={`${employee.id}-${row.attendance_date}`}>
                <TableCell sx={{ py: 1.25 }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.25, minWidth: 0 }}>
                    <Avatar src={employee.profile_photo ?? undefined} alt="" sx={{ width: 32, height: 32, fontSize: 12 }}>
                      {initials(employee.name)}
                    </Avatar>
                    <Typography variant="body2" sx={{ fontWeight: 500 }} noWrap>
                      {employee.name}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell sx={{ py: 1.25, whiteSpace: 'nowrap' }}>
                  <Typography variant="body2">{formatTime(row.check_in_at)}</Typography>
                </TableCell>
                <TableCell sx={{ py: 1.25, whiteSpace: 'nowrap' }}>
                  <Typography variant="body2" color={row.check_out_at ? 'text.primary' : 'text.secondary'}>
                    {row.check_out_at ? formatTime(row.check_out_at) : NO_VALUE}
                  </Typography>
                </TableCell>
                <TableCell sx={{ py: 1.25 }}>
                  <StatusChip label={row.status === 'PRESENT' ? 'Present' : 'Absent'} />
                </TableCell>
              </TableRow>
            )
          })}
        </TableBody>
      </Table>
    </TableContainer>
  )
}

function RecentAttendanceSkeleton() {
  return (
    <Box aria-label="Loading recent attendance" sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
      {Array.from({ length: RECENT_ATTENDANCE_LIMIT }, (_, index) => (
        <Skeleton key={index} variant="rounded" height={36} />
      ))}
    </Box>
  )
}

export function DashboardPage() {
  // Real attendance data from the Attendance Admin summary API; `today` refetches silently every 5 seconds and the
  // existing figures stay on screen while it does. Only the first load shows the skeletons.
  const { today, trend, trendLoading } = useDashboardAttendance()
  const summary = today.data

  // Latest check-ins for the server's "today" (taken from the summary response), newest first. Same endpoint,
  // service and polling cadence as the Attendance page; it only starts once the summary has returned its date.
  const recent = useQuery({
    queryKey: attendanceKeys.list({ date: summary?.date, status: 'present', ordering: '-check_in', page: 1, page_size: RECENT_ATTENDANCE_LIMIT }),
    queryFn: ({ signal }) =>
      attendanceApi.list({ date: summary.date, status: 'present', ordering: '-check_in', page: 1, page_size: RECENT_ATTENDANCE_LIMIT }, signal),
    enabled: Boolean(summary?.date),
    placeholderData: keepPreviousData,
    refetchInterval: ATTENDANCE_REFRESH_MS,
    refetchOnWindowFocus: true,
    staleTime: 0,
  })
  const recentRows = recent.data?.results ?? []

  const sessionUser = authService.getCurrentUser()
  const can = (codename) => sessionUser?.role === 'SUPERADMIN' || Boolean(sessionUser?.permissions?.includes(codename))

  const quickActions = [
    {
      label: 'Add Employee',
      description: 'Create a new employee profile',
      icon: UserPlus,
      to: '/employees',
      disabledReason: can('employees.add_employee') ? undefined : 'You do not have permission to add employees',
    },
    { label: 'Review Attendance', description: "Check today's attendance", icon: CalendarCheck2, to: '/attendance' },
    { label: 'Approve Leave', description: 'Review pending leave requests', icon: Clock3, disabledReason: 'Coming soon' },
    { label: 'Generate Report', description: 'Create attendance report', icon: FileText, disabledReason: 'Coming soon' },
  ]

  const totalSubtitle = (() => {
    if (summary) return formatDate(summary.date)
    return today.isError ? 'Unavailable right now' : 'Loading attendance data'
  })()

  const recentLoading = recent.isPending && !today.isError

  return (
    <Box>
      
      {today.isError && !summary ? <ErrorState message={attendanceErrorMessage(today.error)} onRetry={() => today.refetch()} retrying={today.isFetching} /> : null}

      <Grid container spacing={GRID_SPACING} sx={{ mb: GRID_SPACING }}>
        <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
          <StatsCard
            title="Total Employees"
            value={summary ? summary.total_employees : UNAVAILABLE}
            subtitle={totalSubtitle}
            icon={<Users size={18} />}
            tone="info"
            loading={today.isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
          <StatsCard
            title="Present Today"
            value={summary ? summary.present : UNAVAILABLE}
            subtitle="Checked in"
            icon={<Activity size={18} />}
            tone="success"
            loading={today.isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
          <StatsCard
            title="Absent Today"
            value={summary ? summary.absent : UNAVAILABLE}
            subtitle="No check-in recorded"
            icon={<Clock3 size={18} />}
            tone="error"
            loading={today.isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
          <StatsCard
            title="On Leave"
            value={UNAVAILABLE}
            subtitle="Leave data unavailable"
            icon={<CalendarCheck2 size={18} />}
            tone="secondary"
          />
        </Grid>
      </Grid>

      <Grid container spacing={GRID_SPACING} sx={{ mb: GRID_SPACING }}>
        <Grid size={{ xs: 12, lg: 8 }}>
          <SectionCard
            title="Attendance Overview"
            action={
              <Typography variant="caption" color="text.secondary">
                Last 7 days
              </Typography>
            }
          >
            {trend ? (
              <AttendanceChart data={trend} />
            ) : trendLoading ? (
              <Skeleton variant="rounded" height={280} aria-label="Loading attendance overview" />
            ) : (
              <CompactEmpty
                icon={Activity}
                title="Attendance data is unavailable"
                description="The daily attendance for the last 7 days could not be loaded. Please try again."
              />
            )}
          </SectionCard>
        </Grid>

        <Grid size={{ xs: 12, lg: 4 }}>
          <SectionCard title="Leave Requests">
            <CompactEmpty
              icon={CalendarCheck2}
              title="Leave data unavailable"
              description="Leave information will appear when the feature is available."
            />
          </SectionCard>
        </Grid>
      </Grid>

      <Grid container spacing={GRID_SPACING}>
        <Grid size={{ xs: 12, lg: 7 }}>
          <SectionCard
            title="Recent Attendance"
            action={
              <Typography
                component={Link}
                to="/attendance"
                variant="caption"
                sx={{ color: 'info.main', fontWeight: 500, textDecoration: 'none', '&:hover': { textDecoration: 'underline' } }}
              >
                View all
              </Typography>
            }
          >
            {recentLoading ? (
              <RecentAttendanceSkeleton />
            ) : recent.isError && !recent.data ? (
              <ErrorState message={attendanceErrorMessage(recent.error)} onRetry={() => recent.refetch()} retrying={recent.isFetching} />
            ) : recentRows.length > 0 ? (
              <RecentAttendanceTable rows={recentRows} />
            ) : (
              <CompactEmpty
                icon={Inbox}
                title="No attendance activity to show"
                description="Recent attendance activity will appear here."
              />
            )}
          </SectionCard>
        </Grid>

        <Grid size={{ xs: 12, lg: 5 }}>
          <SectionCard title="Quick Actions">
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.25 }}>
              {quickActions.map((action) => (
                <QuickAction key={action.label} {...action} />
              ))}
            </Box>
          </SectionCard>
        </Grid>
      </Grid>
    </Box>
  )
}
