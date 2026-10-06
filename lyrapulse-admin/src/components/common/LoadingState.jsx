import { Box, CircularProgress, Stack, Typography } from '@mui/material'

export function LoadingState({ label = 'Loading…' }) {
  return (
    <Box role="status" aria-live="polite" sx={{ py: 6, display: 'flex', justifyContent: 'center' }}>
      <Stack sx={{ alignItems: 'center', gap: 1.5 }}>
        <CircularProgress size={26} aria-label={label} />
        <Typography variant="body2" color="text.secondary">{label}</Typography>
      </Stack>
    </Box>
  )
}