import { keepPreviousData, useQuery } from '@tanstack/react-query'
import {
  Avatar, Box, ButtonBase, Card, CardContent, Divider, Grid, Skeleton, Typography, alpha, useTheme,
} from '@mui/material'
import { Activity, CalendarCheck2, ChevronRight, Clock3, FileText, Inbox, Percent, UserCheck, UserPlus, UserX, Users } from 'lucide-react'
import { Bar, BarChart, CartesianGrid, Cell, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { Link } from 'react-router-dom'
import { ErrorState } from '../../../components/common/ErrorState'
import { PageHeader } from '../../../components/common/PageHeader'
import { StatusChip } from '../../../components/common/StatusChip'
import { authService } from '../../../services/authService'
import { attendanceApi } from '../../attendance/api/attendanceApi'
import { ATTENDANCE_REFRESH_MS, attendanceKeys } from '../../attendance/hooks/useAttendanceQueries'
import { attendanceErrorMessage } from '../../attendance/utils/errors'
import { NO_VALUE, formatDate, formatTime, initials } from '../../attendance/utils/format'
import { useDashboardAttendance } from '../hooks/useDashboardAttendance'

const UNAVAILABLE = '—'
const RECENT_ATTENDANCE_LIMIT = 5

// Shared spacing for every Dashboard row and card.
const GRID_SPACING = 2

function SectionCard({ title, action, children }) {
  return (
    <Card sx={{ height: '100%' }}>
      <CardContent sx={{ p: 2, '&:last-child': { pb: 2 }, height: '100%', display: 'flex', flexDirection: 'column', boxSizing: 'border-box' }}>
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

function DashboardKpi({ title, value, subtitle, icon: Icon, tone = 'info', loading = false, progress }) {
  const theme = useTheme()
  const color = theme.palette[tone] ?? theme.palette.info
  const isWarning = tone === 'warning'

  return (
    <Card
      variant="outlined"
      sx={{
        height: '100%',
        borderColor: 'divider',
        boxShadow: theme.shadows[1],
        transition: 'box-shadow 150ms ease, border-color 150ms ease',
        '&:hover': { borderColor: 'action.disabled', boxShadow: theme.shadows[2] },
      }}
    >
      <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 1.5 }}>
          <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 500 }}>{title}</Typography>
          <Box aria-hidden="true" sx={{ display: 'grid', placeItems: 'center', width: 32, height: 32, flexShrink: 0, borderRadius: 1, bgcolor: isWarning ? color.light : alpha(color.main, 0.08), color: isWarning ? color.dark : color.main }}>
            <Icon size={17} />
          </Box>
        </Box>
        {loading ? (
          <Skeleton variant="text" width={72} sx={{ fontSize: 28, mt: 0.5 }} aria-label={`Loading ${title}`} />
        ) : (
          <Typography sx={{ mt: 0.5, color: 'text.primary', fontSize: 28, lineHeight: 1.2, fontWeight: 700, letterSpacing: '-0.02em', fontVariantNumeric: 'tabular-nums' }}>
            {value}
          </Typography>
        )}
        {progress != null && !loading ? (
          <Box sx={{ mt: 1, height: 4, borderRadius: 2, bgcolor: 'action.hover', overflow: 'hidden' }}>
            <Box sx={{ width: `${progress}%`, height: '100%', bgcolor: color.main, borderRadius: 2, transition: 'width 180ms ease' }} />
          </Box>
        ) : null}
        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: progress != null && !loading ? 0.75 : 1 }} noWrap>
          {subtitle}
        </Typography>
      </CardContent>
    </Card>
  )
}

