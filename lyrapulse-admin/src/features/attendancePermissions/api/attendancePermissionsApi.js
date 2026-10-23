import apiClient from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data

export const attendancePermissionsApi = {
  list: async (params) => unwrap(await apiClient.get('/attendance-permissions/', { params })),
  get: async (id) => unwrap(await apiClient.get(`/attendance-permissions/${id}/`)),
  update: async (id, permissions) => unwrap(await apiClient.patch(`/attendance-permissions/${id}/`, permissions)),
  bulkUpdate: async (employeeIds, permissions) => unwrap(await apiClient.post('/attendance-permissions/bulk/', {
    employee_ids: employeeIds,
    permissions,
  })),
  branches: async () => {
    const data = unwrap(await apiClient.get('/branches/'))
    return Array.isArray(data) ? data : []
  },
}
