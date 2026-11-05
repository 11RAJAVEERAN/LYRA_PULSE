import apiClient from '../../../services/apiClient'

export const authApi = {
  sendOtp: async (payload) => {
    const response = await apiClient.post('/auth/admin/send-otp/', payload)
    return response.data?.data ?? response.data
  },
  verifyOtp: async (payload) => {
    const response = await apiClient.post('/auth/admin/verify-otp/', payload)
    return response.data?.data ?? response.data
  },
}
