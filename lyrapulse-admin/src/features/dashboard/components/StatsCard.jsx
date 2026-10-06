import { Box, Card, CardContent, Chip, Typography, useTheme } from '@mui/material'

export function StatsCard({ title, value, subtitle, trend, icon, tone = 'primary' }) {
  const theme = useTheme()
  const paletteTone = theme.palette[tone] ?? theme.palette.primary

  return (
    <Card sx={{ height: '100%' }}>
      <CardContent sx={{ p: 2.5 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 2 }}>
          <Box
            aria-hidden="true"
            sx={{
              display: 'grid',
              placeItems: 'center',
              width: 42,
              height: 42,
              borderRadius: 1.5,
              backgroundColor: paletteTone.light,
              color: paletteTone.dark,
            }}
          >
            {icon}
          </Box>
          {trend ? <Chip label={trend} color={tone} size="small" /> : null}
        </Box>
        <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
          {title}
        </Typography>
        <Typography variant="h4" sx={{ mt: 0.5 }}>
          {value}
        </Typography>
        <Typography variant="caption" color="text.secondary">
          {subtitle}
        </Typography>
      </CardContent>
    </Card>
  )
}