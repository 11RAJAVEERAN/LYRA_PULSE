import { Card, CardContent, Grid, MenuItem, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TextField, Typography } from '@mui/material'
import { PageHeader } from '../../../components/common/PageHeader'
import { SearchInput } from '../../../components/common/SearchInput'
import { useState } from 'react'

const rows = [
  { employee: 'Alicia Turner', code: 'LYR-201', branch: 'Head Office', date: '2026-09-28', checkIn: '08:52', checkOut: '18:05', hours: '9h 13m', status: 'Present', source: 'Fingerprint' },
  { employee: 'Rohit Sharma', code: 'LYR-185', branch: 'Bengaluru', date: '2026-09-28', checkIn: '09:18', checkOut: '18:11', hours: '8h 53m', status: 'Late', source: 'Mobile Face' },
  { employee: 'Meera Nair', code: 'LYR-947', branch: 'Chennai', date: '2026-09-28', checkIn: '-', checkOut: '-', hours: '0h 00m', status: 'Absent', source: 'Admin' },
]

export function AttendancePage() {
  const [query, setQuery] = useState('')

  return (
    <div>
      <PageHeader title="Attendance" subtitle="Employee check-in and attendance overview" />

      <Card>
        <CardContent sx={{ p: 2.5 }}>
          <Grid container spacing={2} sx={{ alignItems: 'center' }}>
            <Grid size={{ xs: 12, md: 4 }}>
              <SearchInput value={query} onChange={setQuery} placeholder="Search employee" />
            </Grid>
            <Grid size={{ xs: 12, md: 2 }}>
              <TextField select fullWidth size="small" label="Branch" defaultValue="all">
                <MenuItem value="all">All</MenuItem>
                <MenuItem value="head-office">Head Office</MenuItem>
                <MenuItem value="bengaluru">Bengaluru</MenuItem>
              </TextField>
            </Grid>
            <Grid size={{ xs: 12, md: 2 }}>
              <TextField select fullWidth size="small" label="Status" defaultValue="all">
                <MenuItem value="all">All</MenuItem>
                <MenuItem value="present">Present</MenuItem>
                <MenuItem value="late">Late</MenuItem>
                <MenuItem value="absent">Absent</MenuItem>
              </TextField>
            </Grid>
            <Grid size={{ xs: 12, md: 2 }}>
              <TextField select fullWidth size="small" label="Source" defaultValue="all">
                <MenuItem value="all">All</MenuItem>
                <MenuItem value="fingerprint">Fingerprint</MenuItem>
                <MenuItem value="mobile-face">Mobile Face</MenuItem>
                <MenuItem value="admin">Admin</MenuItem>
              </TextField>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      <Paper sx={{ mt: 3, overflow: 'hidden' }}>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Employee</TableCell>
                <TableCell>Employee Code</TableCell>
                <TableCell>Branch</TableCell>
                <TableCell>Date</TableCell>
                <TableCell>Check In</TableCell>
                <TableCell>Check Out</TableCell>
                <TableCell>Working Hours</TableCell>
                <TableCell>Status</TableCell>
                <TableCell>Source</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={row.code} hover>
                  <TableCell>{row.employee}</TableCell>
                  <TableCell>{row.code}</TableCell>
                  <TableCell>{row.branch}</TableCell>
                  <TableCell>{row.date}</TableCell>
                  <TableCell>{row.checkIn}</TableCell>
                  <TableCell>{row.checkOut}</TableCell>
                  <TableCell>{row.hours}</TableCell>
                  <TableCell>
                    <Typography variant="body2" color={row.status === 'Present' ? 'success.main' : row.status === 'Late' ? 'warning.main' : 'error.main'} sx={{ fontWeight: 600 }}>{row.status}</Typography>
                  </TableCell>
                  <TableCell>{row.source}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>
    </div>
  )
}
