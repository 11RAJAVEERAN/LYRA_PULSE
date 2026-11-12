import apiClient from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data

export const companiesApi = {
  list: async (params) => unwrap(await apiClient.get('/organizations/', { params })),
  get: async (id) => unwrap(await apiClient.get(`/organizations/${id}/`)),
  create: async (payload) => unwrap(await apiClient.post('/organizations/', payload)),
  update: async (id, payload) => unwrap(await apiClient.patch(`/organizations/${id}/`, payload)),
  superAdmins: async (companyId) => unwrap(await apiClient.get(`/organizations/${companyId}/super-admins/`)),
  createSuperAdmin: async (companyId, payload) =>
    unwrap(await apiClient.post(`/organizations/${companyId}/super-admins/`, payload)),
  updateSuperAdmin: async (companyId, userId, payload) =>
    unwrap(await apiClient.patch(`/organizations/${companyId}/super-admins/${userId}/`, payload)),
}