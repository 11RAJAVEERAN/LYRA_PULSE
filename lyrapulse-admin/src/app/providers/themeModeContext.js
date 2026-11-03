import { createContext, useContext } from 'react'

// UI-only preference: which palette (light or dark) the admin shell renders with.
export const ThemeModeContext = createContext({ mode: 'light', toggleMode: () => {} })

export const useThemeMode = () => useContext(ThemeModeContext)
