import { Box, Button, Card, CardContent, Grid, MenuItem, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, TextField, Typography } from '@mui/material'
import { useState } from 'react'
import { PageHeader } from '../../../components/common/PageHeader'
import { SearchInput } from '../../../components/common/SearchInput'

const rows = [
  { name: 'Alicia Turner', code: 'LYR-201', phone: '+91 98765 43210', email: 'alicia@lyratech.com', department: 'HR', status: 'Active' },
  { name: 'Rohit Sharma', code: 'LYR-185', phone: '+91 99887 66554', email: 'rohit@lyratech.com', department: 'Engineering', status: 'Active' },
  { name: 'Meera Nair', code: 'LYR-947', phone: '+91 98111 22334', email: 'meera@lyratech.com', department: 'Operations', status: 'Inactive' },
]

export function EmployeesPage() {
  const [query, setQuery] = useState('')

  return (
    <div>
      <PageHeader
        title="Employees"
        subtitle="Manage workforce details and employee records"
        action={<Button variant="contained">Add Employee</Button>}
      />

      <Card>
        <CardContent sx={{ p: 2.5 }}>
          <Grid container spacing={2} sx={{ alignItems: 'center' }}>
            <Grid size={{ xs: 12, md: 4 }}>
              <SearchInput value={query} onChange={setQuery} placeholder="Search employee" />
            </Grid>
            <Grid size={{ xs: 12, md: 2 }}>
              <TextField select fullWidth size="small" label="Department" defaultValue="all">
                <MenuItem value="all">All</MenuItem>
                <MenuItem value="hr">HR</MenuItem>
                <MenuItem value="engineering">Engineering</MenuItem>
              </TextField>
            </Grid>
            <Grid size={{ xs: 12, md: 2 }}>
              <TextField select fullWidth size="small" label="Status" defaultValue="all">
                <MenuItem value="all">All</MenuItem>
                <MenuItem value="active">Active</MenuItem>
                <MenuItem value="inactive">Inactive</MenuItem>
              </TextField>
            </Grid>
            <Grid size={{ xs: 12, md: 2 }}>
              <TextField select fullWidth size="small" label="Branch" defaultValue="all">
                <MenuItem value="all">All</MenuItem>
                <MenuItem value="head-office">Head Office</MenuItem>
                <MenuItem value="bengaluru">Bengaluru</MenuItem>
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
                <TableCell>Phone</TableCell>
                <TableCell>Email</TableCell>
                <TableCell>Department</TableCell>
                <TableCell>Status</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={row.code} hover>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                      <Typography variant="body1" sx={{ fontWeight: 600 }}>{row.name}</Typography>
                    </Box>
                  </TableCell>
                  <TableCell>{row.code}</TableCell>
                  <TableCell>{row.phone}</TableCell>
                  <TableCell>{row.email}</TableCell>
                  <TableCell>{row.department}</TableCell>
                  <TableCell>
                    <Typography variant="body2" color={row.status === 'Active' ? 'success.main' : 'text.secondary'} sx={{ fontWeight: 600 }}>
                      {row.status}
                    </Typography>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>
    </div>
  )
}
