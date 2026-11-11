import { Alert, Box, Button, Stack, Typography } from '@mui/material'
import { Link } from 'react-router-dom'
import { authService } from '../../services/authService'

export function PermissionRoute({ permission, roles = [], children }) {
  const user = authService.getCurrentUser()
  const allowed = roles.includes(user?.role)
    || (permission && (
      user?.role === 'SUPERADMIN'
      || user?.permissions?.includes('*')
      || user?.permissions?.includes(permission)
    ))

  if (allowed) return children

  return (
    <Box sx={{ maxWidth: 720, mx: 'auto', p: { xs: 2, md: 4 } }}>
      <Stack spacing={2}>
        <Alert severity="error">
          <Typography component="span" fontWeight={600}>Access denied.</Typography>
          {' You do not have permission to open this page.'}
        </Alert>
        <Button component={Link} to="/dashboard" variant="outlined" sx={{ alignSelf: 'flex-start' }}>
          Return to dashboard
        </Button>
      </Stack>
    </Box>
  )
}
