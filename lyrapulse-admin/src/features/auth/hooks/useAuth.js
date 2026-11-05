import { useCallback, useMemo, useState } from 'react'
import { authService } from '../../../services/authService'

export function useAuth() {
  const [isAuthenticated, setIsAuthenticated] = useState(authService.isAuthenticated())
  const [currentUser, setCurrentUser] = useState(authService.getCurrentUser())
  const [isLoading, setIsLoading] = useState(false)

  const sendOtp = useCallback(async (identifier) => {
    setIsLoading(true)
    try {
      return await authService.sendOtp(identifier)
    } finally {
      setIsLoading(false)
    }
  }, [])

  const verifyOtp = useCallback(async (payload) => {
    setIsLoading(true)
    try {
      const session = await authService.verifyOtp(payload)
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
      sendOtp,
      verifyOtp,
      logout,
    }),
    [isAuthenticated, isLoading, currentUser, sendOtp, verifyOtp, logout],
  )
}
