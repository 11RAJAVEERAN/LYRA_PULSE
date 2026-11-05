const ACCESS_TOKEN_KEY = 'lyrapulse_admin_access_token'
const REFRESH_TOKEN_KEY = 'lyrapulse_admin_refresh_token'
const USER_KEY = 'lyrapulse_admin_user'

function readUser(storage) {
  try {
    const value = storage.getItem(USER_KEY)
    return value ? JSON.parse(value) : null
  } catch {
    storage.removeItem(USER_KEY)
    return null
  }
}

export const storageService = {
  setAuthTokens: (accessToken, refreshToken, user, rememberMe) => {
    const storage = rememberMe === undefined
      ? (localStorage.getItem(REFRESH_TOKEN_KEY) ? localStorage : sessionStorage)
      : (rememberMe ? localStorage : sessionStorage)
    const otherStorage = storage === localStorage ? sessionStorage : localStorage
    otherStorage.removeItem(ACCESS_TOKEN_KEY)
    otherStorage.removeItem(REFRESH_TOKEN_KEY)
    otherStorage.removeItem(USER_KEY)
    storage.setItem(ACCESS_TOKEN_KEY, accessToken)
    if (refreshToken) {
      storage.setItem(REFRESH_TOKEN_KEY, refreshToken)
    } else {
      storage.removeItem(REFRESH_TOKEN_KEY)
    }
    if (user) storage.setItem(USER_KEY, JSON.stringify(user))
  },
  getAccessToken: () => localStorage.getItem(ACCESS_TOKEN_KEY) ?? sessionStorage.getItem(ACCESS_TOKEN_KEY),
  getRefreshToken: () => localStorage.getItem(REFRESH_TOKEN_KEY) ?? sessionStorage.getItem(REFRESH_TOKEN_KEY),
  getCurrentUser: () => readUser(localStorage) ?? readUser(sessionStorage),
  clearAuth: () => {
    localStorage.removeItem(ACCESS_TOKEN_KEY)
    localStorage.removeItem(REFRESH_TOKEN_KEY)
    localStorage.removeItem(USER_KEY)
    sessionStorage.removeItem(ACCESS_TOKEN_KEY)
    sessionStorage.removeItem(REFRESH_TOKEN_KEY)
    sessionStorage.removeItem(USER_KEY)
  },
}
