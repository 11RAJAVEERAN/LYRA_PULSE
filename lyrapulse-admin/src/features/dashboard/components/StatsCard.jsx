import { Box, Card, CardContent, Chip, Skeleton, Typography, useTheme } from '@mui/material'

// `tone` maps to a theme palette colour: info (brand blue), success, warning or error.
export function StatsCard({ title, value, subtitle, trend, icon, tone = 'info', loading = false }) {
  const theme = useTheme()
  const paletteTone = theme.palette[tone] ?? theme.palette.info

  return (
    <Card
      sx={{
        height: '100%',
        transition: 'box-shadow 0.2s ease, transform 0.2s ease',
        '&:hover': { boxShadow: theme.shadows[2], transform: 'translateY(-1px)' },
        '@media (prefers-reduced-motion: reduce)': { transition: 'none', '&:hover': { transform: 'none' } },
      }}
    >
      <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 1.5 }}>
          <Box
            aria-hidden="true"
            sx={{
              display: 'grid',
              placeItems: 'center',
              width: 38,
              height: 38,
              borderRadius: 1.5,
              flexShrink: 0,
              backgroundColor: paletteTone.light,
              color: paletteTone.main,
            }}
          >
            {icon}
          </Box>
          {trend ? (
            <Chip
              label={trend}
              size="small"
              sx={{
                height: 24,
                backgroundColor: paletteTone.light,
                color: paletteTone.dark,
                fontSize: 11,
                fontWeight: 700,
                '& .MuiChip-label': { px: 1 },
              }}
            />
          ) : null}
        </Box>

        <Typography variant="body2" color="text.secondary" sx={{ mt: 1.5, fontSize: 12, fontWeight: 500 }}>
          {title}
        </Typography>

        {loading ? (
          <Skeleton variant="text" width={64} sx={{ fontSize: 26, mt: 0.35 }} aria-label={`Loading ${title}`} />
        ) : (
          <Typography
            sx={{ mt: 0.35, color: 'text.primary', fontSize: 26, lineHeight: 1.15, fontWeight: 700, letterSpacing: '-0.02em' }}
          >
            {value}
          </Typography>
        )}

        <Typography sx={{ mt: 0.45, color: 'text.secondary', fontSize: 11, lineHeight: 1.3 }}>
          {subtitle}
        </Typography>
      </CardContent>
    </Card>
  )
}