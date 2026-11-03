import apiClient from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data

async function listAllPages(path, params, signal) {
  const results = []
  let page = 1
  let totalPages = 1
  do {
    const response = unwrap(await apiClient.get(path, { params: { ...params, page, page_size: 100 }, signal, skipBranchContext: true }))
    results.push(...(response.results ?? []))
    totalPages = response.total_pages ?? page
    page += 1
  } while (page <= totalPages)
  return results
}

export const shiftsApi = {
  list: async (params, signal) => unwrap(await apiClient.get('/shifts/', { params, signal, skipBranchContext: true })),
  listAll: (params, signal) => listAllPages('/shifts/', params, signal),
  get: async (id, signal) => unwrap(await apiClient.get(`/shifts/${id}/`, { signal })),
  create: async (payload) => unwrap(await apiClient.post('/shifts/', payload)),
  update: async (id, payload) => unwrap(await apiClient.patch(`/shifts/${id}/`, payload)),
  listAssignments: async (params, signal) => unwrap(await apiClient.get('/shift-assignments/', { params, signal, skipBranchContext: true })),
  listAllAssignments: (params, signal) => listAllPages('/shift-assignments/', params, signal),
  assign: async (payload) => unwrap(await apiClient.post('/shift-assignments/', payload)),
  bulkAssign: async (payload) => unwrap(await apiClient.post('/shift-assignments/bulk/', payload)),
  history: async (employeeId, params, signal) =>
    unwrap(await apiClient.get(`/shift-assignments/history/${employeeId}/`, { params, signal })),
  branches: async (signal) => {
    const data = unwrap(await apiClient.get('/branches/', { signal }))
    return Array.isArray(data) ? data : []
  },
  departments: async (signal) => {
    const data = unwrap(await apiClient.get('/departments/', { signal }))
    return Array.isArray(data) ? data : []
  },
  designations: async (signal) => {
    const data = unwrap(await apiClient.get('/designations/', { signal }))
    return Array.isArray(data) ? data : []
  },
  employees: async (filters, signal) => {
    const params = typeof filters === 'object' && filters !== null ? filters : filters ? { branch: filters } : {}
    const data = unwrap(await apiClient.get('/employees/', { params, signal, skipBranchContext: true }))
    return Array.isArray(data) ? data : []
  },
}

