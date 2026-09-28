import { storageService } from './storageService'

export const authService = {
  async login({ email, password, rememberMe = false }) {
    if (!import.meta.env.DEV) {
      throw new Error('Production authentication is not configured.')
    }

    const { DEMO_ADMIN } = await import('../features/auth/config/demoAuth')
    const emailMatches = email.trim().toLowerCase() === DEMO_ADMIN.email.toLowerCase()
    if (!emailMatches || password !== DEMO_ADMIN.password) {
      throw new Error('Invalid email or password')
    }

    const session = {
      authenticated: true,
      user: {
        name: DEMO_ADMIN.name,
        email: DEMO_ADMIN.email,
        role: DEMO_ADMIN.role,
      },
    }

    storageService.setDemoSession(session, rememberMe)
    return session
  },
  logout() {
    storageService.clearAuth()
  },
  isAuthenticated() {
    if (!import.meta.env.DEV) {
      return Boolean(storageService.getAccessToken())
    }

    const session = storageService.getDemoSession()
    return Boolean(session?.authenticated && session.user) || Boolean(storageService.getAccessToken())
  },
  getCurrentUser() {
    if (!import.meta.env.DEV) {
      return null
    }

    return storageService.getDemoSession()?.user ?? null
  },
}