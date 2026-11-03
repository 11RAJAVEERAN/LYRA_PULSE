import { useEffect, useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  AppBar,
  Avatar,
  Badge,
  Box,
  Button,
  CircularProgress,
  Divider,
  IconButton,
  Menu,
  MenuItem,
  Select,
  Toolbar,
  Tooltip,
  Typography,
} from '@mui/material'
import { Bell, ChevronDown, LogOut, Menu as MenuIcon, Moon, Sun } from 'lucide-react'
import lyraPulseLogo from '../../assets/lyra-pulse-horizontal.png'
import { useNavigate } from 'react-router-dom'
import { useThemeMode } from '../../app/providers/ThemeProvider'
import { useAuth } from '../../features/auth/hooks/useAuth'
import apiClient, {
  BRANCH_CONTEXT_EVENT,
  SELECTED_BRANCH_KEY,
} from '../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data
const EMPTY_BRANCHES = []

// There is no notifications API yet, so this only drives the unread dot on the bell. Wire it to real data when one exists.
const HAS_UNREAD_NOTIFICATIONS = true

// Shared look for the hotel/branch switcher: soft surface, 8px radius, hairline only on hover.
const switcherSx = {
  borderRadius: 1,
  border: '1px solid transparent',
  bgcolor: 'action.hover',
  transition: 'background-color 150ms ease, border-color 150ms ease, box-shadow 150ms ease',
}

// 36x36 hit area around an 18-20px icon; only the hover state shows a background.
const utilityButtonSx = {
  width: 36,
  height: 36,
  borderRadius: 1,
  color: 'text.secondary',
  transition: 'background-color 150ms ease, color 150ms ease',
  '&:hover': { bgcolor: 'action.hover', color: 'text.primary' },
}

// Presentation-only role label ("SUPERADMIN" -> "Super Admin"); the stored role value is never changed.
const formatRole = (role) => {
  const value = String(role ?? 'User').toLowerCase()
  if (value === 'superadmin') return 'Super Admin'
  return value.replace(/[_-]+/g, ' ').replace(/\b\w/g, (letter) => letter.toUpperCase())
}

