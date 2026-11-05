import {
  BadgeCheck,
  Building2,
  CalendarCheck2,
  ChevronRight,
  ClipboardList,
  LayoutDashboard,
  NotebookPen,
  UserCog,
  Users,
} from 'lucide-react'
import { Box, Collapse, List, ListItemButton, ListItemIcon, ListItemText, Tooltip, useMediaQuery } from '@mui/material'
import { useState } from 'react'
import { NavLink, matchPath, useLocation } from 'react-router-dom'

// Departments and Designations live under the Employees group. Attendance Permission keeps its existing route.
const navItems = [
  { label: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
  {
    label: 'Employees',
    icon: Users,
    children: [
      { label: 'Employees', path: '/employees' },
      { label: 'Departments', path: '/departments' },
      { label: 'Designations', path: '/designations' },
    ],
  },
  {
    label: 'Attendance', icon: CalendarCheck2,
    children: [
      { label: 'Attendance', path: '/attendance' },
      { label: 'Shifts', path: '/shifts', permission: 'shifts.view_shift' },
      { label: 'Shift Assignments', path: '/shift-assignments', permission: 'shifts.view_shift' },
      { label: 'Attendance Permission', path: '/permissions' },
    ],
  },
  { label: 'Leaves', path: '/leaves', icon: NotebookPen },
  { label: 'Branches', path: '/branches', icon: Building2 },
  { label: 'Devices', path: '/devices', icon: BadgeCheck },
  { label: 'Reports', path: '/reports', icon: ClipboardList },
  { label: 'Admin Users', path: '/admin-users', icon: UserCog, superadminOnly: true },
]

const isPathActive = (path, pathname) => Boolean(matchPath({ path, end: false }, pathname))

const MOTION_MS = 180

const navButtonSx = (collapsed) => ({
  position: 'relative',
  minHeight: 40,
  borderRadius: 1,
  mb: 0.5,
  // Identical side padding in both states plus a centered icon in the rail keeps every icon on the same
  // x position when the sidebar is toggled (icon centre = 12px padding + 18px half of the 36px icon box).
  px: 1.5,
  justifyContent: collapsed ? 'center' : 'flex-start',
  color: 'text.secondary',
  transition: 'background-color 150ms ease, color 150ms ease',
  '& .MuiListItemIcon-root': { color: 'text.secondary', transition: 'color 150ms ease' },
  '& .MuiListItemText-root': { ml: 0.5 },
  '& .MuiListItemText-primary': { fontSize: '0.875rem', fontWeight: 500, lineHeight: 1.4286, letterSpacing: 0 },
  // Selected item: a subtle translucent highlight plus a thin brand-blue indicator line on the left edge.
  '&.active': {
    bgcolor: 'action.selected',
    color: 'text.primary',
    '& .MuiListItemIcon-root': { color: 'info.main' },
    '& .MuiListItemText-primary': { fontWeight: 600 },
    '&:before': { content: '""', position: 'absolute', left: 0, top: '50%', height: 22, transform: 'translateY(-50%)', width: 3, borderRadius: '0 3px 3px 0', bgcolor: 'info.main' },
  },
  '&.active:hover': { bgcolor: 'action.selected' },
  '&:hover': { bgcolor: 'action.hover', color: 'text.primary', '& .MuiListItemIcon-root': { color: 'text.primary' } },
  '&.active:hover .MuiListItemIcon-root': { color: 'info.main' },
  '&:active:not(.active)': { bgcolor: 'action.selected' },
  '&:focus-visible': { outline: '2px solid', outlineColor: 'info.main', outlineOffset: -2 },
})

// Vertical tree connector for the sub-menu: each row draws its share of the trunk plus a short horizontal branch,
// and the last row stops the trunk at its branch so the tree ends in an elbow.
const treeRowSx = (isLast) => ({
  position: 'relative',
  pl: 2.25,
  py: 0.25,
  '&:before': { content: '""', position: 'absolute', left: 0, top: 0, bottom: isLast ? '50%' : 0, width: 0, borderLeft: '1px solid', borderColor: 'divider' },
  '&:after': { content: '""', position: 'absolute', left: 0, top: '50%', width: 12, height: 0, borderTop: '1px solid', borderColor: 'divider', transition: 'border-color 150ms ease' },
  '&:has(.active):after': { borderColor: 'info.main' },
})

export function Sidebar({ collapsed, onToggle, onNavigate, belowHeader = false }) {
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
    if (path === '/attendance') return user?.role === 'SUPERADMIN' || user?.permissions?.includes('employees.view_employee')
    if (path === '/permissions') return user?.role === 'SUPERADMIN' || user?.role === 'ADMIN'
    if (path === '/shifts' || path === '/shift-assignments') return user?.role === 'SUPERADMIN' || user?.permissions?.includes('shifts.view_shift')
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
  const [isHovered, setIsHovered] = useState(false)
  const visuallyCollapsed = collapsed && !isHovered
  const [syncedKey, setSyncedKey] = useState(activeGroupsKey)

  // When the route moves into a group (e.g. browser back/forward), open it. Adjusted during render, not in an effect.
  if (syncedKey !== activeGroupsKey) {
    setSyncedKey(activeGroupsKey)
    setOpenGroups(openActiveGroups)
  }

  const toggleGroup = (label) => {
    if (visuallyCollapsed) {
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
      onMouseEnter={() => { if (collapsed) setIsHovered(true) }}
      onMouseLeave={() => setIsHovered(false)}
      sx={{
        // Inside the mobile drawer (which is slightly wider than 264px) the expanded sidebar fills it, so no dark strip shows beside the light surface.
        width: visuallyCollapsed ? 80 : { xs: '100%', md: 264 },
        height: belowHeader ? 'calc(100vh - 68px)' : '100vh',
        position: belowHeader ? 'fixed' : 'sticky',
        top: belowHeader ? 68 : 0,
        left: belowHeader ? 0 : undefined,
        zIndex: isHovered && collapsed ? 1200 : 'auto',
        // Only the navigation list scrolls, and the rail stays inside the space below the global header.
        overflow: 'hidden',
        transition: reduceMotion ? 'none' : `width ${MOTION_MS}ms ease`,
        bgcolor: 'background.paper',
        color: 'text.primary',
        fontFamily: (theme) => theme.typography.fontFamily,
        borderRight: 1,
        borderColor: 'divider',
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      <List component="div" sx={{ px: 1.25, py: 2, flex: 1, minHeight: 0, overflowY: 'auto', overflowX: 'hidden' }}>
        {visibleItems.map((item) => {
          const { label, icon: Icon } = item

          if (item.children) {
            const groupId = `nav-group-${label.toLowerCase().replace(/\s+/g, '-')}`
            const expanded = Boolean(openGroups[label]) && !visuallyCollapsed
            const childActive = activeGroups.includes(label)

            const parent = (
              <ListItemButton
                onClick={() => toggleGroup(label)}
                aria-expanded={expanded}
                aria-controls={expanded ? groupId : undefined}
                aria-label={visuallyCollapsed ? label : undefined}
                sx={{
                  ...navButtonSx(visuallyCollapsed),
                  // Parent of the current page: no fill (only the child reads as the selected page), just a stronger label and brand icon.
                  ...(childActive ? { color: 'text.primary', '& .MuiListItemIcon-root': { color: 'info.main' }, '& .MuiListItemText-primary': { fontWeight: 600 } } : null),
                }}
              >
                <ListItemIcon sx={{ color: 'inherit', minWidth: visuallyCollapsed ? 0 : 36, justifyContent: 'center' }}>
                  <Icon size={20} aria-hidden="true" />
                </ListItemIcon>
                {!visuallyCollapsed ? (
                  <>
                    <ListItemText primary={label} primaryTypographyProps={{ variant: 'body2', noWrap: true }} />
                    <ChevronRight size={16} aria-hidden="true" style={{ flexShrink: 0, transform: expanded ? 'rotate(90deg)' : 'none', color: 'inherit', transition: reduceMotion ? 'none' : `transform ${MOTION_MS}ms ease` }} />
                  </>
                ) : null}
              </ListItemButton>
            )

            return (
              <Box key={label}>
                {visuallyCollapsed ? <Tooltip title={label} placement="right">{parent}</Tooltip> : parent}
                {!visuallyCollapsed ? (
                  <Collapse in={expanded} timeout={motionMs} unmountOnExit id={groupId}>
                    <Box sx={{ ml: '29px', mt: 0.25, mb: 1 }}>
                      {item.children.map((child, index) => (
                        <Box key={child.path} sx={treeRowSx(index === item.children.length - 1)}>
                          <ListItemButton
                            component={NavLink}
                            to={child.path}
                            onClick={onNavigate}
                            sx={{
                              ...navButtonSx(false),
                              minHeight: 36,
                              mb: 0,
                              px: 1.5,
                              '& .MuiListItemText-root': { ml: 0 },
                              // Child rows read one step lighter than their parent; the selected child regains weight.
                              '& .MuiListItemText-primary': { fontSize: '0.8125rem', fontWeight: 500 },
                              '&.active .MuiListItemText-primary': { fontWeight: 600 },
                              // The connector branch carries the selection marker for sub-items, so the edge indicator is dropped.
                              '&.active:before': { display: 'none' },
                            }}
                          >
                            <ListItemText primary={child.label} primaryTypographyProps={{ variant: 'body2', noWrap: true }} />
                          </ListItemButton>
                        </Box>
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
              aria-label={visuallyCollapsed ? label : undefined}
              sx={navButtonSx(visuallyCollapsed)}
            >
              <ListItemIcon sx={{ color: 'inherit', minWidth: visuallyCollapsed ? 0 : 36, justifyContent: 'center' }}>
                <Icon size={20} aria-hidden="true" />
              </ListItemIcon>
              {!visuallyCollapsed ? <ListItemText primary={label} primaryTypographyProps={{ variant: 'body2', noWrap: true }} /> : null}
            </ListItemButton>
          )

          return visuallyCollapsed ? <Tooltip key={path} title={label} placement="right">{link}</Tooltip> : link
        })}
      </List>
    </Box>
  )
}
