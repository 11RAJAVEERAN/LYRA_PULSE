import { Box, Paper } from '@mui/material'
import { EmptyState } from '../../../components/common/EmptyState'
import { PageHeader } from '../../../components/common/PageHeader'

export function AttendancePage() {
  return (
    <Box>
      <PageHeader title="Attendance" subtitle="Review employee check-ins and attendance activity." />
      <Paper sx={{ border: 1, borderColor: 'divider' }}>
        <EmptyState
          title="Attendance data is unavailable"
          description="This project does not yet provide an attendance API, so there are no live records to display."
        />
      </Paper>
    </Box>
  )
}