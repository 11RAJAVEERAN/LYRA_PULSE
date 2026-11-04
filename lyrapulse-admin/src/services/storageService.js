const DEMO_AUTH_KEY = 'lyrapulse_admin_demo_auth'
const ACCESS_TOKEN_KEY = 'lyrapulse_admin_access_token'
const REFRESH_TOKEN_KEY = 'lyrapulse_admin_refresh_token'

function readDemoSession(storage) {
  try {
    const value = storage.getItem(DEMO_AUTH_KEY)
    return value ? JSON.parse(value) : null
  } catch {
    storage.removeItem(DEMO_AUTH_KEY)
    return null
  }
}

export const storageService = {
  setDemoSession: (session, rememberMe) => {
    storageService.clearDemoSession()
    const storage = rememberMe ? localStorage : sessionStorage
    storage.setItem(DEMO_AUTH_KEY, JSON.stringify(session))
  },
  getDemoSession: () => readDemoSession(localStorage) ?? readDemoSession(sessionStorage),
  clearDemoSession: () => {
    localStorage.removeItem(DEMO_AUTH_KEY)
    sessionStorage.removeItem(DEMO_AUTH_KEY)
  },
  setAuthTokens: (accessToken, refreshToken) => {
    localStorage.setItem(ACCESS_TOKEN_KEY, accessToken)
    if (refreshToken) {
      localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken)
    } else {
      localStorage.removeItem(REFRESH_TOKEN_KEY)
    }
  },
  getAccessToken: () => localStorage.getItem(ACCESS_TOKEN_KEY),
  getRefreshToken: () => localStorage.getItem(REFRESH_TOKEN_KEY),
  clearAuth: () => {
    storageService.clearDemoSession()
    localStorage.removeItem(ACCESS_TOKEN_KEY)
    localStorage.removeItem(REFRESH_TOKEN_KEY)
  },
}
