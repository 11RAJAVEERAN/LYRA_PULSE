
import {
  Alert,
  Box,
  Button,
  Checkbox,
  CircularProgress,
  FormControlLabel,
  Link,
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

const loginSchema = z.object({
  email: z
    .string()
    .trim()
    .min(1, 'Please enter your email address')
    .email('Please enter a valid email address'),
  password: z
    .string()
    .min(1, 'Please enter your password'),
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
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        backgroundColor: "#002147",
        px: 2,
      }}
    >
      {/* Login Box */}
      <Box
        sx={{
          width: "100%",
          maxWidth: 440,
          height: 500,
          backgroundColor: "#ffffff",
          borderRadius: 3,
          p: { xs: 3, sm: 4 },
          boxShadow: "0 20px 50px rgba(0, 0, 0, 0.25)",
        }}
      >
        {/* Brand */}
        <Box sx={{ textAlign: "center", mb: 3 }}>
          <Typography
            sx={{
              color: "#002147",
              fontWeight: 800,
              fontSize: { xs: 24, sm: 28 },
              letterSpacing: "2px",
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
              letterSpacing: "3px",
              textTransform: "uppercase",
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
            textAlign: "center",
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
            textAlign: "center",
          }}
        >
          Sign in to continue to your workspace.
        </Typography>

        <Box
          component="form"
          onSubmit={handleSubmit(onSubmit)}
          noValidate
          sx={{ mt: 4 }}
        >
          <Stack spacing={2.5}>
            <TextField
              label="Work email"
              type="email"
              fullWidth
              autoComplete="username"
              {...register("email")}
              error={Boolean(errors.email)}
              helperText={errors.email?.message}
            />

            <TextField
              label="Password"
              type="password"
              fullWidth
              autoComplete="current-password"
              {...register("password")}
              error={Boolean(errors.password)}
              helperText={errors.password?.message}
            />

            <Box
              sx={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                gap: 1,
                flexWrap: "wrap",
              }}
            >
              <FormControlLabel
                control={
                  <Checkbox
                    checked={rememberMe}
                    onChange={(event) => setRememberMe(event.target.checked)}
                  />
                }
                label="Remember me"
              />

              <Link
                href="#"
                underline="hover"
                color="primary.main"
                sx={{
                  fontSize: 14,
                  fontWeight: 600,
                }}
              >
                Forgot password?
              </Link>
            </Box>

            <Button
              type="submit"
              variant="contained"
              size="large"
              disabled={isLoading}
              sx={{
                minHeight: 52,
                backgroundColor: "#002147",
                "&:hover": {
                  backgroundColor: "#003366",
                },
              }}
            >
              {isLoading ? (
                <>
                  <CircularProgress size={18} color="inherit" sx={{ mr: 1 }} />
                  Signing in...
                </>
              ) : (
                "Sign In"
              )}
            </Button>

            {loginError ? <Alert severity="error">{loginError}</Alert> : null}
          </Stack>
        </Box>

        <Typography
          sx={{
            mt: 4,
            textAlign: "center",
            color: colors.textSecondary,
            fontSize: 12,
          }}
        >
          Protected access for Lyra Pulse administrators
        </Typography>
      </Box>
    </Box>
  );
}

