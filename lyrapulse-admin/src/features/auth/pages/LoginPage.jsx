import { Alert, Box, Button, Checkbox, CircularProgress, FormControlLabel, Link, Stack, TextField, Typography } from '@mui/material'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { colors } from '../../../theme/colors'

const loginSchema = z.object({
  email: z.string().trim().min(1, 'Please enter your email address').email('Please enter a valid email address'),
  password: z.string().min(1, 'Please enter your password'),
})

export function LoginPage() {
  const navigate = useNavigate()
  const { login, isLoading } = useAuth()
  const [rememberMe, setRememberMe] = useState(false)
  const [loginError, setLoginError] = useState('')

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: '',
    },
  })

  const onSubmit = async (values) => {
    setLoginError('')
    try {
      await login({ ...values, rememberMe })
      navigate('/dashboard', { replace: true })
    } catch (error) {
      setLoginError(error.message || 'Unable to sign in.')
    }
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'grid',
        gridTemplateColumns: { xs: '1fr', md: 'minmax(0, 1.08fr) minmax(420px, 0.92fr)' },
        backgroundColor: colors.surface,
      }}
    >
      <Box
        sx={{
          minHeight: { xs: 310, md: '100vh' },
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          position: 'relative',
          overflow: 'hidden',
          px: { xs: 3, sm: 5, lg: 8 },
          py: { xs: 4, md: 6 },
          color: colors.surface,
          backgroundColor: colors.primaryDark,
          backgroundImage: 'linear-gradient(135deg, rgba(37, 99, 235, 0.28), transparent 52%), repeating-linear-gradient(135deg, rgba(255,255,255,0.025) 0px, rgba(255,255,255,0.025) 1px, transparent 1px, transparent 18px)',
        }}
      >
        <Box sx={{ position: 'relative', zIndex: 1 }}>
          <Typography sx={{ fontSize: 19, fontWeight: 750, letterSpacing: 0, color: colors.surface }}>
            Lyra Pulse
          </Typography>
          <Typography sx={{ mt: 0.5, color: 'rgba(255,255,255,0.62)', fontSize: 13 }}>
            PEOPLE OPERATIONS
          </Typography>
        </Box>

        <Box sx={{ position: 'relative', zIndex: 1, maxWidth: 650, py: { xs: 4, md: 7 } }}>
          <Typography
            component="h1"
            sx={{
              maxWidth: 600,
              fontSize: { xs: 34, sm: 44, lg: 56 },
              lineHeight: 1.12,
              fontWeight: 650,
              color: colors.surface,
            }}
          >
            People, presence, and progress in one place.
          </Typography>
          <Typography sx={{ mt: 2.5, maxWidth: 490, color: 'rgba(255,255,255,0.72)', fontSize: 16, lineHeight: 1.7 }}>
            A clearer view of your workforce, from daily attendance to the people shaping your business.
          </Typography>

          <Box
            sx={{
              mt: { xs: 4, md: 6 },
              maxWidth: 510,
              display: 'grid',
              gridTemplateColumns: 'repeat(3, minmax(0, 1fr))',
              borderTop: '1px solid rgba(255,255,255,0.18)',
              pt: 2.5,
              gap: 2,
            }}
          >
            {[
              ['1,284', 'Team members'],
              ['98.4%', 'Attendance'],
              ['12', 'Locations'],
            ].map(([value, label]) => (
              <Box key={label}>
                <Typography sx={{ fontSize: 22, fontWeight: 700, color: colors.surface }}>{value}</Typography>
                <Typography sx={{ mt: 0.5, color: 'rgba(255,255,255,0.6)', fontSize: 12 }}>{label}</Typography>
              </Box>
            ))}
          </Box>
        </Box>

        <Typography sx={{ position: 'relative', zIndex: 1, color: 'rgba(255,255,255,0.52)', fontSize: 12 }}>
          © 2026 Lyra Pulse · Secure workforce management
        </Typography>
      </Box>

      <Box
        sx={{
          minHeight: { xs: 500, md: '100vh' },
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          px: { xs: 3, sm: 6, lg: 9 },
          py: { xs: 6, md: 8 },
        }}
      >
        <Box sx={{ width: '100%', maxWidth: 440 }}>
          <Typography sx={{ color: colors.primaryBlue, fontWeight: 700, fontSize: 13 }}>
            LYRA PULSE ADMIN
          </Typography>
          <Typography component="h2" variant="h3" sx={{ mt: 1.5, fontSize: { xs: 30, md: 36 }, fontWeight: 650 }}>
            Welcome back
          </Typography>
          <Typography color="text.secondary" sx={{ mt: 1 }}>
            Sign in to continue to your workspace.
          </Typography>

          <Box component="form" onSubmit={handleSubmit(onSubmit)} noValidate sx={{ mt: 4 }}>
            <Stack spacing={2.5}>
              <TextField
                label="Work email"
                type="email"
                fullWidth
                autoComplete="username"
                {...register('email')}
                error={Boolean(errors.email)}
                helperText={errors.email?.message}
              />
              <TextField
                label="Password"
                type="password"
                fullWidth
                autoComplete="current-password"
                {...register('password')}
                error={Boolean(errors.password)}
                helperText={errors.password?.message}
              />

              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
                <FormControlLabel
                  control={<Checkbox checked={rememberMe} onChange={(event) => setRememberMe(event.target.checked)} />}
                  label="Remember me"
                />
                <Link href="#" underline="hover" color="primary.main" sx={{ fontSize: 14, fontWeight: 600 }}>
                  Forgot password?
                </Link>
              </Box>

              <Button type="submit" variant="contained" size="large" disabled={isLoading} sx={{ minHeight: 52 }}>
                {isLoading ? <><CircularProgress size={18} color="inherit" sx={{ mr: 1 }} />Signing in...</> : 'Sign In'}
              </Button>
              {loginError ? <Alert severity="error">{loginError}</Alert> : null}
            </Stack>
          </Box>

          <Typography sx={{ mt: 4, textAlign: 'center', color: colors.textSecondary, fontSize: 12 }}>
            Protected access for Lyra Pulse administrators
          </Typography>
        </Box>
      </Box>
    </Box>
  )
}