export function Topbar({ onMenu, showMenu = false, collapsed = false, onToggle }) {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { currentUser, logout } = useAuth()
  const { mode, toggleMode } = useThemeMode()
  const [profileAnchor, setProfileAnchor] = useState(null)
  const [selectedBranch, setSelectedBranch] = useState(
    () => window.localStorage.getItem(SELECTED_BRANCH_KEY) ?? '',
  )

  const userQuery = useQuery({
    queryKey: ['topbar-user', currentUser?.id],
    queryFn: async () => unwrap(await apiClient.get('/auth/me/'))?.user,
    enabled: Boolean(currentUser?.id),
    staleTime: 60_000,
    retry: 1,
  })

  const branchesQuery = useQuery({
    queryKey: ['topbar-branches', currentUser?.id],
    queryFn: async () => {
      const data = unwrap(await apiClient.get('/branches/'))
      return Array.isArray(data) ? data : []
    },
    enabled: Boolean(currentUser?.id),
    staleTime: 60_000,
    retry: 1,
  })

  const branches = branchesQuery.data ?? EMPTY_BRANCHES

  useEffect(() => {
    if (!branchesQuery.isSuccess) return

    const authorizedIds = new Set(branches.map((branch) => String(branch.id)))
    const saved = window.localStorage.getItem(SELECTED_BRANCH_KEY)
    const next =
      saved && authorizedIds.has(saved)
        ? saved
        : branches[0]
          ? String(branches[0].id)
          : ''

    if (next === saved) return

    if (next) {
      window.localStorage.setItem(SELECTED_BRANCH_KEY, next)
    } else {
      window.localStorage.removeItem(SELECTED_BRANCH_KEY)
    }

    window.dispatchEvent(
      new CustomEvent(BRANCH_CONTEXT_EVENT, { detail: { branchId: next } }),
    )

    queryClient.invalidateQueries({
      predicate: (query) =>
        !['topbar-user', 'topbar-branches'].includes(query.queryKey[0]),
    })
  }, [branchesQuery.isSuccess, branches, queryClient])

  const handleLogout = async () => {
    await logout()
    navigate('/login', { replace: true })
  }

  const user = userQuery.data ?? currentUser
  const displayName =
    user?.name ||
    [user?.first_name, user?.last_name].filter(Boolean).join(' ') ||
    user?.phone_number ||
    'Account'
  const initials = displayName
    .split(' ')
    .filter(Boolean)
    .map((part) => part[0])
    .join('')
    .slice(0, 2)
  const organizationName = user?.organization?.name ?? 'Organization unavailable'
  const selected =
    branches.find((branch) => String(branch.id) === selectedBranch) ?? branches[0]
  const branchLabel = selected
    ? user?.organization?.name
      ? `${organizationName} · ${selected.name}`
      : selected.name
    : organizationName

  const changeBranch = async (event) => {
    const id = String(event.target.value)
    if (!branches.some((branch) => String(branch.id) === id)) return

    setSelectedBranch(id)
    window.localStorage.setItem(SELECTED_BRANCH_KEY, id)
    window.dispatchEvent(
      new CustomEvent(BRANCH_CONTEXT_EVENT, { detail: { branchId: id } }),
    )

    await queryClient.invalidateQueries({
      predicate: (query) =>
        !['topbar-user', 'topbar-branches'].includes(query.queryKey[0]),
    })
  }

  return (
    <AppBar
      position="sticky"
      color="transparent"
      elevation={0}
      sx={{
        bgcolor: 'background.paper',
        color: 'text.primary',
        borderBottom: 1,
        borderColor: 'divider',
      }}
    >
      <Toolbar
        aria-label="Admin top navigation"
        sx={{
          minHeight: { xs: 64, md: 68 },
          pl: { xs: 1, md: 0 },
          pr: { xs: 1, md: 3 },
          gap: { xs: 0.5, md: 2 },
        }}
      >
<Box sx={{ display: 'flex', alignItems: 'center', gap: { xs: 0.5, md: 1 }, width: { xs: 'auto', md: 264 }, flexShrink: 0, boxSizing: 'border-box', px: { xs: 0, md: 1 }, borderRight: { xs: 0, md: '1px solid rgba(0, 0, 0, 0.06)' } }}>          {showMenu ? (
            <IconButton
              aria-label="Open navigation menu"
              onClick={onMenu}
              edge="start"
              sx={{ color: 'text.primary', mr: { xs: 0, sm: 0.5 } }}
            >
              <MenuIcon size={20} />
            </IconButton>
          ) : null}

          {onToggle ? (
            <Tooltip title={collapsed ? 'Expand navigation' : 'Collapse navigation'}>
              <IconButton
                aria-label={collapsed ? 'Expand navigation' : 'Collapse navigation'}
                onClick={onToggle}
                edge="start"
                sx={{ color: 'text.secondary', flexShrink: 0, width: 36, height: 36, '&:hover': { bgcolor: 'action.hover', color: 'text.primary' } }}
              >
                <MenuIcon size={20} />
              </IconButton>
            </Tooltip>
          ) : null}

          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              flexShrink: 0,
              // The logo artwork has a white background, so in dark mode it sits on a soft light tile.
              ...(mode === 'dark' ? { bgcolor: 'common.white', borderRadius: 1, px: 1, py: 0.5 } : null),
            }}
          >
            <Box
              component="img"
              src={lyraPulseLogo}
              alt="LYRA PULSE"
              sx={{
                display: 'block',
                width: { xs: 119, sm: 139, md: 159 },
                height: { xs: 24, sm: 28, md: 32 },
                objectFit: 'contain',
                flexShrink: 0,
              }}
            />
          </Box>
        </Box>
        {branchesQuery.isLoading ? (
          <Box
            role="status"
            aria-label="Loading authorized branches"
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 1,
              minWidth: 0,
              color: 'text.secondary',
            }}
          >
            <CircularProgress size={16} />
            <Typography
              variant="body2"
              noWrap
              sx={{ display: { xs: 'none', sm: 'block' } }}
            >
              Loading branches…
            </Typography>
          </Box>
        ) : branchesQuery.isError ? (
          <Tooltip title="Could not load authorized branches. Retry">
            <Button
              onClick={() => branchesQuery.refetch()}
              sx={{
                minWidth: 0,
                maxWidth: 220,
                color: 'text.secondary',
                textTransform: 'none',
              }}
            >
              <Typography variant="body2" noWrap>
                Branches unavailable · Retry
              </Typography>
            </Button>
          </Tooltip>
        ) : branches.length > 1 ? (
          <Select
            value={selected ? String(selected.id) : ''}
            onChange={changeBranch}
            variant="standard"
            disableUnderline
            inputProps={{ 'aria-label': 'Select authorized branch' }}
            IconComponent={ChevronDown}
            MenuProps={{ anchorOrigin: { vertical: 'bottom', horizontal: 'left' }, transformOrigin: { vertical: 'top', horizontal: 'left' } }}
            sx={{
              ...switcherSx,
              width: 'fit-content',
              maxWidth: { xs: 110, sm: 300 },
              minWidth: 0,
              height: 40,
              fontSize: 13,
              fontWeight: 500,
              lineHeight: '40px',
              color: 'text.primary',
              '&:hover': { borderColor: 'divider' },
              '&.Mui-focused': {
                borderColor: 'info.main',
                bgcolor: 'background.paper',
                boxShadow: (theme) => `0 0 0 3px ${theme.palette.action.focus}`,
              },
              '& .MuiSelect-select': {
                height: 40,
                minHeight: '0 !important',
                boxSizing: 'border-box',
                display: 'block',
                overflow: 'hidden',
                whiteSpace: 'nowrap',
                textOverflow: 'ellipsis',
                py: 0,
                pl: 1.5,
                pr: '32px !important',
              },
              '& .MuiSelect-icon': {
                width: 16,
                height: 16,
                right: 10,
                color: 'text.secondary',
              },
            }}
          >
            {branches.map((branch) => (
              <MenuItem key={branch.id} value={String(branch.id)}>
                {user?.organization?.name
                  ? `${organizationName} · ${branch.name}`
                  : branch.name}
              </MenuItem>
            ))}
          </Select>
        ) : (
          <Tooltip title={branches.length ? branchLabel : 'No branch assigned'}>
            <Box
              sx={{
                ...switcherSx,
                maxWidth: { xs: 110, sm: 300 },
                minWidth: 0,
                minHeight: 40,
                px: 1.5,
                display: 'flex',
                alignItems: 'center',
              }}
            >
              <Typography
                variant="body2"
                color="text.primary"
                sx={{ fontSize: 13, fontWeight: 500, lineHeight: 1.3 }}
                noWrap
              >
                {branches.length
                  ? branchLabel
                  : `${organizationName} · No branch assigned`}
              </Typography>
            </Box>
          </Tooltip>
        )}

        <Box sx={{ flex: 1 }} />

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, flexShrink: 0 }}>
          <Tooltip title="Notifications">
            <IconButton aria-label="Notifications" sx={utilityButtonSx}>
              <Badge
                variant="dot"
                color="error"
                invisible={!HAS_UNREAD_NOTIFICATIONS}
                overlap="circular"
                sx={{ '& .MuiBadge-badge': { top: 3, right: 3, width: 7, height: 7, minWidth: 7, padding: 0, boxShadow: (theme) => `0 0 0 2px ${theme.palette.background.paper}` } }}
              >
                <Bell size={20} aria-hidden="true" />
              </Badge>
            </IconButton>
          </Tooltip>

          <Tooltip title={mode === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}>
            <IconButton
              aria-label={mode === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
              onClick={toggleMode}
              sx={utilityButtonSx}
            >
              {mode === 'dark' ? <Sun size={20} aria-hidden="true" /> : <Moon size={20} aria-hidden="true" />}
            </IconButton>
          </Tooltip>
        </Box>

        <Divider
          orientation="vertical"
          flexItem
          sx={{ mx: { xs: 0.25, sm: 1 }, my: 2.5 }}
        />

        <Button
          aria-label="Open account menu"
          aria-haspopup="menu"
          aria-expanded={Boolean(profileAnchor)}
          onClick={(event) => setProfileAnchor(event.currentTarget)}
          endIcon={<ChevronDown size={16} aria-hidden="true" />}
          sx={{
            minWidth: 0,
            minHeight: 40,
            py: 0,
            px: { xs: 0.5, sm: 1 },
            gap: 1.25,
            borderRadius: 1,
            color: 'text.primary',
            textTransform: 'none',
            transition: 'background-color 150ms ease',
            '&:hover': { bgcolor: 'action.hover' },
            '& .MuiButton-endIcon': { ml: 0, color: 'text.secondary' },
          }}
        >
          <Avatar
            sx={{
              bgcolor: 'action.selected',
              color: 'text.secondary',
              width: 36,
              height: 36,
              fontSize: 14,
              fontWeight: 600,
            }}
          >
            {initials}
          </Avatar>
          <Box
            sx={{
              display: { xs: 'none', sm: 'block' },
              maxWidth: 180,
              textAlign: 'left',
            }}
          >
            <Typography variant="body2" sx={{ fontWeight: 600, lineHeight: 1.4286 }} noWrap>
              {displayName}
            </Typography>
            <Typography
              variant="caption"
              color="text.secondary"
              sx={{ display: 'block', lineHeight: 1.5 }}
              noWrap
            >
              {formatRole(user?.role)}
            </Typography>
          </Box>
        </Button>

        <Menu
          anchorEl={profileAnchor}
          open={Boolean(profileAnchor)}
          onClose={() => setProfileAnchor(null)}
        >
          <MenuItem
            onClick={async () => {
              setProfileAnchor(null)
              await handleLogout()
            }}
          >
            <LogOut size={17} style={{ marginRight: 10 }} />
            Log out
          </MenuItem>
        </Menu>
      </Toolbar>
    </AppBar>
  )
}