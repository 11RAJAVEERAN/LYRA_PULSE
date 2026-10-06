import { Alert, Box, Button } from '@mui/material'

export function ErrorState({ message = 'Something went wrong while loading this data.', onRetry, retrying = false }) {
  return (
    <Box sx={{ py: 2 }}>
      <Alert
        severity="error"
        action={onRetry ? (
          <Button color="inherit" size="small" onClick={onRetry} disabled={retrying}>
            {retrying ? 'Retrying…' : 'Retry'}
          </Button>
        ) : undefined}
      >
        {message}
      </Alert>
    </Box>
  )
}