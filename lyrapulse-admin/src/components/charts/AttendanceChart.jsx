import { Box, Typography } from '@mui/material'
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'

export function AttendanceChart({ data }) {
  return (
    <Box sx={{ width: '100%', height: 300 }}>
      <Typography variant="h6" sx={{ mb: 2, fontWeight: 700 }}>
        Attendance Overview
      </Typography>
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data}>
          <defs>
            <linearGradient id="attendanceFill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.35} />
              <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="#dfe7f3" />
          <XAxis dataKey="day" stroke="#64748b" />
          <YAxis stroke="#64748b" />
          <Tooltip />
          <Area type="monotone" dataKey="present" stroke="#1d4ed8" fill="url(#attendanceFill)" strokeWidth={3} />
          <Area type="monotone" dataKey="late" stroke="#f59e0b" fill="#fef3c7" strokeWidth={2} />
        </AreaChart>
      </ResponsiveContainer>
    </Box>
  )
}
