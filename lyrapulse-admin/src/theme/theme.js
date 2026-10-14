import { createTheme } from '@mui/material/styles'
import { colors, palette } from './colors'
import { typography } from './typography'

const radius = { xs: 6, sm: 8, md: 12, lg: 16, chip: 7 }
const shadows = [
  'none',
  '0 1px 2px rgba(15, 23, 42, 0.04)',
  '0 2px 8px rgba(15, 23, 42, 0.06)',
  '0 8px 24px rgba(15, 23, 42, 0.08)',
  '0 16px 40px rgba(15, 23, 42, 0.12)',
  ...Array.from({ length: 20 }, (_, index) => `0 16px 40px rgba(15, 23, 42, ${0.13 + index * 0.005})`),
]

const theme = createTheme({
  palette: {
    primary: {
      main: palette.primary.navy,
      light: palette.primary.indigo,
      dark: palette.primary.royal,
      contrastText: colors.surface,
    },
    secondary: {
      main: palette.primary.purple,
      light: colors.secondarySoft,
      dark: colors.secondaryDark,
      contrastText: colors.surface,
    },
    success: { main: palette.success, light: colors.successBackground, dark: colors.successDark },
    warning: { main: palette.warning, light: colors.warningBackground, dark: colors.warningDark },
    error: { main: palette.error, light: colors.errorBackground, dark: colors.errorDark },
    info: { main: palette.info, light: colors.infoBackground, dark: colors.infoDark },
    background: { default: palette.background, paper: palette.paper },
    text: { primary: palette.text.primary, secondary: palette.text.secondary, disabled: colors.disabled },
    divider: palette.border,
    action: {
      hover: colors.hover,
      focus: colors.focusRing,
      disabled: colors.disabled,
      disabledBackground: colors.hover,
      selected: colors.selected,
    },
    lyra: palette.lyra,
  },
  shape: { borderRadius: radius.sm },
  spacing: 8,
  shadows,
  typography: { ...typography, fontFamily: typography.fontFamily },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        html: { minWidth: 320, scrollBehavior: 'smooth' },
        body: { backgroundColor: colors.background, color: colors.textPrimary, minHeight: '100vh' },
        '#root': { minHeight: '100vh' },
        '*': { boxSizing: 'border-box' },
        '::selection': { backgroundColor: colors.selection },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: ({ theme: activeTheme }) => ({
          borderRadius: radius.lg,
          border: `1px solid ${activeTheme.palette.divider}`,
          boxShadow: activeTheme.shadows[1],
          backgroundImage: 'none',
        }),
      },
    },
    MuiPaper: { styleOverrides: { root: { backgroundImage: 'none' } } },
    MuiButton: {
      defaultProps: { disableElevation: true },
      styleOverrides: {
        root: {
          minHeight: 40,
          borderRadius: radius.sm,
          paddingInline: 16,
          textTransform: 'none',
          fontWeight: 650,
          boxShadow: 'none',
          transition: 'background-color 140ms ease, border-color 140ms ease, box-shadow 140ms ease',
          '&:focus-visible': { outline: `3px solid ${colors.focus}`, outlineOffset: 2 },
        },
        sizeSmall: { minHeight: 32, paddingInline: 10 },
        sizeLarge: { minHeight: 48, paddingInline: 20 },
        containedPrimary: {
          '&:hover': { boxShadow: 'none' },
        },
        outlined: { borderColor: colors.border, '&:hover': { borderColor: colors.textSecondary } },
      },
    },
    MuiIconButton: {
      styleOverrides: {
        root: {
          borderRadius: radius.sm,
          '&:focus-visible': { outline: `3px solid ${colors.focus}`, outlineOffset: 2 },
        },
      },
    },
    MuiInputBase: { styleOverrides: { root: { borderRadius: radius.sm } } },
    MuiOutlinedInput: {
      styleOverrides: {
        root: {
          borderRadius: radius.sm,
          backgroundColor: colors.surface,
          '& .MuiOutlinedInput-notchedOutline': { borderColor: colors.border },
          '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: colors.borderStrong },
          '&.Mui-focused .MuiOutlinedInput-notchedOutline': { borderColor: colors.focus, borderWidth: 2 },
          '&.Mui-focused': { boxShadow: `0 0 0 3px ${colors.focusSubtle}` },
          '&.Mui-error .MuiOutlinedInput-notchedOutline': { borderColor: colors.error },
          '&.Mui-disabled': { backgroundColor: colors.surfaceMuted },
        },
        input: { minHeight: '1.35em' },
      },
    },
    MuiFormLabel: {
      styleOverrides: {
        root: { fontSize: '0.875rem', '&.Mui-focused': { color: colors.primaryBlue } },
      },
    },
    MuiFormHelperText: {
      styleOverrides: { root: { marginInline: 2, fontSize: '0.75rem' } },
    },
    MuiFormControlLabel: { styleOverrides: { label: { fontSize: '0.875rem' } } },
    MuiTableContainer: {
      styleOverrides: { root: { borderRadius: radius.lg, border: `1px solid ${colors.border}` } },
    },
    MuiTable: { styleOverrides: { root: { minWidth: 640 } } },
    MuiTableCell: {
      styleOverrides: {
        root: { padding: '13px 16px', borderBottomColor: colors.border },
        head: {
          color: colors.textSecondary,
          backgroundColor: colors.surfaceMuted,
          fontSize: '0.75rem',
          fontWeight: 700,
          letterSpacing: '0.04em',
          textTransform: 'uppercase',
          whiteSpace: 'nowrap',
        },
      },
    },
    MuiTableRow: { styleOverrides: { root: { '&:last-child td': { borderBottom: 0 } } } },
    MuiChip: {
      styleOverrides: {
        root: { height: 26, borderRadius: radius.chip, fontWeight: 650 },
        label: { paddingInline: 9 },
      },
    },
    MuiAvatar: {
      styleOverrides: {
        root: { fontSize: typography.subtitle2.fontSize, fontWeight: 700 },
      },
    },
    MuiDialog: {
      styleOverrides: {
        paper: { borderRadius: radius.lg, border: `1px solid ${colors.border}`, boxShadow: shadows[4], margin: 16 },
      },
    },
    MuiDialogTitle: { styleOverrides: { root: { padding: '24px 24px 8px', fontWeight: 700 } } },
    MuiDialogContent: { styleOverrides: { root: { padding: '16px 24px' } } },
    MuiDialogActions: { styleOverrides: { root: { padding: '16px 24px 24px', gap: 8 } } },
    MuiAlert: { styleOverrides: { root: { borderRadius: radius.sm }, message: { minWidth: 0 } } },
    MuiDrawer: {
      styleOverrides: {
        paper: { backgroundColor: colors.primaryDark, color: colors.sidebarText, borderRight: 'none' },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: 'rgba(255,255,255,0.94)',
          backdropFilter: 'blur(12px)',
          borderBottom: `1px solid ${colors.border}`,
          color: colors.textPrimary,
          boxShadow: 'none',
        },
      },
    },
    MuiTooltip: { styleOverrides: { tooltip: { borderRadius: radius.xs, fontSize: '0.75rem' } } },
  },
})

export default theme