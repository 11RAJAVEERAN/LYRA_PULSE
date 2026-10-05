import { useEffect, useRef, useState } from 'react'
import { Alert, Box, Button, Checkbox, CircularProgress, Collapse, FormControlLabel, Stack, TextField, Typography } from '@mui/material'
import { alpha } from '@mui/material/styles'
import ArrowForwardRounded from '@mui/icons-material/ArrowForwardRounded'
import CheckCircleRounded from '@mui/icons-material/CheckCircleRounded'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { colors } from '../../../theme/colors'
import loginIllustration from '../../../assets/lyra-login-img.png'

const OTP_LENGTH = 6
const RESEND_SECONDS = 30
const MOBILE_PATTERN = /^\+?\d{10,13}$/
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/

// Decides which flow the typed identifier belongs to.
function detectIdentifierType(value) {
  const trimmed = value.trim()
  if (!trimmed) return 'unknown'
  if (trimmed.includes('@')) return 'email'
  if (/^[+\d\s-]+$/.test(trimmed)) return 'mobile'
  return 'unknown'
}

const primaryButtonSx = {
  minHeight: { xs: 52, md: 'clamp(46px, 6.4vh, 58px)' },
  borderRadius: 999,
  fontSize: 16,
  color: colors.surface,
  backgroundImage: `linear-gradient(135deg, ${colors.primaryBlue} 0%, ${colors.primary} 100%)`,
  boxShadow: `0 10px 22px ${alpha(colors.primaryBlue, 0.22)}`,
  transition: 'box-shadow 0.2s ease, transform 0.2s ease',
  '&:hover': { boxShadow: `0 14px 28px ${alpha(colors.primaryBlue, 0.32)}`, transform: 'translateY(-1px)' },
  '&.Mui-disabled': {
    color: alpha(colors.textSecondary, 0.85),
    backgroundImage: 'none',
    backgroundColor: alpha(colors.textSecondary, 0.12),
    boxShadow: 'none',
  },
}

const makeFieldSx = (radius, height) => ({
  '& .MuiOutlinedInput-root': {
    borderRadius: radius,
    minHeight: height,
    backgroundColor: colors.surface,
    transition: 'box-shadow 0.2s ease',
    '& fieldset': { borderColor: alpha(colors.textSecondary, 0.45) },
    '&:hover fieldset': { borderColor: alpha(colors.primaryBlue, 0.6) },
    '&.Mui-focused': { boxShadow: `0 0 0 4px ${alpha(colors.primaryBlue, 0.12)}` },
    '&.Mui-focused fieldset': { borderColor: colors.primaryBlue, borderWidth: 2 },
    '&.Mui-error fieldset': { borderColor: colors.error },
  },
  '& .MuiInputLabel-root.Mui-focused': { color: colors.primaryBlue },
  '& .MuiInputBase-input': { px: 2.5 },
})

function BrandMark() {
  return (
    <Stack direction="row" alignItems="center" spacing={2}>
      <Box
        aria-hidden="true"
        sx={{
          width: { xs: 46, md: 56 },
          height: { xs: 46, md: 56 },
          borderRadius: '16px',
          display: 'grid',
          placeItems: 'center',
          color: colors.surface,
          fontSize: { xs: 24, md: 30 },
          fontWeight: 800,
          backgroundImage: `linear-gradient(135deg, ${colors.primaryBlue} 0%, ${colors.primary} 100%)`,
          boxShadow: `0 10px 24px ${alpha(colors.primaryBlue, 0.3)}`,
        }}
      >
        L
      </Box>
      <Box>
        <Typography sx={{ color: colors.primary, fontSize: { xs: 22, md: 32 }, fontWeight: 800, letterSpacing: '0.04em', lineHeight: 1.05 }}>
          LYRA PULSE
        </Typography>
        <Typography sx={{ mt: 0.5, color: colors.primaryBlue, fontSize: { xs: 11, md: 13 }, fontWeight: 600, letterSpacing: '0.45em' }}>
          ADMIN
        </Typography>
      </Box>
    </Stack>
  )
}

