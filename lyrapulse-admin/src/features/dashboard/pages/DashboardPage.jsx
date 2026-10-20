import { Box, ButtonBase, Card, CardContent, Grid, Skeleton, Typography } from '@mui/material'
import { Activity, CalendarCheck2, ChevronRight, Clock3, FileText, UserPlus, Users } from 'lucide-react'
import { Link } from 'react-router-dom'
import { AttendanceChart } from '../../../components/charts/AttendanceChart'
import { EmptyState } from '../../../components/common/EmptyState'
import { ErrorState } from '../../../components/common/ErrorState'
import { PageHeader } from '../../../components/common/PageHeader'
import { authService } from '../../../services/authService'
import { attendanceErrorMessage } from '../../attendance/utils/errors'
import { formatDate } from '../../attendance/utils/format'
import { useAuth } from '../../auth/hooks/useAuth'
import { StatsCard } from '../components/StatsCard'
import { useDashboardAttendance } from '../hooks/useDashboardAttendance'

const UNAVAILABLE = '—'

// Leave figures have no backend source yet, so each tile renders an unavailable placeholder.
const leaveTiles = [
  { label: 'Total Requests', description: 'This month', tone: 'info' },
  { label: 'Pending', description: 'Needs review', tone: 'warning' },
  { label: 'Approved', description: 'This month', tone: 'success' },
  { label: 'Rejected', description: 'This month', tone: 'error' },
]

function SectionCard({ title, subtitle, action, children, sx }) {
  return (
    <Card sx={{ height: '100%', ...sx }}>
      <CardContent sx={{ p: { xs: 2, md: 3 } }}>
        <Box sx={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 2, mb: 2.5 }}>
          <Box sx={{ minWidth: 0 }}>
            <Typography variant="h6" component="h2" sx={{ fontWeight: 700 }}>
              {title}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mt: 0.4 }}>
              {subtitle}
            </Typography>
          </Box>
          {action}
        </Box>
        {children}
      </CardContent>
    </Card>
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
        p: 1.5,
        borderRadius: 1.5,
        border: 1,
        borderColor: 'divider',
        backgroundColor: 'background.paper',
        textAlign: 'left',
        transition: 'background-color 0.2s ease, border-color 0.2s ease',
        '&:hover': { backgroundColor: 'action.hover', borderColor: 'info.main' },
        '&.Mui-focusVisible': { outline: 3, outlineStyle: 'solid', outlineColor: 'info.main', outlineOffset: 2 },
        '&.Mui-disabled': { opacity: 0.6 },
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, minWidth: 0 }}>
        <Box
          aria-hidden="true"
          sx={{
            display: 'grid',
            placeItems: 'center',
            width: 38,
            height: 38,
            flexShrink: 0,
            borderRadius: 1.5,
            backgroundColor: 'info.light',
            color: 'info.main',
          }}
        >
          <Icon size={18} />
        </Box>
        <Box sx={{ minWidth: 0 }}>
          <Typography variant="body2" sx={{ fontWeight: 700 }}>
            {label}
          </Typography>
          <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
            {disabled ? disabledReason : description}
          </Typography>
        </Box>
      </Box>
      {disabled ? null : <ChevronRight size={17} aria-hidden="true" />}
    </ButtonBase>
  )
}