function AttendanceOverview({ summary, loading }) {
  const theme = useTheme()
  const total = Number(summary?.total_employees)
  const present = Number(summary?.present)
  const absent = Number(summary?.absent)
  const valid = summary && Number.isFinite(total) && Number.isFinite(present) && Number.isFinite(absent) && total > 0
  const rate = valid ? Math.round((present / total) * 100) : null
  const data = valid ? [{ name: 'Present', value: present }, { name: 'Absent', value: absent }] : []
  const presentColor = theme.palette.success.main
  const absentColor = theme.palette.warning.main

  if (loading) return <Skeleton variant="rounded" height={204} aria-label="Loading today’s attendance" />
  if (!summary) {
    return <CompactEmpty icon={Activity} title="Attendance data is unavailable" description="Today’s attendance summary could not be loaded. Please try again." />
  }
  if (!valid) {
    return <CompactEmpty icon={Users} title="No employees in this scope" description="Attendance distribution will appear when employee data is available." />
  }

  return (
    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: { xs: 1, sm: 3 }, flexDirection: { xs: 'column', sm: 'row' }, flex: 1, minWidth: 0 }}>
      <Box sx={{ width: 160, height: 160, position: 'relative', flexShrink: 0 }} aria-label={`${rate}% present out of ${total} employees`}>
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie data={[{ name: 'Attendance', value: total }]} dataKey="value" cx="50%" cy="50%" innerRadius={49} outerRadius={63} fill={theme.palette.divider} isAnimationActive={false} />
            <Pie data={data} dataKey="value" nameKey="name" cx="50%" cy="50%" innerRadius={50} outerRadius={62} paddingAngle={2} stroke={theme.palette.background.paper} strokeWidth={1}>
              <Cell key="present" fill={presentColor} />
              <Cell key="absent" fill={absentColor} />
            </Pie>
            <Tooltip
              formatter={(value, name) => [value, name]}
              contentStyle={{ backgroundColor: theme.palette.background.paper, border: `1px solid ${theme.palette.divider}`, borderRadius: theme.shape.borderRadius, boxShadow: theme.shadows[2], fontSize: 12 }}
            />
          </PieChart>
        </ResponsiveContainer>
        <Box sx={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', pointerEvents: 'none' }}>
          <Typography sx={{ fontSize: 25, lineHeight: 1.15, fontWeight: 700, color: 'info.main', fontVariantNumeric: 'tabular-nums' }}>{rate}%</Typography>
          <Typography variant="caption" color="text.secondary">present</Typography>
        </Box>
      </Box>
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: 'repeat(3, minmax(0, 1fr))', sm: '1fr' }, gap: { xs: 1, sm: 1.5 }, width: { xs: '100%', sm: 'auto' }, minWidth: 0 }}>
        {[
          { label: 'Present', value: present, color: 'success.main' },
          { label: 'Absent', value: absent, color: 'warning.dark' },
          { label: 'Employees', value: total, color: 'text.primary' },
        ].map((item) => (
          <Box key={item.label} sx={{ minWidth: 0 }}>
            <Typography sx={{ fontSize: 20, lineHeight: 1.25, fontWeight: 650, color: item.color, fontVariantNumeric: 'tabular-nums' }}>{item.value}</Typography>
            <Typography variant="caption" color="text.secondary" noWrap>{item.label}</Typography>
          </Box>
        ))}
      </Box>
    </Box>
  )
}

function WeeklyAttendanceChart({ data }) {
  const theme = useTheme()
  const presentColor = theme.palette.success.main
  const absentColor = theme.palette.warning.main
  const tooltipStyle = { backgroundColor: theme.palette.background.paper, border: `1px solid ${theme.palette.divider}`, borderRadius: theme.shape.borderRadius, boxShadow: theme.shadows[2], padding: '8px 12px' }

  return (
    <Box sx={{ width: '100%', minWidth: 0 }}>
      <Box sx={{ width: '100%', height: 190, minWidth: 0 }}>
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={data} margin={{ top: 8, right: 8, bottom: 0, left: -18 }} barGap={5}>
            <CartesianGrid vertical={false} stroke={theme.palette.divider} strokeDasharray="3 5" />
            <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fill: theme.palette.text.secondary, fontSize: 12 }} dy={8} />
            <YAxis axisLine={false} tickLine={false} tick={{ fill: theme.palette.text.secondary, fontSize: 11 }} width={30} allowDecimals={false} />
            <Tooltip
              cursor={{ fill: alpha(theme.palette.info.main, 0.05) }}
              contentStyle={tooltipStyle}
              labelStyle={{ color: theme.palette.text.primary, fontSize: 12, fontWeight: 600, marginBottom: 4 }}
              itemStyle={{ fontSize: 12, padding: 0 }}
              formatter={(value, name) => [value, name === 'present' ? 'Present' : 'Absent']}
            />
            <Bar dataKey="present" name="present" stackId="attendance" fill={presentColor} maxBarSize={20} />
            <Bar dataKey="absent" name="absent" stackId="attendance" fill={absentColor} radius={[4, 4, 0, 0]} maxBarSize={20} />
          </BarChart>
        </ResponsiveContainer>
      </Box>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mt: 1.25 }}>
        {[{ label: 'Present', color: presentColor }, { label: 'Absent', color: absentColor }].map((item) => (
          <Box key={item.label} sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
            <Box aria-hidden="true" sx={{ width: 8, height: 8, borderRadius: '50%', bgcolor: item.color }} />
            <Typography variant="caption" color="text.secondary">{item.label}</Typography>
          </Box>
        ))}
      </Box>
    </Box>
  )
}

// Light, centred placeholder used when a section has nothing to show (or no data source yet).
function CompactEmpty({ icon: Icon, title, description }) {
  return (
    <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 0.5, py: 2, px: 2, textAlign: 'center' }}>
      <Box
        aria-hidden="true"
        sx={{ display: 'grid', placeItems: 'center', width: 32, height: 32, borderRadius: 1, backgroundColor: 'action.hover', color: 'text.secondary', mb: 0.25 }}
      >
        <Icon size={16} />
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
        px: 1.25,
        py: 1,
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
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.25, minWidth: 0 }}>
        <Box
          aria-hidden="true"
          sx={(theme) => ({
            display: 'grid',
            placeItems: 'center',
            width: 32,
            height: 32,
            flexShrink: 0,
            borderRadius: 1,
            backgroundColor: disabled ? theme.palette.action.hover : alpha(theme.palette.info.main, 0.1),
            color: disabled ? theme.palette.text.disabled : theme.palette.info.main,
          })}
        >
          <Icon size={16} />
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

