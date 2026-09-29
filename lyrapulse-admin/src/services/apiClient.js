import axios from 'axios'
import { apiConfig } from '../app/config/apiConfig'
import { storageService } from './storageService'

const apiClient = axios.create({
  baseURL: apiConfig.baseUrl,
  timeout: apiConfig.timeout,
  headers: {
    'Content-Type': 'application/json',
  },
})

apiClient.interceptors.request.use((config) => {
  const token = storageService.getAccessToken()

  if (token && config.headers) {
    config.headers.Authorization = `Bearer ${token}`
  }

  return config
})

apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401 && apiConfig.refreshEnabled && !error.config?._retry) {
      const refreshToken = storageService.getRefreshToken()

      if (refreshToken) {
        try {
          const refreshResponse = await axios.post(`${apiConfig.baseUrl}/auth/token/refresh/`, {
            refresh: refreshToken,
          })

          const refreshData = refreshResponse.data?.data ?? refreshResponse.data
          const nextToken = refreshData?.access
          if (nextToken) {
            storageService.setAuthTokens(nextToken, refreshData.refresh ?? refreshToken)
            if (error.config) {
              error.config._retry = true
              error.config.headers = error.config.headers ?? {}
              error.config.headers.Authorization = `Bearer ${nextToken}`
              return apiClient.request(error.config)
            }
          }
        } catch {
          storageService.clearAuth()
          window.location.href = '/login'
        }
      }
    }

    return Promise.reject(error)
  },
)

export default apiClient
