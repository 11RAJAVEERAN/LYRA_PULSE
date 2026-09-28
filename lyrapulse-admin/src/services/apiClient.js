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
    if (error.response?.status === 401 && apiConfig.refreshEnabled) {
      const refreshToken = storageService.getRefreshToken()

      if (refreshToken) {
        try {
          const refreshResponse = await axios.post(`${apiConfig.baseUrl}/auth/refresh/`, {
            refresh: refreshToken,
          })

          const nextToken = refreshResponse.data?.access ?? refreshResponse.data?.token
          if (nextToken) {
            storageService.setAuthTokens(nextToken, refreshToken)
            if (error.config) {
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
