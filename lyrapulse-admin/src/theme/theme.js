import { createTheme } from '@mui/material/styles'
import { colors, palette } from './colors'
import { typography } from './typography'

const radius = { xs: 8, sm: 8, md: 12, lg: 12, chip: 8 }
const shadows = [
  'none',
  '0 1px 2px rgba(15, 23, 42, 0.04)',
  '0 2px 8px rgba(15, 23, 42, 0.06)',
  '0 8px 24px rgba(15, 23, 42, 0.08)',
  '0 16px 40px rgba(15, 23, 42, 0.12)',
  ...Array.from({ length: 20 }, (_, index) => `0 16px 40px rgba(15, 23, 42, ${0.13 + index * 0.005})`),
]

// Per-mode surface tokens. Every value is an existing token from colors.js; dark mode reuses the navy/sidebar tokens.
const modeTokens = {
  light: {
    background: colors.background,
    paper: colors.surface,
    muted: colors.surfaceMuted,
    input: colors.surface,
    textPrimary: colors.textPrimary,
    textSecondary: colors.textSecondary,
    border: colors.border,
    borderStrong: colors.borderStrong,
    hover: colors.hover,
    selected: colors.selected,
    appBar: 'rgba(255,255,255,0.94)',
    primaryMain: palette.primary.navy,
  },
  dark: {
    background: colors.primaryDark,
    paper: colors.primary,
    muted: colors.primaryDark,
    input: colors.primaryDark,
    textPrimary: colors.surfaceMuted,
    textSecondary: colors.sidebarMuted,
    border: colors.sidebarDivider,
    borderStrong: colors.sidebarMuted,
    hover: colors.sidebarHover,
    selected: colors.selection,
    appBar: colors.primary,
    primaryMain: colors.sidebarText,
  },
}

const selectionControl = {
  color: colors.borderStrong,
  '&:hover': { backgroundColor: colors.selected },
  '&.Mui-checked, &.MuiCheckbox-indeterminate': { color: colors.primaryBlue },
  '&.Mui-focusVisible': { backgroundColor: colors.focusSubtle, outline: `2px solid ${colors.primaryBlue}`, outlineOffset: -2 },
  '&.Mui-disabled': { color: colors.disabled, opacity: 0.55 },
  '&.Mui-checked.Mui-disabled': { color: colors.primaryBlue, opacity: 0.45 },
}

