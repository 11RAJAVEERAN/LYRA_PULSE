
import { Navigate } from 'react-router-dom'

import { LoginPage } from '../../features/auth/pages/LoginPage'
import { DashboardPage } from '../../features/dashboard/pages/DashboardPage'
import { AttendancePage } from '../../features/attendance/pages/AttendancePage'
import { EmployeesPage } from '../../features/employees/pages/EmployeesPage'
import { AdminUsersPage } from '../../features/adminUsers/pages/AdminUsersPage'
import { DevicesPage } from '../../features/devices/pages/DevicesPage'
import { AttendancePermissionsPage } from '../../features/attendancePermissions/pages/AttendancePermissionsPage'

import { ROUTES } from '../../constants/routes'
import { ProtectedRoute } from './ProtectedRoute'
import { SuperAdminRoute } from './SuperAdminRoute'
import { AdminLayout } from '../../components/layout/AdminLayout'

// Reports pages
import AttendanceMasterPage from '../../reports/AttendanceMasterPage'
import DailyPunchReportPage from '../../reports/DailyPunchReportPage'
import ShiftWiseReportPage from '../../reports/ShiftWiseReportPage'

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
          {
            path: ROUTES.devices,
            element: <DevicesPage />,
          },
          {
            path: ROUTES.permissions,
            element: <AttendancePermissionsPage />,
          },
          {
            path: ROUTES.adminUsers,
            element: (
              <SuperAdminRoute>
                <AdminUsersPage />
              </SuperAdminRoute>
            ),
          },

          // Reports
          {
            path: 'reports/attendance-master',
            element: <AttendanceMasterPage />,
          },
          {
            path: 'reports/daily-punch-report',
            element: <DailyPunchReportPage />,
          },
          {
            path: 'reports/shift-wise-report',
            element: <ShiftWiseReportPage />,
          },

          ...[
            ROUTES.leaves,
            ROUTES.branches,
            ROUTES.departments,
            ROUTES.designations,
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

