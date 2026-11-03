import { Alert, Box, Chip, Divider, Drawer, LinearProgress, Stack, Typography } from '@mui/material'
import { useAssignmentHistory } from '../hooks/useShiftQueries'

export function AssignmentHistoryDrawer({ employee, open, onClose }) {
  const history = useAssignmentHistory(employee?.id, { page: 1, page_size: 100 }, open)
  const rows = history.data?.results ?? []
  return <Drawer anchor="right" open={open} onClose={onClose} PaperProps={{ sx: { width: { xs: '100%', sm: 500 }, p: 3 } }}>
    <Typography variant="h5" fontWeight={700}>Assignment history</Typography>
    <Typography color="text.secondary" sx={{ mt: 0.5 }}>{employee?.name} · {employee?.employee_code}</Typography>
    <Divider sx={{ my: 2 }} />
    {history.isFetching ? <LinearProgress /> : null}
    {history.isError ? <Alert severity="error">{history.error?.response?.data?.message ?? 'Unable to load assignment history.'}</Alert> : null}
    {!history.isFetching && !rows.length && !history.isError ? <Typography color="text.secondary">No shift assignments recorded.</Typography> : null}
    <Stack spacing={1.5} sx={{ mt: 2 }}>{rows.map((item) => <Box key={item.id} sx={{ p: 2, border: 1, borderColor: 'divider', borderRadius: 2 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center"><Typography fontWeight={700}>{item.shift?.name}</Typography><Chip size="small" label={item.assignment_state} /></Stack>
      <Typography variant="body2" sx={{ mt: 1 }}>{item.effective_from} — {item.effective_to ?? 'No end date'}</Typography>
      <Typography variant="caption" color="text.secondary">Week off: {item.week_off_days?.join(', ') || 'None'}</Typography>
      <Typography variant="caption" display="block" color="text.secondary">Assigned by {item.assigned_by?.name ?? '—'}</Typography>
    </Box>)}</Stack>
  </Drawer>
}
