import { AppBar, Avatar, Box, IconButton, Toolbar, Tooltip, Typography } from '@mui/material'
import { LogOut, Menu } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../features/auth/hooks/useAuth'

export function Topbar({ title = 'Dashboard', onMenu, showMenu = false }) {
  const navigate = useNavigate()
  const { currentUser, logout } = useAuth()

  const handleLogout = async () => {
    await logout()
    navigate('/login', { replace: true })
  }

  const displayName = currentUser?.name ?? 'LyraTech Admin'
  const initials = displayName.split(' ').filter(Boolean).map((part) => part[0]).join('').slice(0, 2)

  return (
    <AppBar position="sticky" color="transparent" elevation={0}>
      <Toolbar sx={{ minHeight: { xs: 64, md: 72 }, px: { xs: 2, md: 3 }, gap: 1.5 }}>
        {showMenu ? (
          <IconButton aria-label="Open navigation menu" onClick={onMenu} edge="start" sx={{ color: 'text.primary' }}>
            <Menu size={20} />
          </IconButton>
        ) : null}
        <Typography variant="subtitle1" component="p" sx={{ flex: 1, minWidth: 0 }} noWrap>
          {title}
        </Typography>

        <Box sx={{ display: 'flex', alignItems: 'center', gap: { xs: 1, sm: 1.5 } }}>
          <Avatar sx={{ bgcolor: 'primary.main', color: 'primary.contrastText', width: 36, height: 36 }}>
            {initials}
          </Avatar>
          <Box sx={{ display: { xs: 'none', sm: 'block' }, maxWidth: 200 }}>
            <Typography variant="body2" sx={{ fontWeight: 650 }} noWrap>{displayName}</Typography>
            <Typography variant="caption" color="text.secondary" sx={{ textTransform: 'capitalize' }}>
              {(currentUser?.role ?? 'Administrator').toLowerCase()}
            </Typography>
          </Box>
          <Tooltip title="Log out">
            <IconButton aria-label="Log out" onClick={handleLogout} sx={{ color: 'text.secondary' }}>
              <LogOut size={18} />
            </IconButton>
          </Tooltip>
        </Box>
      </Toolbar>
    </AppBar>
  )
}