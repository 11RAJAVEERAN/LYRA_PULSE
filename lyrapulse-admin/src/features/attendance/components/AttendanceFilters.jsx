import { Box, MenuItem, TextField } from '@mui/material'
import { SearchInput } from '../../../components/common/SearchInput'

const STATUS_OPTIONS = [
  { value: '', label: 'All Status' },
  { value: 'present', label: 'Present' },
  { value: 'absent', label: 'Absent' },
]

function FilterSelect({ label, value, onChange, allLabel, options, disabled }) {
  return (
    <TextField
      select size="small" value={value} onChange={(event) => onChange(event.target.value)}
      disabled={disabled} sx={{ minWidth: 168 }}
      slotProps={{ htmlInput: { 'aria-label': label }, select: { displayEmpty: true } }}
    >
      <MenuItem value="">{allLabel}</MenuItem>
      {options.map((option) => (
        <MenuItem key={option.id} value={String(option.id)}>{option.name}</MenuItem>
      ))}
    </TextField>
  )
}

export function AttendanceFilters({ search, onSearch, filters, onFilter, options, optionsLoading }) {
  const departments = filters.branch
    ? options.departments.filter((item) => String(item.branch) === filters.branch)
    : options.departments
  const designations = filters.department
    ? options.designations.filter((item) => String(item.department) === filters.department)
    : options.designations
  // A single branch needs no selector; the backend already scopes results to the user's branches.
  const showBranch = options.branches.length > 1

  return (
    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1.5, p: 2 }}>
      <Box sx={{ flex: '1 1 260px', minWidth: 220, maxWidth: 420 }}>
        <SearchInput value={search} onChange={onSearch} placeholder="Search by employee name or ID..." label="Search attendance by employee name or ID" />
      </Box>
      {showBranch ? (
        <FilterSelect label="Filter by branch" value={filters.branch} onChange={(value) => onFilter({ branch: value })} allLabel="All Branches" options={options.branches} disabled={optionsLoading} />
      ) : null}
      <FilterSelect label="Filter by department" value={filters.department} onChange={(value) => onFilter({ department: value })} allLabel="All Departments" options={departments} disabled={optionsLoading} />
      <FilterSelect label="Filter by designation" value={filters.designation} onChange={(value) => onFilter({ designation: value })} allLabel="All Designations" options={designations} disabled={optionsLoading} />
      <TextField
        select size="small" value={filters.status} onChange={(event) => onFilter({ status: event.target.value })}
        sx={{ minWidth: 140 }} slotProps={{ htmlInput: { 'aria-label': 'Filter by status' }, select: { displayEmpty: true } }}
      >
        {STATUS_OPTIONS.map((option) => (
          <MenuItem key={option.value} value={option.value}>{option.label}</MenuItem>
        ))}
      </TextField>
    </Box>
  )
}
