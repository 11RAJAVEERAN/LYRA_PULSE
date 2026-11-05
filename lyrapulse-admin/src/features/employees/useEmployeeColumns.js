import { useCallback, useState } from 'react'
import { DEFAULT_VISIBLE_IDS, normalizeVisibleIds } from './employeeColumns'

const STORAGE_PREFIX = 'lyrapulse_admin_employee_columns_v1'

function load(key) {
  try {
    const saved = JSON.parse(localStorage.getItem(key) || 'null')
    if (saved && Array.isArray(saved.visible)) return normalizeVisibleIds(saved.visible)
  } catch {
    // Unreadable or unavailable storage: fall back to the defaults below.
  }
  return DEFAULT_VISIBLE_IDS
}

// Per-user saved column visibility. Purely a display preference: it never touches employee records.
export function useEmployeeColumns(userId) {
  const key = `${STORAGE_PREFIX}:${userId ?? 'default'}`
  const [visibleIds, setVisibleIds] = useState(() => load(key))

  const save = useCallback((ids) => {
    const next = normalizeVisibleIds(ids)
    setVisibleIds(next)
    try {
      localStorage.setItem(key, JSON.stringify({ visible: next }))
    } catch {
      // Storage is blocked (e.g. private mode): the choice still applies for this session.
    }
  }, [key])

  return { visibleIds, save, defaultIds: DEFAULT_VISIBLE_IDS }
}