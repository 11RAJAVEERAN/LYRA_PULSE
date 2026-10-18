import {
  BadgeCheck,
  Building2,
  CalendarCheck2,
  ChevronLeft,
  ChevronRight,
  ClipboardList,
  LayoutDashboard,
  NotebookPen,
  UserCog,
  Users,
} from 'lucide-react'
import { Box, Collapse, Divider, IconButton, List, ListItemButton, ListItemIcon, ListItemText, Tooltip, Typography, useMediaQuery } from '@mui/material'
import { useState } from 'react'
import { NavLink, matchPath, useLocation } from 'react-router-dom'

// Departments, Designations and Attendance Permission live under the Employees group.
// Their destinations are unchanged. "Attendance Permission" reuses the existing /permissions route
// (the only permission-related route in the project) instead of introducing a new URL.
const navItems = [
  { label: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
  {
    label: 'Employees',
    icon: Users,
    children: [
      { label: 'Employees', path: '/employees' },
      { label: 'Departments', path: '/departments' },
      { label: 'Designations', path: '/designations' },
      { label: 'Attendance Permission', path: '/permissions' },
    ],
  },
  { label: 'Attendance', path: '/attendance', icon: CalendarCheck2 },
  { label: 'Leaves', path: '/leaves', icon: NotebookPen },
  { label: 'Branches', path: '/branches', icon: Building2 },
  { label: 'Devices', path: '/devices', icon: BadgeCheck },
  { label: 'Reports', path: '/reports', icon: ClipboardList },
  { label: 'Admin users', path: '/admin-users', icon: UserCog, superadminOnly: true },
]

const isPathActive = (path, pathname) => Boolean(matchPath({ path, end: false }, pathname))

const MOTION_MS = 200

const navButtonSx = (collapsed) => ({
  minHeight: 44,
  borderRadius: 1.5,
  mb: 0.5,
  // Identical side padding in both states plus a centered icon in the rail keeps every icon on the same
  // x position when the sidebar is toggled (icon centre = 12px padding + 18px half of the 36px icon box).
  px: 1.5,
  justifyContent: collapsed ? 'center' : 'flex-start',
  color: 'text.primary',
  '& .MuiListItemIcon-root': { color: 'text.secondary' },
  // Selected item: a soft brand-blue tint with a blue label, icon and edge marker.
  '&.active': {
    bgcolor: 'info.light',
    color: 'info.dark',
    '& .MuiListItemIcon-root': { color: 'info.main' },
    '& .MuiListItemText-primary': { fontWeight: 650 },
    '&:before': { content: '""', position: 'absolute', left: 0, top: 8, bottom: 8, width: 3, borderRadius: 3, bgcolor: 'info.main' },
  },
  '&.active:hover': { bgcolor: 'info.light', color: 'info.dark' },
  '&:hover': { bgcolor: 'action.hover', '& .MuiListItemIcon-root': { color: 'text.primary' } },
  '&.active:hover .MuiListItemIcon-root': { color: 'info.main' },
  '&:active:not(.active)': { bgcolor: 'action.selected' },
  '&:focus-visible': { outline: '2px solid', outlineColor: 'info.main', outlineOffset: -2 },
})

export function Sidebar({ collapsed, onToggle, onNavigate }) {
  const { pathname } = useLocation()
  const reduceMotion = useMediaQuery('(prefers-reduced-motion: reduce)')
  const motionMs = reduceMotion ? 0 : MOTION_MS
  let user = null
  try {
    user = JSON.parse(localStorage.getItem('lyrapulse_admin_user') || sessionStorage.getItem('lyrapulse_admin_user') || 'null')
  } catch {
    user = null
  }

  const canSee = ({ superadminOnly, path }) => {
    if (superadminOnly) return user?.role === 'SUPERADMIN'
    if (path === '/employees') return user?.role === 'SUPERADMIN' || user?.permissions?.includes('employees.view_employee')
    return user?.role === 'SUPERADMIN'
  }

  const visibleItems = navItems
    .map((item) => (item.children ? { ...item, children: item.children.filter(canSee) } : item))
    .filter((item) => (item.children ? item.children.length > 0 : canSee(item)))

  // Open groups are tracked by label. A group is always open when one of its children is the current route
  // (direct URL, refresh, or navigating between its children).
  const activeGroups = visibleItems.filter((item) => item.children?.some((child) => isPathActive(child.path, pathname))).map((item) => item.label)
  const activeGroupsKey = activeGroups.join('|')
  const openActiveGroups = (current) => {
    const next = { ...current }
    activeGroups.forEach((label) => { next[label] = true })
    return next
  }
  const [openGroups, setOpenGroups] = useState(() => openActiveGroups({}))
  const [syncedKey, setSyncedKey] = useState(activeGroupsKey)

  // When the route moves into a group (e.g. browser back/forward), open it. Adjusted during render, not in an effect.
  if (syncedKey !== activeGroupsKey) {
    setSyncedKey(activeGroupsKey)
    setOpenGroups(openActiveGroups)
  }

  const toggleGroup = (label) => {
    if (collapsed) {
      // No room for a submenu in the icon-only rail: expand the sidebar and reveal the group instead.
      setOpenGroups((current) => ({ ...current, [label]: true }))
      onToggle?.()
      return
    }
    setOpenGroups((current) => ({ ...current, [label]: !current[label] }))
  }

  return (
    <Box
      component="nav"
      aria-label="Main navigation"
      sx={{
        // Inside the mobile drawer (which is slightly wider than 264px) the expanded sidebar fills it, so no dark strip shows beside the light surface.
        width: collapsed ? 80 : { xs: '100%', md: 264 },
        height: '100vh',
        position: 'sticky',
        top: 0,
        // Only the navigation list scrolls (below), so the brand header stays reachable and no horizontal bar appears while the width animates.
        overflow: 'hidden',
        transition: reduceMotion ? 'none' : `width ${MOTION_MS}ms ease`,
        bgcolor: 'background.paper',
        color: 'text.primary',
        borderRight: 1,
        borderColor: 'divider',
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      <Box sx={{ display: 'flex', flexDirection: collapsed ? 'column' : 'row', alignItems: 'center', justifyContent: collapsed ? 'center' : 'space-between', gap: collapsed ? 0.5 : 1, px: 2, py: collapsed ? 1 : 0, minHeight: 72 }}>
        {!collapsed ? (
          <Box sx={{ minWidth: 0 }}>
            <Typography variant="subtitle1" sx={{ color: 'primary.main', fontWeight: 750, letterSpacing: '0.01em' }}>
              LYRA PULSE
            </Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>Admin Console</Typography>
          </Box>
        ) : (
          <Typography variant="h6" aria-label="LYRA PULSE" sx={{ textAlign: 'center', color: 'primary.main', fontWeight: 750, lineHeight: 1.2 }}>
            L
          </Typography>
        )}
        {onToggle ? (
          <Tooltip title={collapsed ? 'Expand navigation' : 'Collapse navigation'}>
            <IconButton aria-label={collapsed ? 'Expand navigation' : 'Collapse navigation'} onClick={onToggle} size="small" sx={{ flexShrink: 0, color: 'text.secondary', border: '1px solid', borderColor: 'divider', '&:hover': { bgcolor: 'action.hover', color: 'text.primary' }, '&:focus-visible': { outline: '2px solid', outlineColor: 'info.main', outlineOffset: 1 } }}>
              {collapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
            </IconButton>
          </Tooltip>
        ) : null}
      </Box>

      <Divider />

      <List component="div" sx={{ px: 1.25, py: 2, flex: 1, minHeight: 0, overflowY: 'auto', overflowX: 'hidden' }}>
        {visibleItems.map((item) => {
          const { label, icon: Icon } = item

          if (item.children) {
            const groupId = `nav-group-${label.toLowerCase().replace(/\s+/g, '-')}`
            const expanded = Boolean(openGroups[label]) && !collapsed
            const childActive = activeGroups.includes(label)

            const parent = (
              <ListItemButton
                onClick={() => toggleGroup(label)}
                aria-expanded={expanded}
                aria-controls={expanded ? groupId : undefined}
                aria-label={collapsed ? label : undefined}
                sx={{
                  ...navButtonSx(collapsed),
                  // Parent of the current page: a soft tint, so only the child reads as the selected page.
                  ...(childActive ? { bgcolor: 'action.selected', color: 'info.dark', '& .MuiListItemIcon-root': { color: 'info.main' } } : null),
                }}
              >
                <ListItemIcon sx={{ color: 'inherit', minWidth: collapsed ? 0 : 36, justifyContent: 'center' }}>
                  <Icon size={18} aria-hidden="true" />
                </ListItemIcon>
                {!collapsed ? (
                  <>
                    <ListItemText primary={label} primaryTypographyProps={{ variant: 'body2', fontWeight: 550, noWrap: true }} />
                    <ChevronRight size={16} aria-hidden="true" style={{ flexShrink: 0, transform: expanded ? 'rotate(90deg)' : 'none', transition: reduceMotion ? 'none' : `transform ${MOTION_MS}ms ease` }} />
                  </>
                ) : null}
              </ListItemButton>
            )

            return (
              <Box key={label}>
                {collapsed ? <Tooltip title={label} placement="right">{parent}</Tooltip> : parent}
                {!collapsed ? (
                  <Collapse in={expanded} timeout={motionMs} unmountOnExit id={groupId}>
                    <Box sx={{ ml: 3, pl: 1, mb: 0.5, borderLeft: '1px solid', borderColor: 'divider' }}>
                      {item.children.map((child) => (
                        <ListItemButton
                          key={child.path}
                          component={NavLink}
                          to={child.path}
                          onClick={onNavigate}
                          sx={{
                            ...navButtonSx(false),
                            minHeight: 38,
                            mb: 0.25,
                            pl: 1.75,
                            // Child rows read one step lighter than their parent; the selected child regains weight.
                            '& .MuiListItemText-primary': { fontSize: '0.8125rem' },
                            '&.active .MuiListItemText-primary': { fontWeight: 650 },
                          }}
                        >
                          <ListItemText primary={child.label} primaryTypographyProps={{ variant: 'body2', fontWeight: 550, noWrap: true }} />
                        </ListItemButton>
                      ))}
                    </Box>
                  </Collapse>
                ) : null}
              </Box>
            )
          }

          const { path } = item
          const link = (
            <ListItemButton
              key={path}
              component={NavLink}
              to={path}
              onClick={onNavigate}
              aria-label={collapsed ? label : undefined}
              sx={navButtonSx(collapsed)}
            >
              <ListItemIcon sx={{ color: 'inherit', minWidth: collapsed ? 0 : 36, justifyContent: 'center' }}>
                <Icon size={18} aria-hidden="true" />
              </ListItemIcon>
              {!collapsed ? <ListItemText primary={label} primaryTypographyProps={{ variant: 'body2', fontWeight: 550, noWrap: true }} /> : null}
            </ListItemButton>
          )

          return collapsed ? <Tooltip key={path} title={label} placement="right">{link}</Tooltip> : link
        })}
      </List>
    </Box>
  )
}