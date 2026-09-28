import { Box, Card, CardContent, Chip, Typography } from '@mui/material'

export function StatsCard({ title, value, subtitle, trend, icon, tone = 'primary' }) {
  const toneMap = {
    primary: { bg: '#eff6ff', color: '#1d4ed8' },
    success: { bg: '#ecfdf5', color: '#16a34a' },
    warning: { bg: '#fff7ed', color: '#f59e0b' },
    error: { bg: '#fef2f2', color: '#ef4444' },
  }

  const color = toneMap[tone]

  return (
    <Card sx={{ height: '100%' }}>
      <CardContent sx={{ p: 2.5 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
          <Box
            sx={{
              display: 'grid',
              placeItems: 'center',
              width: 44,
              height: 44,
              borderRadius: 2,
              backgroundColor: color.bg,
              color: color.color,
            }}
          >
            {icon}
          </Box>
          {trend ? (
            <Chip label={trend} size="small" sx={{ backgroundColor: color.bg, color: color.color, fontWeight: 700 }} />
          ) : null}
        </Box>
        <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
          {title}
        </Typography>
        <Typography variant="h4" sx={{ mt: 0.75, fontWeight: 700 }}>
          {value}
        </Typography>
        <Typography variant="caption" color="text.secondary">
          {subtitle}
        </Typography>
      </CardContent>
    </Card>
  )
}
