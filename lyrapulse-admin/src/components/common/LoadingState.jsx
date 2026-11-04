import { Box, CircularProgress, Stack, Typography } from '@mui/material'

export function LoadingState({ label = 'Loading...' }) {
  return (
    <Box sx={{ py: 6, display: 'flex', justifyContent: 'center' }}>
      <Stack sx={{ alignItems: 'center', gap: 2 }}>
        <CircularProgress size={28} />
        <Typography variant="body2" color="text.secondary">
          {label}
        </Typography>
      </Stack>
    </Box>
  )
}
