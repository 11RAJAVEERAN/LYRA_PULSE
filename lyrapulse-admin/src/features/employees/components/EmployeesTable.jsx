import { Box, Button, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Typography } from '@mui/material'
import { StatusChip } from '../../../components/common/StatusChip'
import { fullName, formatDate, selectOptions } from '../employeeColumns'
import { ColumnHeader, headCellSx } from './ColumnHeader'

const dash = '—'
const textOrDash = (value) => (value == null || value === '' ? dash : value)

function Secondary({ children }) {
  return <Typography variant="caption" color="text.secondary" sx={{ display: 'block', lineHeight: 1.3, fontVariantNumeric: 'tabular-nums' }}>{children}</Typography>
}

// How each column renders a row. Keys match column ids in employeeColumns.js.
const cells = {
  employee: (row) => (
    <Box sx={{ minWidth: 0 }}>
      <Typography variant="body2" sx={{ fontWeight: 600, color: 'text.primary', lineHeight: 1.35 }} noWrap>{fullName(row) || dash}</Typography>
      {row.employee_code ? <Secondary>{row.employee_code}</Secondary> : null}
    </Box>
  ),
  employee_code: (row) => textOrDash(row.employee_code),
  display_name: (row) => textOrDash(row.display_name),
  phone_number: (row) => textOrDash(row.phone_number),
  email: (row) => textOrDash(row.email),
  branch: (row, ctx) => textOrDash(ctx.branches.get(String(row.branch))),
  department: (row, ctx) => textOrDash(ctx.departments.get(String(row.department))),
  roles: (row, ctx) => {
    const designation = ctx.designations.get(String(row.designation))
    const department = ctx.departments.get(String(row.department))
    if (!designation) return dash
    return <Box><Typography variant="body2">{designation}</Typography>{department ? <Secondary>{department}</Secondary> : null}</Box>
  },
  joining_date: (row) => formatDate(row.joining_date),
  status: (row) => <StatusChip label={row.is_active ? 'Active' : 'Inactive'} />,
  date_of_birth: (row) => formatDate(row.date_of_birth),
  door_lock_permission: (row) => (row.door_lock_permission == null ? dash : row.door_lock_permission ? 'Yes' : 'No'),
  pf_number: (row) => textOrDash(row.pf_number),
  uan_number: (row) => textOrDash(row.uan_number),
  esic_number: (row) => textOrDash(row.esic_number),
  emergency_contact_name: (row) => textOrDash(row.emergency_contact_name),
  emergency_contact_number: (row) => textOrDash(row.emergency_contact_number),
  emergency_contact_relation: (row) => textOrDash(row.emergency_contact_relation),
  address: (row) => (row.address ? <Typography variant="body2" noWrap sx={{ maxWidth: 260 }} title={row.address}>{row.address}</Typography> : dash),
}

export function EmployeesTable({ rows, allRows, columns, ctx, sort, onSort, onSortTo, filters, onFilterChange, canEdit, onEdit }) {
  return (
    <TableContainer sx={{ border: 0, borderRadius: 0 }}>
      <Table aria-label="Employees" size="small" sx={{ minWidth: 640 }}>
        <TableHead>
          <TableRow>
            {columns.map((column) => (
              <ColumnHeader
                key={column.id}
                column={column}
                sort={sort}
                onSort={onSort}
                onSortTo={onSortTo}
                filterValue={filters[column.id]}
                onFilterChange={onFilterChange}
                options={column.filter === 'select' || column.filter === 'date' ? selectOptions(allRows, column, ctx) : undefined}
              />
            ))}
            <TableCell align="right" sx={headCellSx}>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {rows.map((row) => (
            <TableRow key={row.id} hover sx={{ '& td': { py: 1, px: 1.5, fontSize: '0.875rem' } }}>
              {columns.map((column) => (
                <TableCell key={column.id}>{cells[column.id](row, ctx)}</TableCell>
              ))}
              <TableCell align="right">
                {canEdit ? <Button size="small" onClick={() => onEdit(row)} aria-label={`Edit ${fullName(row) || row.employee_code}`}>Edit</Button> : null}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  )
}