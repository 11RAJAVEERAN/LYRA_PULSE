// Column model for the Employees table. Pure data + helpers (no JSX) so sorting, filtering and the
// Edit Columns panel all work from one definition. Every field below comes from GET /employees/.

export const NONE = '__none__' // select-filter value for rows with no assignment
export const DEFAULT_ROWS_PER_PAGE = 10
export const ROWS_PER_PAGE_OPTIONS = [10, 25, 50]

const clean = (value) => (value == null ? '' : String(value).trim())
const yesNo = (value) => (value ? 'Yes' : 'No')

export const fullName = (row) => [row.first_name, row.last_name].filter(Boolean).join(' ') || clean(row.name)

export function formatDate(value) {
  if (!value) return '—'
  const date = new Date(`${value}T00:00:00`)
  if (Number.isNaN(date.getTime())) return '—'
  return date.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
}

const lookup = (map, id) => (id == null || id === '' ? '' : map.get(String(id)) ?? '')

// Pick-list option for a plain text field: one option per distinct value (case-insensitive, trimmed); blanks share one option.
const distinctOption = (field, { lower = false } = {}) => (row) => {
  const text = clean(row[field])
  if (!text) return { value: NONE, label: 'Not provided' }
  return { value: lower ? text.toLowerCase() : text, label: text }
}

// Pick-list option for a related record shown by name. Department and designation names are only unique within
// their parent (branch / department), so the same name can exist under several ids: those collapse into one option.
const relatedNameOption = (mapKey, field, noun) => (row, ctx) => {
  const id = row[field]
  if (id == null || id === '') return { value: NONE, label: 'Unassigned' }
  const name = lookup(ctx[mapKey], id)
  return name ? { value: `name:${name.toLowerCase()}`, label: name } : { value: `id:${id}`, label: `${noun} #${id}` }
}

