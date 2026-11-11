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
import AttendanceMasterPage from '../../reports/AttendanceMasterPage'
import DailyPunchReportPage from '../../reports/DailyPunchReportPage'
import ShiftWiseReportPage from '../../reports/ShiftWiseReportPage'
import WorkingHoursReportPage from '../../reports/WorkingHoursReportPage'
import MusterReportPage from '../../reports/MusterReportPage'
import BranchWisePunchReportPage from '../../reports/BranchWisePunchReportPage'
import LeaveTakenReportPage from '../../reports/LeaveTakenReportPage'
import { BulkAttendanceAdjustmentsPage } from '../../features/payroll/pages/BulkAttendanceAdjustmentsPage'

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
          { path: ROUTES.bulkAttendanceAdjustments, element: <BulkAttendanceAdjustmentsPage /> },
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
          { path: ROUTES.reports, element: <Navigate to="/reports/attendance-master" replace /> },
          { path: '/reports/attendance-master', element: <AttendanceMasterPage /> },
          { path: '/reports/daily-punch-report', element: <DailyPunchReportPage /> },
          { path: '/reports/shift-wise-report', element: <ShiftWiseReportPage /> },
          { path: '/reports/working-hours', element: <WorkingHoursReportPage /> },
          { path: '/reports/muster-report', element: <MusterReportPage /> },
          { path: '/reports/branch-wise-punch', element: <BranchWisePunchReportPage /> },
          { path: '/reports/leave-taken', element: <LeaveTakenReportPage /> },
          ...[
            ROUTES.leaves,
            ROUTES.branches,
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
