import { createContext, useCallback, useContext, useMemo, useState } from 'react'
import { CssBaseline, ThemeProvider as MuiThemeProvider } from '@mui/material'
import { createAppTheme } from '../../theme/theme'

const MODE_KEY = 'lyrapulse_theme_mode'

// UI-only preference: which palette (light or dark) the admin shell renders with.
const ThemeModeContext = createContext({ mode: 'light', toggleMode: () => {} })

// eslint-disable-next-line react-refresh/only-export-components
export const useThemeMode = () => useContext(ThemeModeContext)

const readStoredMode = () => {
  try {
    return window.localStorage.getItem(MODE_KEY) === 'dark' ? 'dark' : 'light'
  } catch {
    return 'light'
  }
}

export function ThemeProvider({ children }) {
  const [mode, setMode] = useState(readStoredMode)

  const toggleMode = useCallback(() => {
    setMode((current) => {
      const next = current === 'dark' ? 'light' : 'dark'
      try {
        window.localStorage.setItem(MODE_KEY, next)
      } catch {
        // Storage can be unavailable (private mode); the toggle still works for this session.
      }
      return next
    })
  }, [])

  const theme = useMemo(() => createAppTheme(mode), [mode])
  const value = useMemo(() => ({ mode, toggleMode }), [mode, toggleMode])

  return (
    <ThemeModeContext.Provider value={value}>
      <MuiThemeProvider theme={theme}>
        <CssBaseline />
        {children}
      </MuiThemeProvider>
    </ThemeModeContext.Provider>
  )
}