export function DashboardPage() {
  const { currentUser } = useAuth()
  // Real attendance data from the Attendance Admin summary API; `today` refetches silently every 5 seconds and the
  // existing figures stay on screen while it does. Only the first load shows the skeletons.
  const { today, trend, trendLoading } = useDashboardAttendance()
  const summary = today.data

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
    { label: 'Approve Leave', description: 'Review pending leave requests', icon: Clock3, disabledReason: 'Leave management is not available yet' },
    { label: 'Generate Report', description: 'Create attendance report', icon: FileText, disabledReason: 'Reports are not available yet' },
  ]

  const totalSubtitle = (() => {
    if (summary) return formatDate(summary.date)
    return today.isError ? 'Unavailable right now' : 'Loading attendance data'
  })()

  return (
    <Box>
      <PageHeader title="Dashboard" subtitle={`Welcome back, ${currentUser?.name ?? 'LyraTech Admin'}`} />

      {today.isError && !summary ? <ErrorState message={attendanceErrorMessage(today.error)} onRetry={() => today.refetch()} retrying={today.isFetching} /> : null}

      <Grid container spacing={2.5} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="Total Employees"
            value={summary ? summary.total_employees : UNAVAILABLE}
            subtitle={totalSubtitle}
            icon={<Users size={18} />}
            tone="info"
            loading={today.isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="Present Today"
            value={summary ? summary.present : UNAVAILABLE}
            subtitle="Checked in"
            icon={<Activity size={18} />}
            tone="success"
            loading={today.isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="Absent Today"
            value={summary ? summary.absent : UNAVAILABLE}
            subtitle="No check-in recorded"
            icon={<Clock3 size={18} />}
            tone="warning"
            loading={today.isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="On Leave"
            value={UNAVAILABLE}
            subtitle="Leave data is not available yet"
            icon={<CalendarCheck2 size={18} />}
            tone="error"
          />
        </Grid>
      </Grid>

      <Grid container spacing={2.5} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, lg: 8 }}>
          <SectionCard title="Attendance Overview" subtitle="Employee attendance for the last 7 days">
            {trend ? (
              <AttendanceChart data={trend} />
            ) : trendLoading ? (
              <Skeleton variant="rounded" height={285} aria-label="Loading attendance overview" />
            ) : (
              <EmptyState
                compact
                title="Attendance data is unavailable"
                description="The daily attendance for the last 7 days could not be loaded. Please try again."
              />
            )}
          </SectionCard>
        </Grid>

        <Grid size={{ xs: 12, lg: 4 }}>
          <SectionCard
            title="Leave Requests"
            subtitle="Monthly leave overview"
            action={
              <Box
                aria-hidden="true"
                sx={{ display: 'grid', placeItems: 'center', width: 36, height: 36, flexShrink: 0, borderRadius: 1.5, backgroundColor: 'info.light', color: 'info.main' }}
              >
                <CalendarCheck2 size={18} />
              </Box>
            }
          >
            <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 1.5 }}>
              {leaveTiles.map((tile) => (
                <Box
                  key={tile.label}
                  sx={(theme) => ({
                    p: 1.7,
                    borderRadius: 1.5,
                    backgroundColor: theme.palette[tile.tone].light,
                    border: 1,
                    borderColor: 'divider',
                  })}
                >
                  <Typography sx={{ fontSize: 11, fontWeight: 600, color: 'text.secondary' }}>{tile.label}</Typography>
                  <Typography
                    aria-label={`${tile.label}: unavailable`}
                    sx={(theme) => ({ mt: 0.5, fontSize: 24, lineHeight: 1.1, fontWeight: 700, color: theme.palette[tile.tone].main })}
                  >
                    {UNAVAILABLE}
                  </Typography>
                  <Typography sx={{ mt: 0.5, fontSize: 10, color: 'text.secondary' }}>{tile.description}</Typography>
                </Box>
              ))}
            </Box>
            <Box sx={{ mt: 2, pt: 1.5, borderTop: 1, borderColor: 'divider' }}>
              <Typography sx={{ fontSize: 11, color: 'text.secondary' }}>
                Leave data is not available yet because the backend has no leave API.
              </Typography>
            </Box>
          </SectionCard>
        </Grid>
      </Grid>

      <Grid container spacing={2.5}>
        <Grid size={{ xs: 12, lg: 7 }}>
          <SectionCard title="Recent Attendance" subtitle="Latest employee activity">
            <EmptyState
              compact
              title="No attendance activity to show"
              description="Recent check-ins will appear here once an attendance API is available."
            />
          </SectionCard>
        </Grid>

        <Grid size={{ xs: 12, lg: 5 }}>
          <SectionCard title="Quick Actions" subtitle="Common admin activities">
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.2 }}>
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