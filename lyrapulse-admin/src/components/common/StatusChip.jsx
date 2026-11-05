import { Chip } from '@mui/material'

const statusColors = {
  active: 'success',
  approved: 'success',
  completed: 'success',
  present: 'success',
  pending: 'warning',
  late: 'warning',
  inactive: 'default',
  rejected: 'error',
  failed: 'error',
  absent: 'error',
}

export function StatusChip({ label, color, icon }) {
  const semanticColor = color ?? statusColors[String(label).toLowerCase()] ?? 'default'

  return (
    <Chip
      label={label}
      color={semanticColor}
      icon={icon}
      size="small"
      variant={semanticColor === 'default' ? 'outlined' : 'filled'}
      sx={{
        ...(semanticColor === 'warning' ? { backgroundColor: 'warning.light', color: 'warning.dark' } : {}),
        ...(semanticColor === 'success' ? { backgroundColor: 'success.light', color: 'success.dark' } : {}),
        ...(semanticColor === 'error' ? { backgroundColor: 'error.light', color: 'error.dark' } : {}),
      }}
    />
  )
}