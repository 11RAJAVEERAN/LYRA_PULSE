import { Alert, Box } from '@mui/material'

export function ErrorState({ message = 'Something went wrong while loading this data.' }) {
  return (
    <Box sx={{ py: 3 }}>
      <Alert severity="error">{message}</Alert>
    </Box>
  )
}
