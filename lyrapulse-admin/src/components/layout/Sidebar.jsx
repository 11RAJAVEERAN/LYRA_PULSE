import {
  BadgeCheck,
  BriefcaseBusiness,
  Building2,
  CalendarCheck2,
  ChevronLeft,
  ChevronRight,
  ClipboardList,
  FolderKanban,
  LayoutDashboard,
  NotebookPen,
  ShieldCheck,
  UserCog,
  Users,
} from 'lucide-react'
import { Box, Divider, IconButton, List, ListItemButton, ListItemIcon, ListItemText, Tooltip, Typography } from '@mui/material'
import { NavLink } from 'react-router-dom'

const navItems = [
  { label: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
  { label: 'Employees', path: '/employees', icon: Users },
  { label: 'Attendance', path: '/attendance', icon: CalendarCheck2 },
  { label: 'Leaves', path: '/leaves', icon: NotebookPen },
  { label: 'Permissions', path: '/permissions', icon: ShieldCheck },
  { label: 'Branches', path: '/branches', icon: Building2 },
  { label: 'Departments', path: '/departments', icon: FolderKanban },
  { label: 'Designations', path: '/designations', icon: BriefcaseBusiness },
  { label: 'Devices', path: '/devices', icon: BadgeCheck },
  { label: 'Reports', path: '/reports', icon: ClipboardList },
  { label: 'Admin users', path: '/admin-users', icon: UserCog, superadminOnly: true },
]

export function Sidebar({ collapsed, onToggle, onNavigate }) {
  let user = null
  try {
    user = JSON.parse(localStorage.getItem('lyrapulse_admin_user') || sessionStorage.getItem('lyrapulse_admin_user') || 'null')
  } catch {
    user = null
  }

  const visibleItems = navItems.filter(({ superadminOnly, path }) => {
    if (superadminOnly) return user?.role === 'SUPERADMIN'
    if (path === '/employees') return user?.role === 'SUPERADMIN' || user?.permissions?.includes('employees.view_employee')
    return user?.role === 'SUPERADMIN'
  })

  return (
    <Box
      component="nav"
      aria-label="Main navigation"
      sx={{
        width: collapsed ? 80 : 264,
        height: '100vh',
        position: 'sticky',
        top: 0,
        overflowY: 'auto',
        transition: 'width 160ms ease',
        bgcolor: 'lyra.sidebarBackground',
        color: 'lyra.sidebarText',
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', px: 2, minHeight: 72 }}>
        {!collapsed ? (
          <Box>
            <Typography variant="subtitle1" sx={{ color: 'common.white', fontWeight: 750, letterSpacing: '0.01em' }}>
              LYRA PULSE
            </Typography>
            <Typography variant="caption" sx={{ color: 'lyra.sidebarMuted' }}>Admin Console</Typography>
          </Box>
        ) : (
          <Typography variant="h6" aria-label="LYRA PULSE" sx={{ width: '100%', textAlign: 'center', color: 'common.white' }}>
            L
          </Typography>
        )}
        {onToggle ? (
          <Tooltip title={collapsed ? 'Expand navigation' : 'Collapse navigation'}>
            <IconButton aria-label={collapsed ? 'Expand navigation' : 'Collapse navigation'} onClick={onToggle} size="small" sx={{ color: 'lyra.sidebarText', border: '1px solid', borderColor: 'lyra.sidebarDivider' }}>
              {collapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
            </IconButton>
          </Tooltip>
        ) : null}
      </Box>

      <Divider sx={{ borderColor: 'lyra.sidebarDivider' }} />

      <List component="div" sx={{ px: 1.25, py: 2, flex: 1 }}>
        {visibleItems.map(({ label, path, icon: Icon }) => {
          const link = (
            <ListItemButton
              key={path}
              component={NavLink}
              to={path}
              onClick={onNavigate}
              aria-label={collapsed ? label : undefined}
              sx={{
                minHeight: 44,
                borderRadius: 1.5,
                mb: 0.5,
                px: collapsed ? 1.5 : 1.75,
                color: 'lyra.sidebarText',
                '&.active': {
                  bgcolor: 'lyra.sidebarActive',
                  color: 'common.white',
                  '& .MuiListItemIcon-root': { color: 'common.white' },
                  '&:before': { content: '""', position: 'absolute', left: 0, top: 8, bottom: 8, width: 3, borderRadius: 3, bgcolor: 'info.light' },
                },
                '&:hover': { bgcolor: 'lyra.sidebarHover', color: 'common.white' },
                '&:focus-visible': { outline: '2px solid', outlineColor: 'info.light', outlineOffset: -2 },
              }}
            >
              <ListItemIcon sx={{ color: 'inherit', minWidth: collapsed ? 0 : 36, justifyContent: 'center' }}>
                <Icon size={18} aria-hidden="true" />
              </ListItemIcon>
              {!collapsed ? <ListItemText primary={label} primaryTypographyProps={{ variant: 'body2', fontWeight: 550 }} /> : null}
            </ListItemButton>
          )

          return collapsed ? <Tooltip key={path} title={label} placement="right">{link}</Tooltip> : link
        })}
      </List>
    </Box>
  )
}