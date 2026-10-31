import { Box, Drawer, useMediaQuery, useTheme } from '@mui/material'
import { useState } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import { Sidebar } from './Sidebar'
import { Topbar } from './Topbar'

const pageTitles = {
  '/dashboard': 'Dashboard',
  '/employees': 'Employees',
  '/attendance': 'Attendance',
  '/shifts': 'Shifts',
  '/shift-assignments': 'Shift Assignments',
  '/admin-users': 'Admin users',
  '/leaves': 'Leaves',
  '/permissions': 'Permissions',
  '/branches': 'Branches',
  '/departments': 'Departments',
  '/designations': 'Designations',
  '/devices': 'Devices',
  '/reports': 'Reports',
  '/settings': 'Settings',
}

export function AdminLayout() {
  const theme = useTheme()
  const location = useLocation()
  const isMobile = useMediaQuery(theme.breakpoints.down('md'))
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const [collapsed, setCollapsed] = useState(false)

  const sidebarContent = (
    <Sidebar
      collapsed={isMobile ? false : collapsed}
      belowHeader={!isMobile}
      onToggle={!isMobile ? () => setCollapsed((value) => !value) : undefined}
      onNavigate={() => setSidebarOpen(false)}
    />
  )

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', width: '100%', maxWidth: '100%', minHeight: '100vh', overflowX: 'clip', backgroundColor: 'background.default' }}>
      <Topbar
        title={pageTitles[location.pathname] ?? 'LYRA PULSE'}
        onMenu={() => setSidebarOpen(true)}
        showMenu={isMobile}
        collapsed={collapsed}
        onToggle={!isMobile ? () => setCollapsed((value) => !value) : undefined}
      />

      <Box sx={{ display: 'flex', flex: '1 1 auto', minHeight: 'calc(100vh - 68px)', minWidth: 0, maxWidth: '100%' }}>
        {!isMobile ? (
          <Box sx={{ width: collapsed ? 80 : 264, height: 'calc(100vh - 68px)', flexShrink: 0 }}>{sidebarContent}</Box>
        ) : (
          <Drawer
            variant="temporary"
            open={sidebarOpen}
            onClose={() => setSidebarOpen(false)}
            ModalProps={{ keepMounted: true }}
            slotProps={{ paper: { sx: { width: 272 } } }}
          >
            {sidebarContent}
          </Drawer>
        )}

        <Box sx={{ flex: '1 1 0%', minWidth: 0, maxWidth: '100%' }}>
          <Box component="main" sx={{ width: '100%', minWidth: 0, maxWidth: 1600, mx: 'auto', px: { xs: 2, sm: 2.5, lg: 3 }, pt: { xs: 2, sm: 2.5, lg: 3 }, pb: { xs: 3, lg: 4 } }}>
            <Outlet />
          </Box>
        </Box>
      </Box>
    </Box>
  )
}
