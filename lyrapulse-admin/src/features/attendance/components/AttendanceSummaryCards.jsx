import { Box } from '@mui/material'
import { UserCheck, UserX, Users } from 'lucide-react'
import { StatsCard } from '../../dashboard/components/StatsCard'
import { formatDate } from '../utils/format'

// A responsive auto-fit grid: more cards can be appended later without changing the layout.
export function AttendanceSummaryCards({ summary, loading, range }) {
  const isRange = range.start !== range.end
  const when = isRange ? `${formatDate(range.start)} – ${formatDate(range.end)}` : formatDate(range.start)
  const cards = [
    { key: 'total', title: 'Total Employees', value: summary?.total_employees, subtitle: when, icon: <Users size={19} />, tone: 'info' },
    {
      key: 'present', title: 'Present', value: summary?.present, icon: <UserCheck size={19} />, tone: 'success',
      subtitle: isRange ? 'Checked in at least once in range' : 'Checked in',
    },
    {
      key: 'absent', title: 'Absent', value: summary?.absent, icon: <UserX size={19} />, tone: 'error',
      subtitle: isRange ? 'No check-in in range' : 'No check-in recorded',
    },
  ]

  return (
    <Box sx={{ display: 'grid', gap: 2, gridTemplateColumns: 'repeat(auto-fit, minmax(210px, 1fr))', mb: 2 }}>
      {cards.map(({ key, ...card }) => (
        <StatsCard key={key} {...card} loading={loading} />
      ))}
    </Box>
  )
}
