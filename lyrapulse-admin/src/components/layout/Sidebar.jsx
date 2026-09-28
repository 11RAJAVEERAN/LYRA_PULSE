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
  LockKeyhole,
  NotebookPen,
  ShieldCheck,
  Users,
} from 'lucide-react'
import { Box, Divider, IconButton, List, ListItemButton, ListItemIcon, ListItemText, Typography } from '@mui/material'
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
]

export function Sidebar({ collapsed, onToggle, onNavigate }) {
  return (
    <Box
      sx={{
        width: collapsed ? 88 : 260,
        transition: 'width 0.2s ease',
        backgroundColor: '#0f172a',
        color: '#e2e8f0',
        borderRight: '1px solid rgba(148, 163, 184, 0.15)',
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', p: 2, minHeight: 72 }}>
        {!collapsed ? (
          <Box>
            <Typography variant="h6" sx={{ color: '#fff', fontWeight: 700 }}>
              Lyra Pulse
            </Typography>
            <Typography variant="caption" sx={{ color: '#94a3b8' }}>
              Admin Console
            </Typography>
          </Box>
        ) : (
          <Box sx={{ width: '100%', display: 'flex', justifyContent: 'center' }}>
            <Typography variant="h6" sx={{ color: '#fff', fontWeight: 800 }}>
              L
            </Typography>
          </Box>
        )}
        <IconButton onClick={onToggle} sx={{ color: '#cbd5e1', border: '1px solid rgba(148,163,184,0.2)' }} size="small">
          {collapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
        </IconButton>
      </Box>

      <Divider sx={{ borderColor: 'rgba(148,163,184,0.15)' }} />

      <List sx={{ px: 1.5, py: 2 }}>
        {navItems.map(({ label, path, icon: Icon }) => (
          <ListItemButton
            key={path}
            component={NavLink}
            to={path}
            onClick={onNavigate}
            sx={{
              borderRadius: 2,
              mb: 0.5,
              color: '#cbd5e1',
              '&.active': {
                backgroundColor: 'rgba(59,130,246,0.18)',
                color: '#fff',
                '& .MuiListItemIcon-root': { color: '#fff' },
              },
              '&:hover': { backgroundColor: 'rgba(148,163,184,0.08)' },
            }}
          >
            <ListItemIcon sx={{ color: 'inherit', minWidth: collapsed ? 28 : 36 }}>
              <Icon size={18} />
            </ListItemIcon>
            {!collapsed ? <ListItemText primary={label} /> : null}
          </ListItemButton>
        ))}
      </List>

      <Box sx={{ mt: 'auto', p: 2 }}>
        <Divider sx={{ borderColor: 'rgba(148,163,184,0.15)', mb: 2 }} />
        <ListItemButton sx={{ borderRadius: 2, color: '#cbd5e1' }}>
          <ListItemIcon sx={{ color: 'inherit', minWidth: collapsed ? 28 : 36 }}>
            <LockKeyhole size={18} />
          </ListItemIcon>
          {!collapsed ? <ListItemText primary="Permissions" /> : null}
        </ListItemButton>
      </Box>
    </Box>
  )
}
