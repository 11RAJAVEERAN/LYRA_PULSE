import { Navigate, Outlet, useLocation } from 'react-router-dom'
import { authService } from '../../services/authService'

export function ProtectedRoute() {
  const location = useLocation()
  const isAuthenticated = authService.isAuthenticated()

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />
  }

  return <Outlet />
}
