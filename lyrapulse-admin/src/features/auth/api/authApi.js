import apiClient from '../../../services/apiClient'

export const authApi = {
  login: async (payload) => {
    const response = await apiClient.post('/auth/login/', payload)
    return response.data
  },
}
