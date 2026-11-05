import { Navigate } from 'react-router-dom'
import { authService } from '../../services/authService'

export function SuperAdminRoute({ children }) {
  return authService.getCurrentUser()?.role === 'SUPERADMIN' ? children : <Navigate to="/dashboard" replace />
}