// sort: 'text' | 'date' | 'boolean'. filter: 'text' | 'select' | 'date' | null.
// value(row, ctx): raw value used for sorting (and for date filtering).
// option(row, ctx): { value, label } used by select filters.
// haystack(row, ctx): text matched by text filters.
export const COLUMNS = [
  {
    // Filtered as a pick-list of individual employees (name + code), sortable by name or by code.
    id: 'employee', label: 'Employee', required: true, defaultVisible: true, sort: 'text', filter: 'select',
    sortOptions: [
      { id: 'employee', label: 'Employee Name wise', hint: 'Sort Alphabetically A → Z' },
      { id: 'employee_code', label: 'Employee Code wise', hint: 'Sort Alphanumerically A → Z' },
    ],
    value: (row) => fullName(row).toLowerCase(),
    option: (row) => ({ value: String(row.id), label: fullName(row) || clean(row.employee_code) || `Employee #${row.id}`, sublabel: clean(row.employee_code) }),
  },
  { id: 'employee_code', label: 'Employee Code', defaultVisible: false, sort: 'text', filter: 'select', value: (row) => clean(row.employee_code).toLowerCase(), option: distinctOption('employee_code', { lower: true }) },
  { id: 'display_name', label: 'Display Name', defaultVisible: false, sort: 'text', filter: 'select', value: (row) => clean(row.display_name).toLowerCase(), option: distinctOption('display_name', { lower: true }) },
  { id: 'phone_number', label: 'Phone Number', defaultVisible: false, sort: 'text', filter: 'select', value: (row) => clean(row.phone_number), option: distinctOption('phone_number') },
  { id: 'email', label: 'Email', defaultVisible: false, sort: 'text', filter: 'select', value: (row) => clean(row.email).toLowerCase(), option: distinctOption('email', { lower: true }) },
  {
    id: 'branch', label: 'Master Branch', defaultVisible: true, sort: 'text', filter: 'select',
    value: (row, ctx) => lookup(ctx.branches, row.branch).toLowerCase(),
    option: (row, ctx) => (row.branch == null ? { value: NONE, label: 'Unassigned' } : { value: String(row.branch), label: lookup(ctx.branches, row.branch) || `Branch #${row.branch}` }),
  },
  {
    id: 'department', label: 'Department', defaultVisible: false, sort: 'text', filter: 'select',
    value: (row, ctx) => lookup(ctx.departments, row.department).toLowerCase(),
    option: relatedNameOption('departments', 'department', 'Department'),
  },
  {
    // "Roles" = the employee's designation (department shown as the secondary line).
    id: 'roles', label: 'Roles', defaultVisible: true, sort: 'text', filter: 'select',
    value: (row, ctx) => lookup(ctx.designations, row.designation).toLowerCase(),
    option: relatedNameOption('designations', 'designation', 'Designation'),
  },
  { id: 'joining_date', label: 'Date of Joining', defaultVisible: true, sort: 'date', filter: 'date', value: (row) => row.joining_date || null },
  {
    id: 'status', label: 'Tags', defaultVisible: true, sort: 'text', filter: 'select',
    value: (row) => (row.is_active ? 'active' : 'inactive'),
    option: (row) => (row.is_active ? { value: 'active', label: 'Active' } : { value: 'inactive', label: 'Inactive' }),
  },
  { id: 'date_of_birth', label: 'Date of Birth', defaultVisible: false, sort: 'date', filter: 'date', value: (row) => row.date_of_birth || null },
  {
    id: 'door_lock_permission', label: 'Door Lock Permission', defaultVisible: false, sort: 'boolean', filter: 'select',
    value: (row) => (row.door_lock_permission == null ? null : Boolean(row.door_lock_permission)),
    option: (row) => (row.door_lock_permission == null ? { value: NONE, label: 'Not set' } : { value: yesNo(row.door_lock_permission), label: yesNo(row.door_lock_permission) }),
  },
  { id: 'pf_number', label: 'PF Number', defaultVisible: false, sort: 'text', filter: 'select', value: (row) => clean(row.pf_number), option: distinctOption('pf_number') },
  { id: 'uan_number', label: 'UAN', defaultVisible: false, sort: 'text', filter: 'select', value: (row) => clean(row.uan_number), option: distinctOption('uan_number') },
  { id: 'esic_number', label: 'ESIC', defaultVisible: false, sort: 'text', filter: 'select', value: (row) => clean(row.esic_number), option: distinctOption('esic_number') },
  { id: 'emergency_contact_name', label: 'Emergency Contact Name', defaultVisible: false, sort: 'text', filter: 'select', value: (row) => clean(row.emergency_contact_name).toLowerCase(), option: distinctOption('emergency_contact_name', { lower: true }) },
  { id: 'emergency_contact_number', label: 'Emergency Mobile', defaultVisible: false, sort: 'text', filter: 'select', value: (row) => clean(row.emergency_contact_number), option: distinctOption('emergency_contact_number') },
  { id: 'emergency_contact_relation', label: 'Emergency Relation', defaultVisible: false, sort: 'text', filter: 'select', value: (row) => clean(row.emergency_contact_relation).toLowerCase(), option: distinctOption('emergency_contact_relation', { lower: true }) },
  { id: 'address', label: 'Address', defaultVisible: false, sort: null, filter: 'text', value: (row) => clean(row.address).toLowerCase(), haystack: (row) => clean(row.address) },
]

export const COLUMN_IDS = COLUMNS.map((column) => column.id)
export const REQUIRED_COLUMN_IDS = COLUMNS.filter((column) => column.required).map((column) => column.id)
export const DEFAULT_VISIBLE_IDS = COLUMNS.filter((column) => column.defaultVisible).map((column) => column.id)
export const columnById = (id) => COLUMNS.find((column) => column.id === id)

// A sort is usable while its own column is visible, or while the Employee column (whose sort popover offers it) is.
export const isSortAvailable = (sortId, visibleSet) => visibleSet.has(sortId) || (visibleSet.has('employee') && columnById('employee').sortOptions.some((option) => option.id === sortId))

