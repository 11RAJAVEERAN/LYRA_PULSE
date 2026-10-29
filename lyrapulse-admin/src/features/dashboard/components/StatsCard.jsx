import { Box, Card, CardContent, Chip, Skeleton, Typography, alpha, useTheme } from '@mui/material'

// Shared KPI card (Dashboard and Attendance). `tone` maps to a theme palette colour: info (brand blue),
// success, warning, error or secondary. Props are unchanged; only the presentation is.
export function StatsCard({ title, value, subtitle, trend, icon, tone = 'info', loading = false }) {
  const theme = useTheme()
  const paletteTone = theme.palette[tone] ?? theme.palette.info

  return (
    <Card sx={{ height: '100%' }}>
      <CardContent sx={{ p: 2.5, '&:last-child': { pb: 2.5 } }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 1.5 }}>
          <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 500, pt: 0.75 }}>
            {title}
          </Typography>
          <Box
            aria-hidden="true"
            sx={{
              display: 'grid',
              placeItems: 'center',
              width: 36,
              height: 36,
              borderRadius: 1,
              flexShrink: 0,
              backgroundColor: alpha(paletteTone.main, 0.1),
              color: paletteTone.main,
            }}
          >
            {icon}
          </Box>
        </Box>

        {loading ? (
          <Skeleton variant="text" width={64} sx={{ fontSize: 28, mt: 0.5 }} aria-label={`Loading ${title}`} />
        ) : (
          <Typography sx={{ mt: 0.5, color: 'text.primary', fontSize: 28, lineHeight: 1.25, fontWeight: 700, letterSpacing: '-0.02em' }}>
            {value}
          </Typography>
        )}

        <Box sx={{ mt: 0.75, display: 'flex', alignItems: 'center', gap: 1, minHeight: 18 }}>
          {trend ? (
            <Chip
              label={trend}
              size="small"
              sx={{
                height: 20,
                backgroundColor: alpha(paletteTone.main, 0.1),
                color: paletteTone.dark,
                fontSize: 12,
                fontWeight: 500,
                '& .MuiChip-label': { px: 0.75 },
              }}
            />
          ) : null}
          <Typography variant="caption" color="text.secondary" noWrap>
            {subtitle}
          </Typography>
        </Box>
      </CardContent>
    </Card>
  )
}
