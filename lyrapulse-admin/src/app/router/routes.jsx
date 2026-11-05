import { Navigate } from 'react-router-dom'
import { LoginPage } from '../../features/auth/pages/LoginPage'
import { DashboardPage } from '../../features/dashboard/pages/DashboardPage'
import { AttendancePage } from '../../features/attendance/pages/AttendancePage'
import { EmployeesPage } from '../../features/employees/pages/EmployeesPage'
import { ROUTES } from '../../constants/routes'
import { ProtectedRoute } from './ProtectedRoute'
import { AdminLayout } from '../../components/layout/AdminLayout'
import { AdminUsersPage } from '../../features/adminUsers/pages/AdminUsersPage'
import { SuperAdminRoute } from './SuperAdminRoute'
import { DevicesPage } from '../../features/devices/pages/DevicesPage'
import { AttendancePermissionsPage } from '../../features/attendancePermissions/pages/AttendancePermissionsPage'
import { DepartmentsPage } from '../../features/departments/pages/DepartmentsPage'
import { DesignationsPage } from '../../features/designations/pages/DesignationsPage'
import { ShiftsPage } from '../../features/shifts/pages/ShiftsPage'
import { ShiftAssignmentsPage } from '../../features/shifts/pages/ShiftAssignmentsPage'

export const routes = [
  {
    path: ROUTES.login,
    element: <LoginPage />,
  },
  {
    path: '/',
    element: <ProtectedRoute />,
    children: [
      {
        element: <AdminLayout />,
        children: [
          {
            index: true,
            element: <Navigate to={ROUTES.dashboard} replace />,
          },
          {
            path: ROUTES.dashboard,
            element: <DashboardPage />,
          },
          {
            path: ROUTES.employees,
            element: <EmployeesPage />,
          },
          {
            path: ROUTES.attendance,
            element: <AttendancePage />,
          },
          { path: ROUTES.shifts, element: <ShiftsPage /> },
          { path: ROUTES.shiftAssignments, element: <ShiftAssignmentsPage /> },
          {
            path: ROUTES.devices,
            element: <DevicesPage />,
          },
          {
            path: ROUTES.permissions,
            element: <AttendancePermissionsPage />,
          },
          {
            path: ROUTES.departments,
            element: <DepartmentsPage />,
          },
          {
            path: ROUTES.designations,
            element: <DesignationsPage />,
          },
          {
            path: ROUTES.adminUsers,
            element: <SuperAdminRoute><AdminUsersPage /></SuperAdminRoute>,
          },
          ...[
            ROUTES.leaves,
            ROUTES.branches,
            ROUTES.reports,
            ROUTES.settings,
          ].map((path) => ({
            path,
            element: <Navigate to={ROUTES.dashboard} replace />,
          })),
          {
            path: '*',
            element: <Navigate to={ROUTES.dashboard} replace />,
          },
        ],
      },
    ],
  },
]