// ---------- search ----------
export function matchesSearch(row, query) {
  const needle = query.trim().toLowerCase()
  if (!needle) return true
  return [fullName(row), row.display_name, row.employee_code, row.phone_number, row.email].map(clean).join(' ').toLowerCase().includes(needle)
}

// ---------- filters ----------
// Filter value shapes: text -> string, select -> string[], date -> { from, to } (ISO yyyy-mm-dd).
export function isFilterActive(column, value) {
  if (!column.filter || value == null) return false
  if (column.filter === 'text') return clean(value) !== ''
  if (column.filter === 'select') return Array.isArray(value) && value.length > 0
  return Boolean(value.from || value.to)
}

export function rowMatchesFilter(row, column, value, ctx) {
  if (column.filter === 'text') return column.haystack(row, ctx).toLowerCase().includes(clean(value).toLowerCase())
  if (column.filter === 'select') return value.includes(column.option(row, ctx).value)
  const date = column.value(row, ctx)
  if (!date) return false // rows without a date never satisfy an active date range
  return (!value.from || date >= value.from) && (!value.to || date <= value.to)
}

export function applyFilters(rows, filters, ctx) {
  const active = COLUMNS.filter((column) => isFilterActive(column, filters[column.id]))
  if (active.length === 0) return rows
  return rows.filter((row) => active.every((column) => rowMatchesFilter(row, column, filters[column.id], ctx)))
}

export function selectOptions(rows, column, ctx) {
  if (column.filter === 'date') {
    // Distinct dates present in the data, newest first (feeds the "specific date" picker).
    return [...new Set(rows.map((row) => column.value(row, ctx)).filter(Boolean))].sort().reverse().map((iso) => ({ value: iso, label: formatDate(iso) }))
  }
  const seen = new Map()
  rows.forEach((row) => {
    const option = column.option(row, ctx)
    if (!seen.has(option.value)) seen.set(option.value, option)
  })
  return [...seen.values()].sort((a, b) => a.label.localeCompare(b.label, undefined, { numeric: true, sensitivity: 'base' }))
}

export function describeFilter(column, value, ctx, rows) {
  if (column.filter === 'text') return `“${clean(value)}”`
  if (column.filter === 'date') return [value.from ? formatDate(value.from) : '…', value.to ? formatDate(value.to) : '…'].join(' – ')
  const labels = new Map(selectOptions(rows, column, ctx).map((option) => [option.value, option.label]))
  const names = value.map((item) => labels.get(item) ?? item)
  return names.length > 2 ? `${names.slice(0, 2).join(', ')} +${names.length - 2}` : names.join(', ')
}

// ---------- sorting ----------
// Missing values always sort last, in both directions. Dates are compared as ISO strings (not formatted text).
export function sortRows(rows, sort, ctx) {
  const column = sort?.id ? columnById(sort.id) : null
  if (!column || !column.sort) return rows
  const direction = sort.dir === 'desc' ? -1 : 1
  const isMissing = (value) => value == null || value === ''
  return [...rows].sort((a, b) => {
    const left = column.value(a, ctx)
    const right = column.value(b, ctx)
    if (isMissing(left) && isMissing(right)) return 0
    if (isMissing(left)) return 1
    if (isMissing(right)) return -1
    let result
    if (column.sort === 'boolean') result = Number(left) - Number(right)
    else if (column.sort === 'date') result = left < right ? -1 : left > right ? 1 : 0
    else result = String(left).localeCompare(String(right), undefined, { numeric: true, sensitivity: 'base' })
    return result * direction
  })
}

// ---------- saved column settings ----------
export function normalizeVisibleIds(ids) {
  const wanted = new Set([...(Array.isArray(ids) ? ids : []), ...REQUIRED_COLUMN_IDS])
  return COLUMN_IDS.filter((id) => wanted.has(id)) // keeps the canonical column order, drops unknown ids
}