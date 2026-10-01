import apiClient from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data

export const adminUsersApi = {
  list: async () => unwrap(await apiClient.get('/auth/admin/users/')),
  create: async (payload) => unwrap(await apiClient.post('/auth/admin/users/', payload)),
  update: async (id, payload) => unwrap(await apiClient.patch(`/auth/admin/users/${id}/`, payload)),
}