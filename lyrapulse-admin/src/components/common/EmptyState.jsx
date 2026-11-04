import { Box, Button, Stack, Typography } from '@mui/material'
import { Inbox } from 'lucide-react'

export function EmptyState({ title, description, actionLabel, onAction }) {
  return (
    <Box sx={{ py: 8, px: 3, textAlign: 'center' }}>
      <Stack sx={{ alignItems: 'center', gap: 1.5 }}>
        <Box sx={{ display: 'grid', placeItems: 'center', width: 56, height: 56, borderRadius: '50%', backgroundColor: '#eef5ff' }}>
          <Inbox size={24} color="#1d4ed8" />
        </Box>
        <Typography variant="h6">{title}</Typography>
        {description ? (
          <Typography variant="body2" color="text.secondary">
            {description}
          </Typography>
        ) : null}
        {actionLabel && onAction ? (
          <Button variant="contained" onClick={onAction}>
            {actionLabel}
          </Button>
        ) : null}
      </Stack>
    </Box>
  )
}