export function createAppTheme(mode = 'light') {
  const t = modeTokens[mode] ?? modeTokens.light

  return createTheme({
    palette: {
      mode,
      primary: {
        main: t.primaryMain,
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
      background: { default: t.background, paper: t.paper },
      text: { primary: t.textPrimary, secondary: t.textSecondary, disabled: colors.disabled },
      divider: t.border,
      action: {
        hover: t.hover,
        focus: colors.focusRing,
        disabled: colors.disabled,
        disabledBackground: t.hover,
        selected: t.selected,
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
          body: { backgroundColor: t.background, color: t.textPrimary, minHeight: '100vh' },
          '#root': { minHeight: '100vh' },
          '*': { boxSizing: 'border-box' },
          '::selection': { backgroundColor: colors.selection },
        },
      },
      // Cards and outlined panels share one surface: 12px radius, hairline border and the lowest elevation.
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
      MuiPaper: {
        styleOverrides: {
          root: { backgroundImage: 'none' },
          outlined: ({ theme: activeTheme }) => ({
            borderRadius: radius.md,
            borderColor: activeTheme.palette.divider,
          }),
        },
      },
      MuiButton: {
        defaultProps: { disableElevation: true },
        styleOverrides: {
          root: {
            minHeight: 40,
            borderRadius: radius.sm,
            paddingInline: 16,
            textTransform: 'none',
            fontWeight: typography.button.fontWeight,
            boxShadow: 'none',
            transition: 'background-color 150ms ease, border-color 150ms ease, box-shadow 150ms ease',
            '&:focus-visible': { outline: `3px solid ${colors.focus}`, outlineOffset: 2 },
          },
          sizeSmall: { minHeight: 32, paddingInline: 10 },
          sizeLarge: { minHeight: 48, paddingInline: 20 },
          outlined: { borderColor: t.border, '&:hover': { borderColor: t.textSecondary } },
        },
        // Primary action: the same primary -> secondary gradient used by the Login and Save Details buttons.
        variants: [
          {
            props: { variant: 'contained', color: 'primary' },
            style: {
              color: colors.surface,
              background: palette.lyra.primaryGradient,
              boxShadow: palette.lyra.actionShadow,
              fontWeight: typography.button.fontWeight,
              '&:hover': { background: palette.lyra.primaryGradient, boxShadow: palette.lyra.actionShadow },
              '&.Mui-disabled': { color: colors.surface, background: colors.disabled, boxShadow: 'none' },
            },
          },
        ],
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
            backgroundColor: t.input,
            '& .MuiOutlinedInput-notchedOutline': { borderColor: t.border },
            '&:hover .MuiOutlinedInput-notchedOutline': { borderColor: t.borderStrong },
            '&.Mui-focused .MuiOutlinedInput-notchedOutline': { borderColor: colors.focus, borderWidth: 2 },
            '&.Mui-focused': { boxShadow: `0 0 0 3px ${colors.focusSubtle}` },
            '&.Mui-error .MuiOutlinedInput-notchedOutline': { borderColor: colors.error },
            '&.Mui-disabled': { backgroundColor: t.muted },
          },
          input: { minHeight: '1.35em' },
        },
      },
      MuiFormLabel: {
        styleOverrides: {
          root: { fontSize: typography.body2.fontSize, fontWeight: 500, '&.Mui-focused': { color: colors.primaryBlue } },
        },
      },
      MuiFormHelperText: {
        styleOverrides: { root: { marginInline: 2, fontSize: typography.caption.fontSize, fontWeight: typography.caption.fontWeight } },
      },
      MuiFormControlLabel: { styleOverrides: { label: { fontSize: typography.body2.fontSize, fontWeight: typography.body2.fontWeight, '&.Mui-disabled': { color: colors.disabled } } } },
      // Selection controls share one rule: borderStrong when off, primaryBlue when on (same as the Login "Remember me" checkbox).
      MuiCheckbox: { styleOverrides: { root: selectionControl } },
      MuiRadio: { styleOverrides: { root: selectionControl } },
      MuiSwitch: {
        styleOverrides: {
          switchBase: {
            '&:hover': { backgroundColor: colors.selected },
            '&.Mui-checked': { color: colors.surface, '&:hover': { backgroundColor: colors.selected } },
            '&.Mui-checked + .MuiSwitch-track': { backgroundColor: colors.primaryBlue, opacity: 1 },
            '&.Mui-focusVisible': { outline: `2px solid ${colors.primaryBlue}`, outlineOffset: 1 },
            '&.Mui-disabled': { color: colors.surface },
            '&.Mui-disabled + .MuiSwitch-track': { opacity: 0.45 },
          },
          thumb: { color: colors.surface },
          track: { backgroundColor: colors.borderStrong, opacity: 1 },
        },
      },
      MuiMenu: {
        styleOverrides: {
          paper: ({ theme: activeTheme }) => ({
            borderRadius: radius.sm,
            border: `1px solid ${activeTheme.palette.divider}`,
            boxShadow: activeTheme.shadows[3],
            marginTop: 4,
          }),
          list: { padding: 6 },
        },
      },
      MuiMenuItem: {
        styleOverrides: {
          root: {
            borderRadius: radius.sm,
            fontSize: typography.body2.fontSize,
            fontWeight: 500,
            '&.Mui-selected': { backgroundColor: colors.selected, '&:hover': { backgroundColor: colors.focusSubtle } },
            '&.Mui-focusVisible': { backgroundColor: colors.focusSubtle },
          },
        },
      },
      MuiLink: { styleOverrides: { root: { color: colors.primaryBlue } } },
      MuiCircularProgress: { styleOverrides: { colorPrimary: { color: colors.primaryBlue } } },
      MuiTableContainer: {
        styleOverrides: { root: { borderRadius: radius.lg, border: `1px solid ${t.border}` } },
      },
      MuiTable: { styleOverrides: { root: { minWidth: 640 } } },
      MuiTableCell: {
        styleOverrides: {
          root: { padding: '13px 16px', borderBottomColor: t.border },
          head: {
            color: t.textSecondary,
            backgroundColor: t.muted,
            fontSize: typography.caption.fontSize,
            fontWeight: 600,
            letterSpacing: 0,
            textTransform: 'none',
            whiteSpace: 'nowrap',
          },
        },
      },
      MuiTableRow: { styleOverrides: { root: { '&:last-child td': { borderBottom: 0 } } } },
      MuiChip: {
        styleOverrides: {
          root: { height: 26, borderRadius: radius.chip, fontWeight: 500 },
          label: { paddingInline: 9 },
        },
      },
      MuiAvatar: {
        styleOverrides: {
          root: { fontSize: typography.subtitle2.fontSize, fontWeight: typography.subtitle2.fontWeight },
        },
      },
      MuiDialog: {
        styleOverrides: {
          paper: { borderRadius: radius.lg, border: `1px solid ${t.border}`, boxShadow: shadows[4], margin: 16 },
        },
      },
      MuiDialogTitle: { styleOverrides: { root: { padding: '24px 24px 8px', fontWeight: typography.h6.fontWeight } } },
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
            backgroundColor: t.appBar,
            backdropFilter: 'blur(12px)',
            borderBottom: `1px solid ${t.border}`,
            color: t.textPrimary,
            boxShadow: 'none',
          },
        },
      },
      MuiTooltip: { styleOverrides: { tooltip: { borderRadius: radius.xs, fontSize: '0.75rem' } } },
    },
  })
}

const theme = createAppTheme('light')

export default theme
  