import apiClient from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data

export const branchesApi = {
  list: async (params) => unwrap(await apiClient.get('/branches/', { params })),
  get: async (id) => unwrap(await apiClient.get(`/branches/${id}/`)),
  create: async (payload) => unwrap(await apiClient.post('/branches/', payload)),
  update: async (id, payload) => unwrap(await apiClient.patch(`/branches/${id}/`, payload)),
  updateAttendanceRadius: async (id, payload) =>
    unwrap(await apiClient.patch(`/branches/${id}/attendance-radius/`, payload)),
}