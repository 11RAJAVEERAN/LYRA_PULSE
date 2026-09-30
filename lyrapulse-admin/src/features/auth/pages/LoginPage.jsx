
import {
  Alert,
  Box,
  Button,
  Checkbox,
  CircularProgress,
  FormControlLabel,
  Stack,
  TextField,
  Typography,
} from '@mui/material'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { colors } from '../../../theme/colors'

// ========================================
// 1. LOGIN VALIDATION
// Email + Password removed
// Mobile number added
// ========================================

const loginSchema = z.object({
  mobile: z
    .string()
    .trim()
    .min(1, 'Please enter your mobile number')
    .regex(/^[0-9]{10}$/, 'Please enter a valid 10-digit mobile number'),
})

export function LoginPage() {
  const navigate = useNavigate()
  const { login, isLoading } = useAuth()
  const [rememberMe, setRememberMe] = useState(false)
  const [loginError, setLoginError] = useState('')

  // ========================================
  // 2. FORM DEFAULT VALUES
  // email + password removed
  // mobile added
  // ========================================

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      mobile: '',
    },
  })

  // ========================================
  // 3. LOGIN SUBMIT
  // ========================================

  const onSubmit = async (values) => {
    setLoginError('')

    try {
      await login({
        mobile: values.mobile,
        rememberMe,
      })

      navigate('/dashboard', { replace: true })
    } catch (error) {
      setLoginError(error.message || 'Unable to sign in.')
    }
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#002147',
        px: 2,
      }}
    >
      {/* Login Box */}
      <Box
        sx={{
          width: '100%',
          maxWidth: 440,
          height: 500,
          backgroundColor: '#ffffff',
          borderRadius: 3,
          p: { xs: 3, sm: 4 },
          boxShadow: '0 20px 50px rgba(0, 0, 0, 0.25)',
        }}
      >
        {/* Brand */}
        <Box sx={{ textAlign: 'center', mb: 3 }}>
          <Typography
            sx={{
              color: '#002147',
              fontWeight: 800,
              fontSize: { xs: 24, sm: 28 },
              letterSpacing: '2px',
              lineHeight: 1.2,
            }}
          >
            LYRA PULSE
          </Typography>

          <Typography
            sx={{
              mt: 0.5,
              color: colors.textSecondary,
              fontWeight: 600,
              fontSize: 13,
              letterSpacing: '3px',
              textTransform: 'uppercase',
            }}
          >
            Admin
          </Typography>
        </Box>

        {/* Welcome */}
        <Typography
          component="h2"
          variant="h3"
          sx={{
            textAlign: 'center',
            fontSize: {
              xs: 30,
              md: 36,
            },
            fontWeight: 650,
          }}
        >
          Welcome back
        </Typography>

        <Typography
          color="text.secondary"
          sx={{
            mt: 1,
            textAlign: 'center',
          }}
        >
          Sign in with your mobile number to continue.
        </Typography>

        {/* Login Form */}
        <Box
          component="form"
          onSubmit={handleSubmit(onSubmit)}
          noValidate
          sx={{ mt: 4 }}
        >
          <Stack spacing={2.5}>

            {/* ========================================
                4. MOBILE NUMBER FIELD
                OLD: Work email
                NEW: Mobile number
            ======================================== */}

            <TextField
              label="Mobile Number"
              type="tel"
              fullWidth
              autoComplete="tel"
              inputProps={{
                maxLength: 10,
              }}
              {...register('mobile')}
              error={Boolean(errors.mobile)}
              helperText={errors.mobile?.message}
            />

            {/* ========================================
                5. PASSWORD FIELD REMOVED
            ======================================== */}

            {/* Remember Me */}
            <Box
              sx={{
                display: 'flex',
                justifyContent: 'flex-start',
                alignItems: 'center',
              }}
            >
              <FormControlLabel
                control={
                  <Checkbox
                    checked={rememberMe}
                    onChange={(event) =>
                      setRememberMe(event.target.checked)
                    }
                  />
                }
                label="Remember me"
              />
            </Box>

            {/* Sign In Button */}
            <Button
              type="submit"
              variant="contained"
              size="large"
              disabled={isLoading}
              sx={{
                minHeight: 52,
                backgroundColor: '#002147',
                '&:hover': {
                  backgroundColor: '#003366',
                },
              }}
            >
              {isLoading ? (
                <>
                  <CircularProgress
                    size={18}
                    color="inherit"
                    sx={{ mr: 1 }}
                  />
                  Signing in...
                </>
              ) : (
                'Sign In'
              )}
            </Button>

            {/* Login Error */}
            {loginError ? (
              <Alert severity="error">
                {loginError}
              </Alert>
            ) : null}

          </Stack>
        </Box>

        {/* Footer */}
        <Typography
          sx={{
            mt: 4,
            textAlign: 'center',
            color: colors.textSecondary,
            fontSize: 12,
          }}
        >
          Protected access for Lyra Pulse administrators
        </Typography>
      </Box>
    </Box>
  )
}