function RecentAttendanceList({ rows }) {
  return (
    <Box aria-label="Recent attendance activity" sx={{ minWidth: 0 }}>
      {rows.map((row, index) => {
        const { employee } = row
        return (
          <Box key={`${employee.id}-${row.attendance_date}`}>
            {index > 0 ? <Divider sx={{ my: 1.25 }} /> : null}
            <Box sx={{ minWidth: 0, py: 0.25 }}>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.25, minWidth: 0 }}>
                <Avatar src={employee.profile_photo ?? undefined} alt="" sx={{ width: 32, height: 32, fontSize: 12, bgcolor: 'action.selected', color: 'text.secondary' }}>
                  {initials(employee.name)}
                </Avatar>
                <Box sx={{ minWidth: 0, flex: 1 }}>
                  <Typography variant="body2" sx={{ fontWeight: 600 }} noWrap>{employee.name}</Typography>
                  {employee.employee_code ? <Typography variant="caption" color="text.secondary" noWrap>{employee.employee_code}</Typography> : null}
                </Box>
                <StatusChip label={row.status === 'PRESENT' ? 'Present' : 'Absent'} />
              </Box>
              <Box sx={{ display: 'flex', gap: 2, ml: 5.25, mt: 0.5 }}>
                <Typography variant="caption" color="text.secondary">In <Box component="span" sx={{ color: 'text.primary', fontWeight: 500 }}>{formatTime(row.check_in_at)}</Box></Typography>
                <Typography variant="caption" color="text.secondary">Out <Box component="span" sx={{ color: row.check_out_at ? 'text.primary' : 'text.secondary', fontWeight: 500 }}>{row.check_out_at ? formatTime(row.check_out_at) : NO_VALUE}</Box></Typography>
              </Box>
            </Box>
          </Box>
        )
      })}
    </Box>
  )
}

function RecentAttendanceSkeleton() {
  return (
    <Box aria-label="Loading recent attendance" sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
      {Array.from({ length: 3 }, (_, index) => (
        <Skeleton key={index} variant="rounded" height={52} />
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
  const totalEmployees = Number(summary?.total_employees)
  const presentEmployees = Number(summary?.present)
  const attendanceRate = Number.isFinite(totalEmployees) && totalEmployees > 0 && Number.isFinite(presentEmployees)
    ? Math.round((presentEmployees / totalEmployees) * 100)
    : null

  const recentLoading = recent.isPending && !today.isError

  return (
    <Box sx={{ minWidth: 0 }}>
      {/* <PageHeader title="Dashboard" subtitle="A clear view of today’s attendance and recent activity." /> */}

      {today.isError && !summary ? <ErrorState message={attendanceErrorMessage(today.error)} onRetry={() => today.refetch()} retrying={today.isFetching} /> : null}

      <Grid container spacing={GRID_SPACING} sx={{ mb: GRID_SPACING }}>
        <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
          <DashboardKpi
            title="Total Employees"
            value={summary ? summary.total_employees : UNAVAILABLE}
            subtitle={totalSubtitle}
            icon={Users}
            tone="secondary"
            loading={today.isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
          <DashboardKpi
            title="Present Today"
            value={summary ? summary.present : UNAVAILABLE}
            subtitle={summary ? 'Attendance recorded' : 'Count unavailable'}
            icon={UserCheck}
            tone="success"
            loading={today.isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
          <DashboardKpi
            title="Absent Today"
            value={summary ? summary.absent : UNAVAILABLE}
            subtitle={summary ? 'No attendance recorded' : 'Count unavailable'}
            icon={UserX}
            tone="warning"
            loading={today.isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, lg: 3 }}>
          <DashboardKpi
            title="Attendance Rate"
            value={attendanceRate == null ? UNAVAILABLE : `${attendanceRate}%`}
            subtitle={summary ? 'Present out of total employees' : 'Rate unavailable'}
            icon={Percent}
            tone="info"
            loading={today.isLoading}
            progress={attendanceRate}
          />
        </Grid>
      </Grid>

      <Grid container spacing={GRID_SPACING} sx={{ mb: GRID_SPACING }}>
        <Grid size={{ xs: 12, lg: 5 }}>
          <SectionCard
            title="Attendance Overview"
            action={
              <Typography variant="caption" color="text.secondary">
                {summary ? formatDate(summary.date) : 'Today'}
              </Typography>
            }
          >
            <AttendanceOverview summary={summary} loading={today.isLoading} />
          </SectionCard>
        </Grid>

        <Grid size={{ xs: 12, lg: 7 }}>
          <SectionCard title="Weekly Attendance" action={<Typography variant="caption" color="text.secondary">Last 7 days</Typography>}>
            {trend ? (
              <WeeklyAttendanceChart data={trend} />
            ) : trendLoading ? (
              <Skeleton variant="rounded" height={220} aria-label="Loading weekly attendance" />
            ) : (
              <CompactEmpty
                icon={Activity}
                title="Weekly attendance is unavailable"
                description="Daily attendance counts could not be loaded for the last 7 days."
              />
            )}
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
              <RecentAttendanceList rows={recentRows} />
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
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
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
