import { Box, Card, CardContent, Grid, Paper, Typography } from '@mui/material'
import { Activity, Clock3, Files, Users, WalletCards } from 'lucide-react'
import { AttendanceChart } from '../../../components/charts/AttendanceChart'
import { PageHeader } from '../../../components/common/PageHeader'
import { StatsCard } from '../components/StatsCard'
import { useAuth } from '../../auth/hooks/useAuth'

const attendanceData = [
  { day: 'Mon', present: 520, late: 46 },
  { day: 'Tue', present: 650, late: 59 },
  { day: 'Wed', present: 610, late: 53 },
  { day: 'Thu', present: 690, late: 65 },
  { day: 'Fri', present: 720, late: 61 },
  { day: 'Sat', present: 470, late: 32 },
]

const recentActivity = [
  { name: 'Sophia Patel', status: 'Present', time: '08:58 AM', branch: 'Head Office' },
  { name: 'Rohan Gupta', status: 'Late', time: '09:14 AM', branch: 'Bengaluru' },
  { name: 'Aisha Khan', status: 'On Leave', time: 'All Day', branch: 'Chennai' },
  { name: 'Marcus Lee', status: 'Present', time: '08:46 AM', branch: 'Hyderabad' },
]

export function DashboardPage() {
  const { currentUser } = useAuth()

  return (
    <Box>
      <PageHeader title="Lyra Pulse Admin" subtitle={`Welcome back, ${currentUser?.name ?? 'LyraTech Admin'}`} />

      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard title="Total Employees" value="1,284" subtitle="Across 9 branches" trend="+4.2%" icon={<Users size={18} />} tone="primary" />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard title="Present Today" value="903" subtitle="70.4% of workforce" trend="+2.8%" icon={<Activity size={18} />} tone="success" />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard title="Absent Today" value="142" subtitle="11.1% of workforce" trend="-1.4%" icon={<Clock3 size={18} />} tone="warning" />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard title="On Leave" value="68" subtitle="Requests pending review" trend="+12" icon={<WalletCards size={18} />} tone="error" />
        </Grid>
      </Grid>

      <Grid container spacing={3}>
        <Grid size={{ xs: 12, lg: 8 }}>
          <Paper sx={{ p: 3, borderRadius: 3, height: '100%' }}>
            <AttendanceChart data={attendanceData} />
          </Paper>
        </Grid>

        <Grid size={{ xs: 12, lg: 4 }}>
          <Card sx={{ height: '100%' }}>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" sx={{ mb: 2, fontWeight: 700 }}>
                Leave Summary
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                {[
                  { label: 'Annual Leave', value: '52', color: '#3b82f6' },
                  { label: 'Sick Leave', value: '25', color: '#16a34a' },
                  { label: 'Casual Leave', value: '18', color: '#f59e0b' },
                  { label: 'Maternity', value: '7', color: '#8b5cf6' },
                ].map((item) => (
                  <Box key={item.label}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                      <Typography variant="body2" color="text.secondary">{item.label}</Typography>
                      <Typography variant="body2" sx={{ fontWeight: 700 }}>{item.value}</Typography>
                    </Box>
                    <Box sx={{ height: 8, borderRadius: 999, backgroundColor: '#e2e8f0', overflow: 'hidden' }}>
                      <Box sx={{ width: `${(Number(item.value) / 52) * 100}%`, height: '100%', backgroundColor: item.color, borderRadius: 999 }} />
                    </Box>
                  </Box>
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={3} sx={{ mt: 0.5 }}>
        <Grid size={{ xs: 12, lg: 7 }}>
          <Card>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" sx={{ mb: 2, fontWeight: 700 }}>
                Recent Attendance Activity
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                {recentActivity.map((activity) => (
                  <Box key={activity.name} sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #e2e8f0', pb: 1.5 }}>
                    <Box>
                      <Typography variant="body1" sx={{ fontWeight: 600 }}>{activity.name}</Typography>
                      <Typography variant="caption" color="text.secondary">{activity.branch}</Typography>
                    </Box>
                    <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end' }}>
                      <Typography variant="body2" color={activity.status === 'Late' ? '#f59e0b' : activity.status === 'On Leave' ? '#ef4444' : '#16a34a'} sx={{ fontWeight: 700 }}>{activity.status}</Typography>
                      <Typography variant="caption" color="text.secondary">{activity.time}</Typography>
                    </Box>
                  </Box>
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid size={{ xs: 12, lg: 5 }}>
          <Card>
            <CardContent sx={{ p: 3 }}>
              <Typography variant="h6" sx={{ mb: 2, fontWeight: 700 }}>
                Quick Actions
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                {['Add employee', 'Approve leave', 'Review attendance', 'Generate report'].map((action) => (
                  <Box key={action} sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: 2, p: 1.5 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                      <Box sx={{ width: 8, height: 8, borderRadius: '50%', backgroundColor: '#3b82f6' }} />
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{action}</Typography>
                    </Box>
                    <Files size={16} color="#64748b" />
                  </Box>
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  )
}
