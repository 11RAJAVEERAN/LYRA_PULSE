import apiClient from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data
const asList = (data) => (Array.isArray(data) ? data : [])

export const DEFAULT_PAGE_SIZE = 25
export const PAGE_SIZE_OPTIONS = [25, 50, 100] // backend max_page_size is 100

// Single source of truth for turning UI state into backend query params. The list, summary and export calls all
// use it so an export always matches what the table shows. Empty / "all" values are omitted entirely.
export function buildFilterParams({ range, filters }) {
  const params = range.start === range.end
    ? { date: range.start }
    : { start_date: range.start, end_date: range.end }
  const search = filters.search?.trim()
  if (filters.branch) params.branch = filters.branch
  if (filters.department) params.department = filters.department
  if (filters.designation) params.designation = filters.designation
  if (filters.status) params.status = filters.status
  if (search) params.search = search
  return params
}

// The summary API takes no status filter (it always reports present and absent together).
export function buildSummaryParams(state) {
  const params = buildFilterParams(state)
  delete params.status
  return params
}

export const attendanceApi = {
  list: async (params, signal) => unwrap(await apiClient.get('/attendance/admin/', { params, signal })),
  summary: async (params, signal) => unwrap(await apiClient.get('/attendance/admin/summary/', { params, signal })),
  detail: async (employeeId, date, signal) =>
    unwrap(await apiClient.get(`/attendance/admin/${employeeId}/`, { params: { date }, signal })),
  // Returns { blob, filename } for the backend-generated CSV (not paginated, same filters as the list).
  exportCsv: async (params) => {
    const response = await apiClient.get('/attendance/admin/export/', { params, responseType: 'blob', timeout: 120000 })
    const disposition = response.headers?.['content-disposition'] ?? ''
    const match = /filename\*?=(?:UTF-8'')?"?([^";]+)"?/i.exec(disposition)
    return { blob: response.data, filename: match ? decodeURIComponent(match[1]) : null }
  },
  // Branch / department / designation options come from the existing scoped dropdown endpoints.
  // Inactive records are included so historical attendance can still be filtered by them.
  filterOptions: async (signal) => {
    const [branches, departments, designations] = await Promise.all(
      ['/branches/', '/departments/', '/designations/'].map((url) =>
        apiClient.get(url, { params: { include_inactive: true }, signal }),
      ),
    )
    return { branches: asList(unwrap(branches)), departments: asList(unwrap(departments)), designations: asList(unwrap(designations)) }
  },
}
