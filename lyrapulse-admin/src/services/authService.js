import { storageService } from './storageService'
import { authApi } from '../features/auth/api/authApi'
import apiClient from './apiClient'

export const authService = {
  async login({ email, password, rememberMe = false }) {
    try {
      const session = await authApi.login({ email: email.trim(), password })
      if (!session?.access || !session?.refresh || !session?.user) {
        throw new Error('The server returned an incomplete login response.')
      }
      storageService.setAuthTokens(session.access, session.refresh, session.user, rememberMe)
      return session
    } catch (error) {
      const message = error.response?.data?.detail
        ?? error.response?.data?.message
        ?? error.message
        ?? 'Unable to sign in.'
      throw new Error(message)
    }
  },
  async logout() {
    const refresh = storageService.getRefreshToken()
    try {
      if (refresh) await apiClient.post('/auth/logout/', { refresh })
    } catch {
      // The local session still needs to end if the API is unreachable.
    } finally {
      storageService.clearAuth()
    }
  },
  isAuthenticated() {
    return Boolean(storageService.getAccessToken())
  },
  getCurrentUser() {
    return storageService.getCurrentUser()
  },
}
