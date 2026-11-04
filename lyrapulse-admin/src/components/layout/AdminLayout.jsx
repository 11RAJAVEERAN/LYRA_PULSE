import { Box, Drawer, useMediaQuery, useTheme } from '@mui/material'
import { useState } from 'react'
import { Outlet } from 'react-router-dom'
import { Sidebar } from './Sidebar'
import { Topbar } from './Topbar'

export function AdminLayout() {
  const theme = useTheme()
  const isMobile = useMediaQuery(theme.breakpoints.down('md'))
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const [collapsed, setCollapsed] = useState(false)

  const sidebarContent = (
    <Sidebar
      collapsed={isMobile ? false : collapsed}
      onToggle={() => setCollapsed((value) => !value)}
      onNavigate={() => setSidebarOpen(false)}
    />
  )

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh', backgroundColor: '#f3f7fb' }}>
      {!isMobile ? (
        <Box>{sidebarContent}</Box>
      ) : (
        <Drawer
          variant="temporary"
          open={sidebarOpen}
          onClose={() => setSidebarOpen(false)}
          ModalProps={{ keepMounted: true }}
          slotProps={{ paper: { sx: { width: 260, backgroundColor: '#0f172a' } } }}
        >
          {sidebarContent}
        </Drawer>
      )}

      <Box sx={{ flex: 1, minWidth: 0 }}>
        <Topbar title="Overview" />
        <Box component="main" sx={{ p: { xs: 2, md: 3 } }}>
          <Outlet />
        </Box>
      </Box>
    </Box>
  )
}
