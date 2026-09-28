import { AppBar, Avatar, Badge, Box, IconButton, Toolbar, Tooltip, Typography } from '@mui/material'
import { Bell, LogOut, Search, Settings } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../features/auth/hooks/useAuth'

export function Topbar({ title = 'Overview' }) {
  const navigate = useNavigate()
  const { currentUser, logout } = useAuth()

  const handleLogout = () => {
    logout()
    navigate('/login', { replace: true })
  }

  return (
    <AppBar
      position="sticky"
      color="transparent"
      elevation={0}
      sx={{
        backgroundColor: 'rgba(255,255,255,0.72)',
        backdropFilter: 'blur(12px)',
        borderBottom: '1px solid rgba(148, 163, 184, 0.12)',
        color: '#0f172a',
      }}
    >
      <Toolbar sx={{ minHeight: 76, px: { xs: 2, md: 3 } }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%' }}>
          <Typography variant="h5" sx={{ fontWeight: 700 }}>
            {title}
          </Typography>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <IconButton sx={{ border: '1px solid rgba(148,163,184,0.15)', backgroundColor: '#fff' }}>
              <Search size={16} />
            </IconButton>
            <IconButton sx={{ border: '1px solid rgba(148,163,184,0.15)', backgroundColor: '#fff' }}>
              <Badge color="error" variant="dot">
                <Bell size={16} />
              </Badge>
            </IconButton>
            <IconButton sx={{ border: '1px solid rgba(148,163,184,0.15)', backgroundColor: '#fff' }}>
              <Settings size={16} />
            </IconButton>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, ml: 1 }}>
              <Avatar sx={{ bgcolor: '#1d4ed8', width: 36, height: 36, fontSize: 14 }}>
                {(currentUser?.name ?? 'LyraTech Admin').split(' ').map((part) => part[0]).join('').slice(0, 2)}
              </Avatar>
              <Box>
                <Typography variant="body2" sx={{ fontWeight: 700 }}>{currentUser?.name ?? 'LyraTech Admin'}</Typography>
                <Typography variant="caption" color="text.secondary">{currentUser?.role ?? 'Administrator'}</Typography>
              </Box>
            </Box>
            <Tooltip title="Log out">
              <IconButton aria-label="Log out" onClick={handleLogout} sx={{ border: '1px solid rgba(148,163,184,0.15)', backgroundColor: '#fff' }}>
                <LogOut size={16} />
              </IconButton>
            </Tooltip>
          </Box>
        </Box>
      </Toolbar>
    </AppBar>
  )
}