function OtpInput({ value, onChange, disabled, invalid, inputRefs, labelId }) {
  // Always holds the newest OTP string, so focus handlers never act on a stale `value`
  // (focus moves synchronously, before React re-renders with the new digit).
  const latest = useRef(value)
  useEffect(() => {
    latest.current = value
  }, [value])

  const focusBox = (index) => {
    const target = inputRefs.current[Math.max(0, Math.min(index, OTP_LENGTH - 1))]
    if (target) target.focus()
  }

  const commit = (next, focusIndex) => {
    latest.current = next
    onChange(next)
    focusBox(focusIndex)
  }

  const applyDigits = (index, digits) => {
    const current = latest.current
    const start = Math.min(index, current.length)
    const next = (current.slice(0, start) + digits).slice(0, OTP_LENGTH)
    commit(next, next.length)
  }

  const handleChange = (index, raw) => {
    const current = latest.current
    const digits = raw.replace(/\D/g, '')
    if (!digits) {
      if (index < current.length) {
        latest.current = current.slice(0, index) + current.slice(index + 1)
        onChange(latest.current)
      }
      return
    }
    if (digits.length === 1 && index < current.length) {
      commit(current.slice(0, index) + digits + current.slice(index + 1), index + 1)
      return
    }
    applyDigits(index, digits)
  }

  const handleKeyDown = (index, event) => {
    const current = latest.current
    if (event.key === 'Backspace' && !current[index] && index > 0) {
      event.preventDefault()
      commit(current.slice(0, index - 1) + current.slice(index), index - 1)
    } else if (event.key === 'ArrowLeft') {
      event.preventDefault()
      focusBox(index - 1)
    } else if (event.key === 'ArrowRight') {
      event.preventDefault()
      focusBox(index + 1)
    }
  }

  const handlePaste = (index, event) => {
    const digits = event.clipboardData.getData('text').replace(/\D/g, '')
    if (!digits) return
    event.preventDefault()
    applyDigits(index, digits.slice(0, OTP_LENGTH))
  }

  const boxSx = makeFieldSx('16px', { xs: 52, md: 'clamp(46px, 6.4vh, 56px)' })

  return (
    <Stack direction="row" role="group" aria-labelledby={labelId} spacing={{ xs: 0.75, sm: 1.25 }}>
      {Array.from({ length: OTP_LENGTH }, (_, index) => (
        <TextField
          key={index}
          value={value[index] ?? ''}
          disabled={disabled}
          error={invalid}
          onChange={(event) => handleChange(index, event.target.value)}
          onKeyDown={(event) => handleKeyDown(index, event)}
          onPaste={(event) => handlePaste(index, event)}
          onFocus={(event) => {
            if (index > latest.current.length) focusBox(latest.current.length)
            else event.target.select()
          }}
          inputRef={(node) => { inputRefs.current[index] = node }}
          sx={{ ...boxSx, flex: 1, minWidth: 0, '& .MuiInputBase-input': { px: 0 } }}
          slotProps={{
            htmlInput: {
              inputMode: 'numeric',
              pattern: '[0-9]*',
              autoComplete: index === 0 ? 'one-time-code' : 'off',
              'aria-label': `Verification code digit ${index + 1} of ${OTP_LENGTH}`,
              style: { textAlign: 'center', fontSize: 22, fontWeight: 700, padding: '10px 0', color: colors.textPrimary },
            },
          }}
        />
      ))}
    </Stack>
  )
}

