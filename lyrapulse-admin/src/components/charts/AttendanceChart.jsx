import { Box, Typography, useTheme } from '@mui/material'
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'

// Expects rows shaped { day, present, absent }. Every colour comes from the active theme.
export function AttendanceChart({ data }) {
  const theme = useTheme()
  const presentColor = theme.palette.info.main
  const absentColor = theme.palette.error.main
  const axisTick = { fill: theme.palette.text.secondary, fontSize: 12 }
  const legend = [
    { label: 'Present', color: presentColor },
    { label: 'Absent', color: absentColor },
  ]

  return (
    <Box sx={{ width: '100%' }}>
      <Box sx={{ width: '100%', height: 280 }}>
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
            <defs>
              <linearGradient id="presentGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor={presentColor} stopOpacity={0.12} />
                <stop offset="100%" stopColor={presentColor} stopOpacity={0} />
              </linearGradient>
              <linearGradient id="absentGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor={absentColor} stopOpacity={0.06} />
                <stop offset="100%" stopColor={absentColor} stopOpacity={0} />
              </linearGradient>
            </defs>

            <CartesianGrid vertical={false} stroke={theme.palette.divider} strokeDasharray="3 4" />
            <XAxis dataKey="day" axisLine={false} tickLine={false} tick={axisTick} dy={8} />
            <YAxis axisLine={false} tickLine={false} tick={axisTick} width={32} allowDecimals={false} />
            <Tooltip
              cursor={{ stroke: theme.palette.divider, strokeWidth: 1 }}
              contentStyle={{
                backgroundColor: theme.palette.background.paper,
                border: `1px solid ${theme.palette.divider}`,
                borderRadius: theme.shape.borderRadius,
                boxShadow: theme.shadows[3],
                padding: '8px 12px',
              }}
              labelStyle={{ color: theme.palette.text.primary, fontSize: 12, fontWeight: 600, marginBottom: 4 }}
              itemStyle={{ fontSize: 12, fontWeight: 500, padding: 0 }}
              formatter={(value, name) => [value, name === 'present' ? 'Present' : 'Absent']}
            />

            <Area
              type="monotone"
              dataKey="absent"
              name="absent"
              stroke={absentColor}
              fill="url(#absentGradient)"
              strokeWidth={2}
              dot={false}
              activeDot={{ r: 4, fill: absentColor, stroke: theme.palette.background.paper, strokeWidth: 2 }}
            />
            <Area
              type="monotone"
              dataKey="present"
              name="present"
              stroke={presentColor}
              fill="url(#presentGradient)"
              strokeWidth={2}
              dot={false}
              activeDot={{ r: 4, fill: presentColor, stroke: theme.palette.background.paper, strokeWidth: 2 }}
            />
          </AreaChart>
        </ResponsiveContainer>
      </Box>

      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mt: 1.5 }}>
        {legend.map((item) => (
          <Box key={item.label} sx={{ display: 'flex', alignItems: 'center', gap: 0.75 }}>
            <Box aria-hidden="true" sx={{ width: 8, height: 8, borderRadius: '50%', backgroundColor: item.color }} />
            <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 500 }}>
              {item.label}
            </Typography>
          </Box>
        ))}
      </Box>
    </Box>
  )
}
