import { Alert, Box, Button, Grid, Paper, Stack, Typography } from '@mui/material'
import { Activity, Clock3, Users, WalletCards } from 'lucide-react'
import { Link } from 'react-router-dom'
import { PageHeader } from '../../../components/common/PageHeader'
import { StatsCard } from '../components/StatsCard'
import { useAuth } from '../../auth/hooks/useAuth'

const metrics = [
  { title: 'Total employees', icon: <Users size={19} />, tone: 'primary' },
  { title: 'Present today', icon: <Activity size={19} />, tone: 'success' },
  { title: 'Absent today', icon: <Clock3 size={19} />, tone: 'warning' },
  { title: 'On leave', icon: <WalletCards size={19} />, tone: 'secondary' },
]

export function DashboardPage() {
  const { currentUser } = useAuth()

  return (
    <Box>
      <PageHeader
        title="Dashboard"
        subtitle={`Welcome back, ${currentUser?.name ?? 'LyraTech Admin'}. Your workspace overview is ready.`}
        action={<Button component={Link} to="/employees" variant="contained">Manage employees</Button>}
      />

      <Alert severity="info" sx={{ mb: 2.5 }}>
        Live workforce metrics are not available because this project does not yet include a dashboard data API.
      </Alert>

      <Grid container spacing={2}>
        {metrics.map((metric) => (
          <Grid key={metric.title} size={{ xs: 12, sm: 6, xl: 3 }}>
            <StatsCard
              {...metric}
              value="—"
              subtitle="Waiting for live dashboard data"
            />
          </Grid>
        ))}
      </Grid>

      <Paper sx={{ mt: 2.5, p: { xs: 2, sm: 3 }, border: 1, borderColor: 'divider' }}>
        <Stack spacing={0.5}>
          <Typography variant="h6">Workforce overview</Typography>
          <Typography variant="body2" color="text.secondary">
            Attendance trends and recent activity will appear here when a live data source is available.
          </Typography>
        </Stack>
      </Paper>
    </Box>
  )
}