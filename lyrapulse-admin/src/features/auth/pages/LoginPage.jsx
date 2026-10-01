import { Alert, Box, Button, CircularProgress, Stack, TextField, Typography } from '@mui/material'
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { colors } from '../../../theme/colors'

export function LoginPage() {
  const navigate = useNavigate()
  const { sendOtp, verifyOtp, isLoading } = useAuth()
  const [identifier, setIdentifier] = useState('')
  const [otp, setOtp] = useState('')
  const [step, setStep] = useState('identifier')
  const [error, setError] = useState('')

  const submitIdentifier = async (event) => {
    event.preventDefault()
    setError('')
    try {
      await sendOtp(identifier)
      setStep('otp')
    } catch (err) {
      setError(err.message || 'Unable to send verification code.')
    }
  }

  const submitOtp = async (event) => {
    event.preventDefault()
    setError('')
    try {
      await verifyOtp({ identifier, otp })
      navigate('/dashboard', { replace: true })
    } catch (err) {
      setError(err.message || 'Unable to verify code.')
    }
  }

  return (
    <Box sx={{ minHeight: '100vh', display: 'grid', gridTemplateColumns: { xs: '1fr', md: '1.08fr 0.92fr' }, backgroundColor: colors.surface }}>
      <Box sx={{ minHeight: { xs: 250, md: '100vh' }, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', px: { xs: 3, sm: 6, lg: 9 }, py: { xs: 4, md: 6 }, color: colors.surface, backgroundColor: colors.primaryDark }}>
        <Box><Typography sx={{ fontSize: 19, fontWeight: 750 }}>Lyra Pulse</Typography><Typography sx={{ mt: 0.5, color: 'rgba(255,255,255,0.62)', fontSize: 13 }}>PEOPLE OPERATIONS</Typography></Box>
        <Box sx={{ maxWidth: 650, py: { xs: 3, md: 7 } }}>
          <Typography component="h1" sx={{ fontSize: { xs: 34, sm: 44, lg: 56 }, lineHeight: 1.12, fontWeight: 650 }}>People, presence, and progress in one place.</Typography>
          <Typography sx={{ mt: 2.5, maxWidth: 490, color: 'rgba(255,255,255,0.72)', fontSize: 16, lineHeight: 1.7 }}>A clearer view of your workforce, from daily attendance to the people shaping your business.</Typography>
        </Box>
        <Typography sx={{ color: 'rgba(255,255,255,0.52)', fontSize: 12 }}>© 2026 Lyra Pulse · Secure workforce management</Typography>
      </Box>
      <Box sx={{ minHeight: { xs: 450, md: '100vh' }, display: 'flex', alignItems: 'center', justifyContent: 'center', px: { xs: 3, sm: 6, lg: 9 }, py: 6 }}>
        <Box sx={{ width: '100%', maxWidth: 440 }}>
          <Typography sx={{ color: colors.primaryBlue, fontWeight: 700, fontSize: 13 }}>LYRA PULSE ADMIN</Typography>
          <Typography component="h2" variant="h3" sx={{ mt: 1.5, fontSize: { xs: 30, md: 36 }, fontWeight: 650 }}>Welcome back</Typography>
          <Typography color="text.secondary" sx={{ mt: 1 }}>{step === 'identifier' ? 'Sign in with your registered email or mobile number.' : 'Enter the verification code sent to your registered mobile.'}</Typography>
          <Box component="form" onSubmit={step === 'identifier' ? submitIdentifier : submitOtp} noValidate sx={{ mt: 4 }}>
            <Stack spacing={2.5}>
              {step === 'identifier' ? <TextField label="Email or mobile number" autoComplete="username" value={identifier} onChange={(event) => setIdentifier(event.target.value)} required /> : <>
                <TextField label="Email or mobile number" value={identifier} disabled />
                <TextField label="6-digit verification code" inputMode="numeric" autoComplete="one-time-code" value={otp} onChange={(event) => setOtp(event.target.value.replace(/\D/g, '').slice(0, 6))} required />
              </>}
              <Button type="submit" variant="contained" size="large" disabled={isLoading || (step === 'otp' && otp.length !== 6)} sx={{ minHeight: 52 }}>
                {isLoading ? <><CircularProgress size={18} color="inherit" sx={{ mr: 1 }} />Please wait...</> : step === 'identifier' ? 'Send verification code' : 'Verify and sign in'}
              </Button>
              {step === 'otp' && <Button type="button" onClick={() => { setOtp(''); setStep('identifier') }}>Use a different email or mobile</Button>}
              {error && <Alert severity="error">{error}</Alert>}
            </Stack>
          </Box>
          <Typography sx={{ mt: 4, textAlign: 'center', color: colors.textSecondary, fontSize: 12 }}>Protected access for Lyra Pulse administrators</Typography>
        </Box>
      </Box>
    </Box>
  )
}
