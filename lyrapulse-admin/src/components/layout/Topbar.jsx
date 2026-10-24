import { useEffect, useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  AppBar,
  Avatar,
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
import { ChevronDown, LogOut, Menu as MenuIcon } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../features/auth/hooks/useAuth'
import apiClient, {
  BRANCH_CONTEXT_EVENT,
  SELECTED_BRANCH_KEY,
} from '../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data
const EMPTY_BRANCHES = []

export function Topbar({ onMenu, showMenu = false }) {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { currentUser, logout } = useAuth()
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
          minHeight: { xs: 64, md: 72 },
          px: { xs: 1.5, md: 3 },
          gap: { xs: 1, md: 2 },
        }}
      >
        {showMenu ? (
          <IconButton
            aria-label="Open navigation menu"
            onClick={onMenu}
            edge="start"
            sx={{ color: 'text.primary' }}
          >
            <MenuIcon size={20} />
          </IconButton>
        ) : null}

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
            sx={{
              width: 'fit-content',
              maxWidth: { xs: 160, sm: 300 },
              minWidth: 0,
              height: 36,
              fontSize: 13,
              lineHeight: 1.3,
              color: 'text.primary',
              border: '1px solid',
              borderColor: 'divider',
              borderRadius: 999,
              bgcolor: 'background.paper',
              '&:hover': { bgcolor: 'action.hover' },
              '&.Mui-focused': {
                outline: '2px solid',
                outlineColor: 'info.main',
                outlineOffset: 1,
              },
              '& .MuiSelect-select': {
                height: 36,
                minHeight: '0 !important',
                boxSizing: 'border-box',
                display: 'flex',
                alignItems: 'center',
                py: 0,
                pl: 1.5,
                pr: '32px !important',
              },
              '& .MuiSelect-icon': {
                width: 16,
                height: 16,
                right: 8,
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
                maxWidth: { xs: 160, sm: 300 },
                minWidth: 0,
                minHeight: 36,
                px: 1.5,
                display: 'flex',
                alignItems: 'center',
                border: '1px solid',
                borderColor: 'divider',
                borderRadius: 999,
                bgcolor: 'background.paper',
              }}
            >
              <Typography
                variant="body2"
                color="text.primary"
                sx={{ fontSize: 13, lineHeight: 1.3 }}
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

        <Divider
          orientation="vertical"
          flexItem
          sx={{ mx: { xs: 0, sm: 1 } }}
        />

        <Button
          aria-label="Open account menu"
          aria-haspopup="menu"
          aria-expanded={Boolean(profileAnchor)}
          onClick={(event) => setProfileAnchor(event.currentTarget)}
          endIcon={<ChevronDown size={16} />}
          sx={{
            minWidth: 0,
            minHeight: 36,
            py: 0,
            px: { xs: 0.5, sm: 1 },
            gap: 0.75,
            color: 'text.primary',
            textTransform: 'none',
          }}
        >
          <Avatar
            sx={{
              bgcolor: 'action.selected',
              color: 'text.secondary',
              width: 36,
              height: 36,
              fontSize: 14,
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
            <Typography variant="body2" sx={{ fontWeight: 650 }} noWrap>
              {displayName}
            </Typography>
            <Typography
              variant="caption"
              color="text.secondary"
              sx={{ textTransform: 'capitalize' }}
              noWrap
            >
              {(user?.role ?? 'User').toLowerCase()}
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