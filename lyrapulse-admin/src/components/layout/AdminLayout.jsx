import { Box, Drawer, useMediaQuery, useTheme } from '@mui/material'
import { useState } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import { Sidebar } from './Sidebar'
import { Topbar } from './Topbar'

const pageTitles = {
  '/dashboard': 'Dashboard',
  '/employees': 'Employees',
  '/attendance': 'Attendance',
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
      onToggle={!isMobile ? () => setCollapsed((value) => !value) : undefined}
      onNavigate={() => setSidebarOpen(false)}
    />
  )

  return (
    <Box sx={{ display: 'flex', width: '100%', maxWidth: '100%', minHeight: '100vh', overflowX: 'clip', backgroundColor: 'background.default' }}>
      {!isMobile ? (
        <Box sx={{ flexShrink: 0 }}>{sidebarContent}</Box>
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
        <Topbar title={pageTitles[location.pathname] ?? 'LYRA PULSE'} onMenu={() => setSidebarOpen(true)} showMenu={isMobile} />
        <Box component="main" sx={{ width: '100%', minWidth: 0, maxWidth: 1600, mx: 'auto', p: { xs: 2, sm: 2.5, lg: 3 } }}>
          <Outlet />
        </Box>
      </Box>
    </Box>
  )
}