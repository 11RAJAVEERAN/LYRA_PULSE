import { Box, Typography, useTheme } from '@mui/material'
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'

// Expects rows shaped { day, present, absent }. Colours come from the active theme.
export function AttendanceChart({ data }) {
  const theme = useTheme()
  const presentColor = theme.palette.info.main
  const absentColor = theme.palette.error.main
  const surface = theme.palette.background.paper
  const legend = [
    { label: 'Present', color: presentColor },
    { label: 'Absent', color: absentColor },
  ]

  return (
    <Box sx={{ width: '100%' }}>
      <Box
        sx={{
          width: '100%',
          height: 285,
          borderRadius: 2,
          backgroundColor: surface,
          border: 1,
          borderColor: 'divider',
          overflow: 'hidden',
        }}
      >
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data} margin={{ top: 20, right: 18, left: -18, bottom: 12 }}>
            <defs>
              <linearGradient id="presentGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor={presentColor} stopOpacity={0.25} />
                <stop offset="100%" stopColor={presentColor} stopOpacity={0} />
              </linearGradient>
              <linearGradient id="absentGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor={absentColor} stopOpacity={0.16} />
                <stop offset="100%" stopColor={absentColor} stopOpacity={0} />
              </linearGradient>
            </defs>

            <CartesianGrid vertical={false} stroke={theme.palette.divider} strokeDasharray="3 6" />
            <XAxis
              dataKey="day"
              axisLine={false}
              tickLine={false}
              tick={{ fill: theme.palette.text.secondary, fontSize: 11, fontWeight: 600 }}
              dy={10}
            />
            <YAxis
              axisLine={false}
              tickLine={false}
              tick={{ fill: theme.palette.text.secondary, fontSize: 10 }}
              width={38}
            />
            <Tooltip
              cursor={{ stroke: presentColor, strokeWidth: 1, strokeDasharray: '5 5' }}
              contentStyle={{
                backgroundColor: surface,
                border: `1px solid ${theme.palette.divider}`,
                borderRadius: 12,
                boxShadow: theme.shadows[3],
                padding: '10px 13px',
              }}
              labelStyle={{ color: theme.palette.primary.main, fontSize: 12, fontWeight: 700, marginBottom: 6 }}
              itemStyle={{ fontSize: 12, fontWeight: 600 }}
              formatter={(value, name) => [value, name === 'present' ? 'Present' : 'Absent']}
            />

            <Area
              type="monotone"
              dataKey="present"
              name="present"
              stroke={presentColor}
              fill="url(#presentGradient)"
              strokeWidth={3}
              dot={{ r: 4, fill: presentColor, stroke: surface, strokeWidth: 2 }}
              activeDot={{ r: 7, fill: presentColor, stroke: surface, strokeWidth: 3 }}
            />
            <Area
              type="monotone"
              dataKey="absent"
              name="absent"
              stroke={absentColor}
              fill="url(#absentGradient)"
              strokeWidth={2}
              strokeDasharray="6 5"
              dot={{ r: 3, fill: absentColor, stroke: surface, strokeWidth: 2 }}
              activeDot={{ r: 5, fill: absentColor, stroke: surface, strokeWidth: 2 }}
            />
          </AreaChart>
        </ResponsiveContainer>
      </Box>

      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 3, mt: 1.8 }}>
        {legend.map((item) => (
          <Box key={item.label} sx={{ display: 'flex', alignItems: 'center', gap: 0.8 }}>
            <Box aria-hidden="true" sx={{ width: 8, height: 8, borderRadius: '50%', backgroundColor: item.color }} />
            <Typography sx={{ fontSize: 11, color: 'text.secondary', fontWeight: 600 }}>{item.label}</Typography>
          </Box>
        ))}
      </Box>
    </Box>
  )
}