import { CssBaseline, ThemeProvider as MuiThemeProvider } from '@mui/material'
import theme from '../../theme/theme'

export function ThemeProvider({ children }) {
  return (
    <MuiThemeProvider theme={theme}>
      <CssBaseline />
      {children}
    </MuiThemeProvider>
  )
}
