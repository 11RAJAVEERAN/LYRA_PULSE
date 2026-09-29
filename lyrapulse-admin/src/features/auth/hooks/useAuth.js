import { useCallback, useMemo, useState } from 'react'
import { authService } from '../../../services/authService'

export function useAuth() {
  const [isAuthenticated, setIsAuthenticated] = useState(authService.isAuthenticated())
  const [currentUser, setCurrentUser] = useState(authService.getCurrentUser())
  const [isLoading, setIsLoading] = useState(false)

  const login = useCallback(async (payload) => {
    setIsLoading(true)

    try {
      const session = await authService.login(payload)
      setIsAuthenticated(true)
      setCurrentUser(session.user)
      return session
    } finally {
      setIsLoading(false)
    }
  }, [])

  const logout = useCallback(async () => {
    try {
      await authService.logout()
    } finally {
      setIsAuthenticated(false)
      setCurrentUser(null)
    }
  }, [])

  return useMemo(
    () => ({
      isAuthenticated,
      isLoading,
      currentUser,
      login,
      logout,
    }),
    [isAuthenticated, isLoading, currentUser, login, logout],
  )
}
