import { createTheme } from '@mui/material/styles'
import { palette } from './colors'
import { typography } from './typography'

const shadows = [
  'none',
  '0 1px 2px rgba(15, 23, 42, 0.04)',
  '0 4px 12px rgba(15, 23, 42, 0.08)',
  '0 10px 24px rgba(15, 23, 42, 0.08)',
  '0 18px 40px rgba(15, 23, 42, 0.1)',
  '0 22px 66px rgba(15, 23, 42, 0.12)',
  '0 30px 80px rgba(15, 23, 42, 0.12)',
  '0 36px 90px rgba(15, 23, 42, 0.12)',
  '0 40px 100px rgba(15, 23, 42, 0.12)',
  '0 42px 110px rgba(15, 23, 42, 0.12)',
  '0 44px 120px rgba(15, 23, 42, 0.12)',
  '0 50px 128px rgba(15, 23, 42, 0.12)',
  '0 60px 160px rgba(15, 23, 42, 0.12)',
  '0 70px 180px rgba(15, 23, 42, 0.14)',
  '0 80px 200px rgba(15, 23, 42, 0.14)',
  '0 90px 220px rgba(15, 23, 42, 0.14)',
  '0 100px 240px rgba(15, 23, 42, 0.14)',
  '0 110px 260px rgba(15, 23, 42, 0.14)',
  '0 120px 280px rgba(15, 23, 42, 0.16)',
  '0 130px 300px rgba(15, 23, 42, 0.16)',
  '0 140px 320px rgba(15, 23, 42, 0.16)',
  '0 150px 340px rgba(15, 23, 42, 0.16)',
  '0 160px 360px rgba(15, 23, 42, 0.18)',
  '0 170px 380px rgba(15, 23, 42, 0.18)',
  '0 180px 400px rgba(15, 23, 42, 0.18)',
]

const theme = createTheme({
  palette: {
    primary: {
      main: palette.primary.navy,
      light: palette.primary.indigo,
      dark: palette.primary.royal,
      contrastText: '#FFFFFF',
    },
    secondary: {
      main: palette.primary.purple,
      light: '#8B7CF7',
      dark: '#4338CA',
      contrastText: '#FFFFFF',
    },
    success: { main: palette.success },
    warning: { main: palette.warning },
    error: { main: palette.error },
    background: {
      default: palette.background,
      paper: palette.paper,
    },
    text: {
      primary: palette.text.primary,
      secondary: palette.text.secondary,
    },
    divider: '#E2E8F0',
  },
  shape: {
    borderRadius: 16,
  },
  shadows,
  typography: {
    ...typography,
    fontFamily: typography.fontFamily,
  },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        body: {
          backgroundColor: '#F5F7FB',
          color: '#0F172A',
        },
        '*': {
          boxSizing: 'border-box',
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 18,
          border: '1px solid rgba(226, 232, 240, 0.9)',
          boxShadow: '0 10px 28px rgba(15, 23, 42, 0.06)',
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          textTransform: 'none',
          fontWeight: 700,
          boxShadow: 'none',
        },
      },
    },
    MuiInputBase: {
      styleOverrides: {
        root: {
          borderRadius: 12,
        },
      },
    },
    MuiOutlinedInput: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          backgroundColor: '#FFFFFF',
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          backgroundImage: 'none',
        },
      },
    },
    MuiTableCell: {
      styleOverrides: {
        head: {
          fontWeight: 700,
          color: '#334155',
          backgroundColor: '#F8FAFC',
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          fontWeight: 700,
        },
      },
    },
    MuiDrawer: {
      styleOverrides: {
        paper: {
          backgroundColor: '#0B1638',
          borderRight: '1px solid rgba(148, 163, 184, 0.15)',
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: 'rgba(255,255,255,0.85)',
          backdropFilter: 'blur(14px)',
          borderBottom: '1px solid rgba(148, 163, 184, 0.16)',
          color: '#0F172A',
        },
      },
    },
  },
})

export default theme
