import { useQuery } from '@tanstack/react-query'
import { Box, ButtonBase, Card, CardContent, Grid, Typography } from '@mui/material'
import { Activity, CalendarCheck2, ChevronRight, Clock3, FileText, UserPlus, Users } from 'lucide-react'
import { Link } from 'react-router-dom'
import { AttendanceChart } from '../../../components/charts/AttendanceChart'
import { EmptyState } from '../../../components/common/EmptyState'
import { ErrorState } from '../../../components/common/ErrorState'
import { PageHeader } from '../../../components/common/PageHeader'
import { authService } from '../../../services/authService'
import { useAuth } from '../../auth/hooks/useAuth'
import { dashboardApi } from '../api/dashboardApi'
import { StatsCard } from '../components/StatsCard'

const UNAVAILABLE = '—'

// Leave figures have no backend source yet, so each tile renders an unavailable placeholder.
const leaveTiles = [
  { label: 'Total Requests', description: 'This month', tone: 'info' },
  { label: 'Pending', description: 'Needs review', tone: 'warning' },
  { label: 'Approved', description: 'This month', tone: 'success' },
  { label: 'Rejected', description: 'This month', tone: 'error' },
]

function loadErrorMessage(error) {
  if (error?.response?.status === 403) return 'You do not have permission to view employee data on the dashboard.'
  return 'Employee figures could not be loaded. Please try again.'
}

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
  const { data: overview, error, isLoading, isError, isFetching, refetch } = useQuery({
    queryKey: ['dashboard', 'overview'],
    queryFn: dashboardApi.getOverview,
  })

  const sessionUser = authService.getCurrentUser()
  const can = (codename) => sessionUser?.role === 'SUPERADMIN' || Boolean(sessionUser?.permissions?.includes(codename))

  const employees = overview?.employees
  const trend = overview?.attendance?.trend
  const hasTrend = Array.isArray(trend) && trend.length > 0

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
    if (isError) return 'Unavailable right now'
    if (!employees) return 'Loading employee data'
    if (employees.total === 0) return 'No employees added yet'
    const branches = `${employees.branchCount} ${employees.branchCount === 1 ? 'branch' : 'branches'}`
    return `${employees.active} active · ${employees.inactive} inactive · ${branches}`
  })()

  return (
    <Box>
      <PageHeader title="Dashboard" subtitle={`Welcome back, ${currentUser?.name ?? 'LyraTech Admin'}`} />

      {isError ? <ErrorState message={loadErrorMessage(error)} onRetry={refetch} retrying={isFetching} /> : null}

      <Grid container spacing={2.5} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="Total Employees"
            value={employees ? employees.total : UNAVAILABLE}
            subtitle={totalSubtitle}
            icon={<Users size={18} />}
            tone="info"
            loading={isLoading}
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="Present Today"
            value={UNAVAILABLE}
            subtitle="Attendance data is not available yet"
            icon={<Activity size={18} />}
            tone="success"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="Absent Today"
            value={UNAVAILABLE}
            subtitle="Attendance data is not available yet"
            icon={<Clock3 size={18} />}
            tone="warning"
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
          <SectionCard title="Attendance Overview" subtitle="Employee attendance for this week">
            {hasTrend ? (
              <AttendanceChart data={trend} />
            ) : (
              <EmptyState
                compact
                title="Attendance data is unavailable"
                description="This project does not yet provide an attendance API, so no weekly attendance can be shown."
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