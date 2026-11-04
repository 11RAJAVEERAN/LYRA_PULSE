import { Chip } from '@mui/material'

export function StatusChip({ label, color = 'default', icon }) {
  return <Chip label={label} color={color} icon={icon} size="small" sx={{ fontWeight: 600 }} />
}
