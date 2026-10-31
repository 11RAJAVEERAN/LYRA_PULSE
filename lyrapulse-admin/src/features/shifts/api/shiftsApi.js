import apiClient from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data

export const shiftsApi = {
  list: async (params, signal) => unwrap(await apiClient.get('/shifts/', { params, signal, skipBranchContext: true })),
  get: async (id, signal) => unwrap(await apiClient.get(`/shifts/${id}/`, { signal })),
  create: async (payload) => unwrap(await apiClient.post('/shifts/', payload)),
  update: async (id, payload) => unwrap(await apiClient.patch(`/shifts/${id}/`, payload)),
  listAssignments: async (params, signal) => unwrap(await apiClient.get('/shift-assignments/', { params, signal, skipBranchContext: true })),
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
  employees: async (branch, signal) => {
    const data = unwrap(await apiClient.get('/employees/', { params: branch ? { branch } : {}, signal, skipBranchContext: true }))
    return Array.isArray(data) ? data : []
  },
}