export function LoginPage() {
  const navigate = useNavigate()
  const { sendOtp, verifyOtp, isLoading } = useAuth()
  const [identifier, setIdentifier] = useState('')
  const [otp, setOtp] = useState('')
  const [step, setStep] = useState('identifier')
  const [error, setError] = useState('')
  const [otpInvalid, setOtpInvalid] = useState(false)
  const [action, setAction] = useState('')
  const [cooldown, setCooldown] = useState(0)
  const [rememberMe, setRememberMe] = useState(false)
  const [password, setPassword] = useState('')
  const otpRefs = useRef([])
  const identifierRef = useRef(null)

  const otpSent = step === 'otp'
  const identifierType = detectIdentifierType(identifier)
  const isEmail = identifierType === 'email'
  const isMobile = identifierType === 'mobile'
  // Mobile numbers are sent without spaces/hyphens; emails are sent as typed (authService trims).
  const submitIdentifier = isMobile ? identifier.replace(/[\s-]/g, '') : identifier.trim()
  const identifierValid = isEmail ? EMAIL_PATTERN.test(submitIdentifier) : isMobile ? MOBILE_PATTERN.test(submitIdentifier) : false
  const otpComplete = otp.length === OTP_LENGTH

  const fieldLabel = isEmail ? 'Email' : isMobile ? 'Mobile Number' : 'Email or Mobile Number'
  const hint = isMobile ? 'We will send a 6-digit code to this number.' : ''

  useEffect(() => {
    if (cooldown <= 0) return undefined
    const timer = setTimeout(() => setCooldown((seconds) => seconds - 1), 1000)
    return () => clearTimeout(timer)
  }, [cooldown])

  const sendCode = async (isResend = false) => {
    if (isLoading || !identifierValid) return
    setError('')
    setOtpInvalid(false)
    setAction(isResend ? 'resend' : 'send')
    try {
      await sendOtp(submitIdentifier)
      setStep('otp')
      setOtp('')
      setCooldown(RESEND_SECONDS)
      setTimeout(() => otpRefs.current[0]?.focus(), 380)
    } catch (err) {
      setError(err.message || 'Unable to send verification code.')
    }
  }

  const verifyCode = async () => {
    if (isLoading || !otpComplete) return
    setError('')
    setOtpInvalid(false)
    setAction('verify')
    try {
      await verifyOtp({ identifier: submitIdentifier, otp, rememberMe })
      navigate('/dashboard', { replace: true })
    } catch (err) {
      setError(err.message || 'Unable to verify code.')
      setOtpInvalid(true)
      setTimeout(() => otpRefs.current[OTP_LENGTH - 1]?.focus(), 60)
    }
  }

  // Placeholder only: email/password sign-in is not implemented yet, so no API is called
  // and no session is created. Mobile + OTP is the only working authentication flow.
  const submitEmailPlaceholder = () => {
    if (!identifierValid || !password) return
    setError('Email and password sign-in is not available yet. Please sign in with your mobile number and OTP.')
  }

  // Switching between email and mobile resets the other flow's state.
  const handleIdentifierChange = (value) => {
    if (detectIdentifierType(value) !== identifierType) {
      setError('')
      setPassword('')
    }
    setIdentifier(value)
  }

  const handleSubmit = (event) => {
    event.preventDefault()
    if (isEmail) submitEmailPlaceholder()
    else if (otpSent) verifyCode()
    else sendCode(false)
  }

  const changeIdentifier = () => {
    setStep('identifier')
    setOtp('')
    setError('')
    setOtpInvalid(false)
    setCooldown(0)
    setTimeout(() => identifierRef.current?.focus(), 60)
  }

  const sending = isLoading && action === 'send'
  const resending = isLoading && action === 'resend'
  const verifying = isLoading && action === 'verify'

  const errorAlert = error ? (
    <Alert severity="error" sx={{ mt: 1.5, borderRadius: 3, py: 0.25 }}>
      {error}
    </Alert>
  ) : null

  return (
    <Box
      sx={{
        position: 'relative',
        minHeight: '100dvh',
        height: { md: '100dvh' },
        overflow: { md: 'hidden' },
        display: 'grid',
        gridTemplateColumns: { xs: '1fr', md: '1.1fr 0.9fr' },
        gridTemplateRows: { xs: 'auto 1fr', md: '1fr' },
        backgroundImage: `linear-gradient(135deg, ${colors.surface} 0%, ${alpha(colors.primaryBlue, 0.05)} 50%, ${alpha(colors.primaryBlue, 0.13)} 100%)`,
      }}
    >
      <Box sx={{ position: { md: 'absolute' }, top: { md: 'clamp(20px, 4vh, 44px)' }, left: { md: 'clamp(32px, 4.5vw, 88px)' }, px: { xs: 3, sm: 5, md: 0 }, pt: { xs: 3, md: 0 }, zIndex: 1 }}>
        <BrandMark />
      </Box>

      <Box
        sx={{
          display: { xs: 'none', md: 'flex' },
          flexDirection: 'column',
          minHeight: 0,
          pt: 'clamp(84px, 14vh, 130px)',
          pb: 'clamp(20px, 4vh, 48px)',
          pl: 'clamp(32px, 4.5vw, 88px)',
          pr: 2,
        }}
      >
        <Box sx={{ flex: 1, minHeight: 0, display: 'flex', alignItems: 'center' }}>
          <Box
            component="img"
            src={loginIllustration}
            alt="Administrator signing in securely to Lyra Pulse from a phone and laptop"
            sx={{ display: 'block', maxWidth: '100%', maxHeight: '100%', objectFit: 'contain', objectPosition: 'left center', mixBlendMode: 'multiply' }}
          />
        </Box>
        {/* <Box sx={{ pl: 1.5, pt: 'clamp(8px, 2vh, 24px)' }}>
          <Typography sx={{ color: colors.primary, fontSize: 'clamp(26px, 4.6vh, 46px)', fontWeight: 800, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
            Track Today,
            <Box component="span" sx={{ display: 'block', color: colors.primaryBlue }}>Build a Better Tomorrow</Box>
          </Typography>
          <Typography sx={{ mt: 1.25, maxWidth: 380, color: colors.textSecondary, fontSize: 'clamp(14px, 2.1vh, 18px)', lineHeight: 1.6 }}>
            Simple, smart and secure access for Lyra Pulse administrators.
          </Typography>
        </Box> */}
      </Box>

      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 0, px: { xs: 2, sm: 5, md: 3, lg: 6 }, py: { xs: 3, md: 2 } }}>
        <Box
          sx={{
            width: '100%',
            maxWidth: 540,
            maxHeight: { md: 'calc(100dvh - 32px)' },
            overflowY: { md: 'auto' },
            p: { xs: 3, sm: 5, md: 'clamp(24px, 5vh, 52px) clamp(28px, 3vw, 52px)' },
            borderRadius: { xs: '28px', md: '48px' },
            backgroundColor: colors.surface,
            border: `1px solid ${alpha(colors.border, 0.8)}`,
            boxShadow: `0 28px 64px ${alpha(colors.primaryBlue, 0.14)}`,
          }}
        >
          <Typography component="h1" sx={{ color: colors.primary, fontSize: { xs: 30, md: 'clamp(28px, 5vh, 42px)' }, fontWeight: 800, letterSpacing: '-0.02em', lineHeight: 1.15 }}>
            Welcome Back
          </Typography>
          <Typography sx={{ mt: 1, color: colors.textSecondary, fontSize: { xs: 15, md: 'clamp(14px, 2.1vh, 17px)' }, lineHeight: 1.5 }}>
            {otpSent ? 'Enter the OTP sent to your mobile number.' : 'Enter your email or mobile number to continue.'}
          </Typography>

          <Box component="form" onSubmit={handleSubmit} noValidate sx={{ mt: { xs: 3, md: 'clamp(16px, 3.4vh, 32px)' } }}>
            <TextField
              fullWidth
              id="login-identifier"
              label={fieldLabel}
              placeholder="Email or mobile number"
              value={identifier}
              onChange={(event) => handleIdentifierChange(event.target.value)}
              inputRef={identifierRef}
              autoFocus
              sx={makeFieldSx('28px', { xs: 56, md: 'clamp(48px, 7vh, 60px)' })}
              slotProps={{
                inputLabel: { shrink: true },
                input: { readOnly: otpSent },
                htmlInput: {
                  inputMode: isMobile ? 'tel' : 'text',
                  autoComplete: 'username',
                  autoCapitalize: 'none',
                  spellCheck: false,
                  'aria-describedby': 'login-identifier-hint',
                },
              }}
            />
            <Collapse in={Boolean(hint) && !otpSent} timeout={250}>
              <Typography id="login-identifier-hint" sx={{ mt: 0.75, ml: 2, color: colors.textSecondary, fontSize: 12.5, lineHeight: 1.4 }}>
                {hint}
              </Typography>
            </Collapse>

            {!isEmail && (
            <Button
              type={otpSent ? 'button' : 'submit'}
              fullWidth
              size="large"
              variant="contained"
              disabled={!identifierValid || isLoading || otpSent}
              endIcon={otpSent ? <CheckCircleRounded /> : sending ? null : <ArrowForwardRounded />}
              sx={{
                ...primaryButtonSx,
                mt: 'clamp(12px, 2.2vh, 20px)',
                '&.Mui-disabled': {
                  ...primaryButtonSx['&.Mui-disabled'],
                  ...(otpSent ? { color: colors.success, backgroundColor: alpha(colors.success, 0.1) } : {}),
                },
              }}
            >
              {sending ? <><CircularProgress size={18} color="inherit" sx={{ mr: 1 }} />Sending OTP...</> : otpSent ? 'OTP Sent' : 'Send OTP'}
            </Button>
            )}

            <Collapse in={isEmail} timeout={250} unmountOnExit>
              <Box sx={{ pt: 'clamp(12px, 2.2vh, 20px)' }}>
                <TextField
                  fullWidth
                  id="login-password"
                  type="password"
                  label="Password"
                  placeholder="Enter your password"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  sx={makeFieldSx('28px', { xs: 56, md: 'clamp(48px, 7vh, 60px)' })}
                  slotProps={{ inputLabel: { shrink: true }, htmlInput: { autoComplete: 'current-password' } }}
                />
                <Button
                  type="submit"
                  fullWidth
                  size="large"
                  variant="contained"
                  disabled={!identifierValid || !password}
                  endIcon={<ArrowForwardRounded />}
                  sx={{ ...primaryButtonSx, mt: 'clamp(12px, 2.2vh, 20px)' }}
                >
                  Login
                </Button>
              </Box>
            </Collapse>
            {!otpSent && errorAlert}

            <Collapse in={otpSent && !isEmail} timeout={350} unmountOnExit>
              <Box sx={{ pt: 'clamp(14px, 2.6vh, 24px)' }}>
                <Typography id="login-otp-label" component="label" sx={{ display: 'block', mb: 1, color: colors.textPrimary, fontSize: 14, fontWeight: 700 }} role="status" aria-live="polite">
                  Verification Code
                </Typography>
                <OtpInput
                  value={otp}
                  onChange={(next) => { setOtp(next); setOtpInvalid(false) }}
                  disabled={!otpSent || isLoading}
                  invalid={otpInvalid}
                  inputRefs={otpRefs}
                  labelId="login-otp-label"
                />

                <Stack direction="row" alignItems="center" justifyContent="space-between" flexWrap="wrap" sx={{ mt: 1, columnGap: 1 }}>
                  <Button type="button" size="small" onClick={changeIdentifier} disabled={isLoading} sx={{ ml: -1, color: colors.textPrimary, fontWeight: 700 }}>
                    {isEmail ? 'Change email' : 'Change number'}
                  </Button>
                  <Stack direction="row" alignItems="center" spacing={0.25}>
                    <Typography sx={{ color: colors.textSecondary, fontSize: 13 }}>Didn&apos;t receive the code?</Typography>
                    <Button
                      type="button"
                      size="small"
                      disabled={isLoading || cooldown > 0}
                      onClick={() => sendCode(true)}
                      sx={{ mr: -1, color: colors.primaryBlue, fontWeight: 700 }}
                    >
                      {resending ? 'Sending...' : cooldown > 0 ? `Resend in ${cooldown}s` : 'Resend OTP'}
                    </Button>
                  </Stack>
                </Stack>

                <FormControlLabel
                  sx={{ mt: 0, ml: -0.5, '& .MuiFormControlLabel-label': { fontSize: 14, color: colors.textPrimary } }}
                  control={<Checkbox size="small" checked={rememberMe} onChange={(event) => setRememberMe(event.target.checked)} sx={{ color: alpha(colors.textSecondary, 0.7), '&.Mui-checked': { color: colors.primaryBlue } }} />}
                  label="Remember me"
                />
                {errorAlert}

                <Button
                  type="submit"
                  fullWidth
                  size="large"
                  variant="contained"
                  disabled={!otpComplete || isLoading}
                  endIcon={verifying ? null : <ArrowForwardRounded />}
                  sx={{ ...primaryButtonSx, mt: 'clamp(10px, 1.8vh, 16px)' }}
                >
                  {verifying ? <><CircularProgress size={18} color="inherit" sx={{ mr: 1 }} />Verifying...</> : 'Verify OTP'}
                </Button>
              </Box>
            </Collapse>
          </Box>

          <Box sx={{ mt: 'clamp(14px, 3vh, 28px)', pt: 'clamp(10px, 2vh, 20px)', borderTop: `1px solid ${colors.border}` }}>
            <Typography sx={{ textAlign: 'center', color: colors.textSecondary, fontSize: 12.5 }}>
              Protected access for Lyra Pulse administrators
            </Typography>
          </Box>
        </Box>
      </Box>
    </Box>
  )
}