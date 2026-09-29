import apiClient from '../../../services/apiClient'

export const authApi = {
  login: async (payload) => {
    const response = await apiClient.post('/auth/admin-login/', payload)
    return response.data?.data ?? response.data
  },
}
