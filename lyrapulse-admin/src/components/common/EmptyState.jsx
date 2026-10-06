import { Box, Button, Stack, Typography } from '@mui/material'
import { Inbox } from 'lucide-react'

export function EmptyState({ title, description, actionLabel, onAction, compact = false }) {
  return (
    <Box sx={{ py: compact ? 5 : 8, px: 3, textAlign: 'center' }}>
      <Stack sx={{ alignItems: 'center', gap: 1.5 }}>
        <Box
          aria-hidden="true"
          sx={{
            display: 'grid',
            placeItems: 'center',
            width: 52,
            height: 52,
            borderRadius: 1.5,
            backgroundColor: 'info.light',
            color: 'info.main',
          }}
        >
          <Inbox size={22} />
        </Box>
        <Typography variant="h6" component="h2">{title}</Typography>
        {description ? (
          <Typography variant="body2" color="text.secondary" sx={{ maxWidth: 440 }}>
            {description}
          </Typography>
        ) : null}
        {actionLabel && onAction ? (
          <Button variant="contained" onClick={onAction} sx={{ mt: 0.5 }}>
            {actionLabel}
          </Button>
        ) : null}
      </Stack>
    </Box>
  )
}