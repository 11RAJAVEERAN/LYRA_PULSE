import { Box, Typography, useTheme } from '@mui/material'
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'

export function AttendanceChart({ data }) {
  const theme = useTheme()

  return (
    <Box sx={{ width: '100%', height: 300 }}>
      <Typography variant="h6" component="h2" sx={{ mb: 2 }}>
        Attendance overview
      </Typography>
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data} margin={{ top: 4, right: 8, left: -16, bottom: 0 }}>
          <defs>
            <linearGradient id="attendanceFill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor={theme.palette.info.main} stopOpacity={0.24} />
              <stop offset="95%" stopColor={theme.palette.info.main} stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke={theme.palette.divider} />
          <XAxis dataKey="day" stroke={theme.palette.text.secondary} tickLine={false} axisLine={false} />
          <YAxis stroke={theme.palette.text.secondary} tickLine={false} axisLine={false} />
          <Tooltip />
          <Area type="monotone" dataKey="present" stroke={theme.palette.info.main} fill="url(#attendanceFill)" strokeWidth={2} />
          <Area type="monotone" dataKey="late" stroke={theme.palette.warning.main} fill={theme.palette.warning.light} strokeWidth={2} />
        </AreaChart>
      </ResponsiveContainer>
    </Box>
  )
}