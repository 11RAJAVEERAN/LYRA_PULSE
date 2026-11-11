import { Navigate } from 'react-router-dom'
import { LoginPage } from '../../features/auth/pages/LoginPage'
import { DashboardPage } from '../../features/dashboard/pages/DashboardPage'
import { AttendancePage } from '../../features/attendance/pages/AttendancePage'
import { EmployeesPage } from '../../features/employees/pages/EmployeesPage'
import { ROUTES } from '../../constants/routes'
import { ProtectedRoute } from './ProtectedRoute'
import { AdminLayout } from '../../components/layout/AdminLayout'
import { AdminUsersPage } from '../../features/adminUsers/pages/AdminUsersPage'
import { DevicesPage } from '../../features/devices/pages/DevicesPage'
import { AttendancePermissionsPage } from '../../features/attendancePermissions/pages/AttendancePermissionsPage'
import { DepartmentsPage } from '../../features/departments/pages/DepartmentsPage'
import { DesignationsPage } from '../../features/designations/pages/DesignationsPage'
import { ShiftsPage } from '../../features/shifts/pages/ShiftsPage'
import { ShiftAssignmentsPage } from '../../features/shifts/pages/ShiftAssignmentsPage'
import { CompaniesPage } from '../../features/companies/pages/CompaniesPage'
import { BranchesPage } from '../../features/branches/pages/BranchesPage'
import { PermissionRoute } from './PermissionRoute'

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
            element: <PermissionRoute permission="employees.view_employee"><EmployeesPage /></PermissionRoute>,
          },
          {
            path: ROUTES.attendance,
            element: <PermissionRoute permission="employees.view_employee"><AttendancePage /></PermissionRoute>,
          },
          { path: ROUTES.shifts, element: <PermissionRoute permission="shifts.view_shift"><ShiftsPage /></PermissionRoute> },
          { path: ROUTES.shiftAssignments, element: <PermissionRoute permission="shifts.view_shift"><ShiftAssignmentsPage /></PermissionRoute> },
          {
            path: ROUTES.devices,
            element: <PermissionRoute roles={['SUPERADMIN', 'ADMIN']}><DevicesPage /></PermissionRoute>,
          },
          {
            path: ROUTES.permissions,
            element: <PermissionRoute roles={['SUPERADMIN', 'ADMIN']}><AttendancePermissionsPage /></PermissionRoute>,
          },
          {
            path: ROUTES.departments,
            element: <PermissionRoute permission="employees.view_employee"><DepartmentsPage /></PermissionRoute>,
          },
          {
            path: ROUTES.designations,
            element: <PermissionRoute permission="employees.view_employee"><DesignationsPage /></PermissionRoute>,
          },
          {
            path: ROUTES.adminUsers,
            element: <PermissionRoute roles={['SUPERADMIN']}><AdminUsersPage /></PermissionRoute>,
          },
          {
            path: ROUTES.companies,
            element: <PermissionRoute roles={['SUPERADMIN']}><CompaniesPage /></PermissionRoute>,
          },
          {
            path: ROUTES.branches,
            element: <PermissionRoute roles={['SUPERADMIN', 'ADMIN']}><BranchesPage /></PermissionRoute>,
          },
          ...[
            ROUTES.leaves,
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
