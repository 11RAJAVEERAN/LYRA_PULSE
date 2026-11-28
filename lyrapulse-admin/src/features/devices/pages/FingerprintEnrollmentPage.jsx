import { useEffect, useMemo, useRef, useState } from 'react'
import {
  Alert, Avatar, Box, Button, Card, Chip, CircularProgress, Dialog, DialogActions, DialogContent,
  DialogTitle, FormControl, IconButton, LinearProgress, MenuItem, Paper, Select, Stack, Table,
  TableBody, TableCell, TableContainer, TableHead, TableRow, TablePagination, Tooltip, Typography,
} from '@mui/material'
import {
  ArrowLeft, BadgeCheck, Briefcase, Building2, CalendarClock, Check, CircleAlert, CircleCheck, Clock3, Fingerprint, Info,
  Minus, Settings, Signal, Trash2, User, Users, Wifi, X,
} from 'lucide-react'
import { PageHeader } from '../../../components/common/PageHeader'
import { SearchInput } from '../../../components/common/SearchInput'
import { EmptyState } from '../../../components/common/EmptyState'
import { LoadingState } from '../../../components/common/LoadingState'
import { DEFAULT_ROWS_PER_PAGE, ROWS_PER_PAGE_OPTIONS } from '../../employees/employeeColumns'
import { headCellSx } from '../../employees/components/ColumnHeader'
import { colors } from '../../../theme/colors'
import apiClient, { BRANCH_CONTEXT_EVENT } from '../../../services/apiClient'

const unwrap = response => response.data?.data ?? response.data
const terminalStatuses = ['SUCCESS', 'FAILED', 'EXPIRED', 'CANCELLED']
const activeStatuses = ['PENDING', 'WAITING_FOR_FINGER', 'WAITING_FOR_SECOND_SCAN', 'PROCESSING']
const enrollmentStatus = employee => employee?.fingerprint_enrollment?.status || 'NOT_ENROLLED'
const statusLabel = { ENROLLED: 'Enrolled', NOT_ENROLLED: 'Not Enrolled', PENDING: 'Pending', FAILED: 'Failed' }
const statusColor = { ENROLLED: 'success', NOT_ENROLLED: 'default', PENDING: 'warning', FAILED: 'error' }
const CARD_MAX_WIDTH = 440
const MODAL_WIDTH = 720
// Which layout the directory-row popup uses: 'card' = Selected Employee card, 'modal' = Employee Biometric Details.
const ENROLL_DIALOG_LAYOUT = 'card'

const formatDateTime = value => {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '—'
  return date.toLocaleString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false })
}

const formatDateOnly = value => {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '—'
  return date.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
}

const formatClock = value => {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: true })
}

function StatusBadge({ status }) {
  const Icon = { ENROLLED: BadgeCheck, NOT_ENROLLED: Check, PENDING: Clock3, FAILED: CircleAlert }[status] || Check
  return <Chip
    size="small"
    color={statusColor[status] || 'default'}
    icon={<Icon size={14} aria-hidden="true" />}
    label={statusLabel[status] || statusLabel.NOT_ENROLLED}
    sx={{ height: 24, fontWeight: 650, whiteSpace: 'nowrap', '& .MuiChip-icon': { ml: 0.75 } }}
  />
}

const directoryBadgeColors = {
  ENROLLED: { bgcolor: 'success.light', color: 'success.dark' },
  NOT_ENROLLED: { bgcolor: 'action.hover', color: '#475569' },
  PENDING: { bgcolor: 'warning.light', color: 'warning.dark' },
  FAILED: { bgcolor: 'error.light', color: 'error.dark' },
}

// Fixed 100 x 26 so the badge size never depends on the label length.
function DirectoryStatusBadge({ status }) {
  const key = directoryBadgeColors[status] ? status : 'NOT_ENROLLED'
  return <Box component="span" sx={{
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', boxSizing: 'border-box',
    width: 100, height: 26, px: 0.5, borderRadius: '8px',
    fontFamily: 'inherit', fontSize: '0.8125rem', fontWeight: 600, lineHeight: 1, whiteSpace: 'nowrap', textAlign: 'center',
    ...directoryBadgeColors[key],
  }}>{statusLabel[key]}</Box>
}

// Pill used by the Employee Biometric Details modal (employee status and per-finger status).
function StatusPill({ status, large = false }) {
  const key = directoryBadgeColors[status] ? status : 'NOT_ENROLLED'
  const Icon = { ENROLLED: CircleCheck, NOT_ENROLLED: Minus, PENDING: Clock3, FAILED: CircleAlert }[key]
  return <Box component="span" sx={{
    display: 'inline-flex', alignItems: 'center', gap: 0.75, flexShrink: 0, whiteSpace: 'nowrap',
    height: large ? 36 : 28, px: large ? 1.75 : 1.25, borderRadius: '999px',
    fontSize: large ? '0.9375rem' : '0.8125rem', fontWeight: 600, lineHeight: 1, ...directoryBadgeColors[key],
  }}><Icon size={large ? 18 : 15} aria-hidden="true" />{statusLabel[key]}</Box>
}

function FingerprintMark({ status = 'NOT_ENROLLED', size = 34 }) {
  return <Box sx={{
    width: size, height: size, flex: `0 0 ${size}px`, borderRadius: 1.5,
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    color: status === 'ENROLLED' ? 'primary.main' : status === 'PENDING' ? 'warning.dark' : status === 'FAILED' ? 'error.main' : 'text.secondary',
    bgcolor: 'action.hover',
  }} aria-hidden="true"><Fingerprint size={Math.max(16, size * 0.58)} strokeWidth={1.8} /></Box>
}

function statusMessage(error, fallback) {
  const data = error?.response?.data
  if (typeof data?.message === 'string') return data.message
  if (typeof data?.detail === 'string') return data.detail
  if (data?.errors) {
    if (Array.isArray(data.errors)) return data.errors.map(String).join(' ')
    if (typeof data.errors === 'object') return Object.values(data.errors).flat().join(' ')
  }
  return error?.message || fallback
}

export function FingerprintEnrollmentPage() {
  const [employees, setEmployees] = useState([])
  const [devices, setDevices] = useState([])
  const [branches, setBranches] = useState([])
  const [departments, setDepartments] = useState([])
  const [selectedId, setSelectedId] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [search, setSearch] = useState('')
  const [branchFilter, setBranchFilter] = useState('')
  const [statusFilter, setStatusFilter] = useState('ALL')
  const [departmentFilter, setDepartmentFilter] = useState('')
  const [page, setPage] = useState(1)
  const [rowsPerPage, setRowsPerPage] = useState(DEFAULT_ROWS_PER_PAGE)
  const [detailLoading, setDetailLoading] = useState(false)
  const [enrollment, setEnrollment] = useState(null)
  const [history, setHistory] = useState([])
  const [historyOpen, setHistoryOpen] = useState(false)
  const [historyLoading, setHistoryLoading] = useState(false)
  const [starting, setStarting] = useState(false)
  const [cancelling, setCancelling] = useState(false)
  const [secondStartFailed, setSecondStartFailed] = useState(false)
  const [enrollOpen, setEnrollOpen] = useState(false)
  const [finishing, setFinishing] = useState(false)
  const [showCard, setShowCard] = useState(false)
  const secondFingerStarted = useRef(false)
  const startLock = useRef(false)

  const reload = async (silent = false) => {
    if (!silent) setLoading(true)
    if (!silent) setError('')
    try {
      const [employeeResponse, deviceResponse, branchResponse, departmentResponse] = await Promise.all([
        apiClient.get('/employees/', { params: { status: 'active' } }),
        apiClient.get('/devices/'),
        apiClient.get('/branches/'),
        apiClient.get('/departments/'),
      ])
      const employeeRows = unwrap(employeeResponse) || []
      setEmployees(employeeRows)
      setDevices(unwrap(deviceResponse) || [])
      setBranches(unwrap(branchResponse) || [])
      setDepartments(unwrap(departmentResponse) || [])
    } catch (e) {
      setError(statusMessage(e, 'Unable to load employee fingerprint information.'))
    } finally {
      if (!silent) setLoading(false)
    }
  }

  useEffect(() => {
    void reload()
    const timer = setInterval(() => { void reload(true) }, 15000)
    return () => clearInterval(timer)
  }, [])

  useEffect(() => {
    window.addEventListener(BRANCH_CONTEXT_EVENT, reload)
    return () => window.removeEventListener(BRANCH_CONTEXT_EVENT, reload)
  }, [])

  const selectedEmployee = employees.find(employee => String(employee.id) === String(selectedId))
  const selectedStatus = enrollmentStatus(selectedEmployee)
  const selectedEnrollment = selectedEmployee?.fingerprint_enrollment
  const selectedBranchId = selectedEmployee?.branch_id ?? (typeof selectedEmployee?.branch === 'object' ? selectedEmployee?.branch?.id : selectedEmployee?.branch)
  const currentEnrollment = enrollment?.employee_id != null && String(enrollment.employee_id) === String(selectedId) ? enrollment : null
  const deviceForEmployee = devices.find(device => String(device.branch_id) === String(selectedBranchId) && device.is_active)

  useEffect(() => {
    if (!selectedId) return undefined
    let live = true
    setDetailLoading(true)
    setHistory([])
    apiClient.get(`/fingerprints/employees/${selectedId}/enrollments/`)
      .then(response => { if (live) setHistory(unwrap(response) || []) })
      .catch(e => { if (live) setError(statusMessage(e, 'Unable to load fingerprint details.')) })
      .finally(() => { if (live) setDetailLoading(false) })
    return () => { live = false }
  }, [selectedId])

  // Keep the finger cards and "Last Enrolled" current after an enrollment changes state.
  useEffect(() => {
    if (!selectedId || !terminalStatuses.includes(enrollment?.status)) return undefined
    let live = true
    apiClient.get(`/fingerprints/employees/${selectedId}/enrollments/`)
      .then(response => { if (live) setHistory(unwrap(response) || []) })
      .catch(() => {})
    return () => { live = false }
  }, [selectedId, enrollment?.status, enrollment?.finger])

  useEffect(() => {
    if (!selectedEmployee) return
    if (selectedStatus !== 'PENDING' || !selectedEnrollment?.enrollment_id) {
      if (enrollment && String(enrollment.employee_id) !== String(selectedEmployee.id)) setEnrollment(null)
      return
    }
    let live = true
    apiClient.get(`/fingerprints/employees/${selectedEmployee.id}/enrollments/${selectedEnrollment.enrollment_id}/`)
      .then(response => { if (live) setEnrollment(unwrap(response)) })
      .catch(e => { if (live) setError(statusMessage(e, 'Unable to resume the pending enrollment status.')) })
    return () => { live = false }
  }, [selectedEmployee?.id, selectedStatus, selectedEnrollment?.enrollment_id])

  useEffect(() => {
    if (enrollment?.status !== 'SUCCESS' || enrollment.finger !== 'first_finger' || secondFingerStarted.current) return
    secondFingerStarted.current = true
    setSecondStartFailed(false)
    apiClient.post(`/fingerprints/employees/${enrollment.employee_id}/enrollments/`, {
      device_id: enrollment.device_id,
      finger: 'second_finger',
    }).then(response => {
      const next = unwrap(response)
      setEnrollment(next)
      if (terminalStatuses.includes(next.status)) void reload(true)
    }).catch(e => {
      setSecondStartFailed(true)
      setError(statusMessage(e, 'The first finger is saved, but the second finger could not be started. Retry it here.'))
    })
  }, [enrollment?.status, enrollment?.finger, enrollment?.employee_id, enrollment?.device_id])

  useEffect(() => {
    if (!enrollment || terminalStatuses.includes(enrollment.status)) return undefined
    const timer = setInterval(async () => {
      try {
        const response = await apiClient.get(`/fingerprints/employees/${enrollment.employee_id}/enrollments/${enrollment.enrollment_id}/`)
        const next = unwrap(response)
        setEnrollment(next)
        if (terminalStatuses.includes(next.status)) {
          setNotice(next.status === 'SUCCESS' ? 'Fingerprint enrollment completed successfully.' : `Enrollment ${next.status.toLowerCase()}.`)
          void reload(true)
        }
      } catch (e) {
        setError(statusMessage(e, 'Unable to refresh enrollment progress.'))
      }
    }, 2500)
    return () => clearInterval(timer)
  }, [enrollment?.enrollment_id, enrollment?.employee_id, enrollment?.status])

  const filteredEmployees = useMemo(() => employees.filter(employee => {
    const query = search.trim().toLowerCase()
    const matchesSearch = !query || [employee.name, employee.employee_code, employee.id]
      .some(value => String(value ?? '').toLowerCase().includes(query))
    const branchId = employee.branch_id ?? (typeof employee.branch === 'object' ? employee.branch?.id : employee.branch)
    const matchesBranch = !branchFilter || String(branchId) === String(branchFilter)
    const employeeDepartmentId = employee.department_id ?? (typeof employee.department === 'object' ? employee.department?.id : employee.department)
    const matchesDepartment = !departmentFilter || String(employeeDepartmentId) === String(departmentFilter)
    const matchesStatus = statusFilter === 'ALL' || enrollmentStatus(employee) === statusFilter
    return matchesSearch && matchesBranch && matchesDepartment && matchesStatus
  }), [employees, search, branchFilter, departmentFilter, statusFilter])
  const pageCount = Math.max(1, Math.ceil(filteredEmployees.length / rowsPerPage))
  const safePage = Math.min(page, pageCount)
  const pageEmployees = filteredEmployees.slice((safePage - 1) * rowsPerPage, safePage * rowsPerPage)
  const selectedBranch = branches.find(item => String(item.id) === String(selectedBranchId))
  const selectedDepartmentId = selectedEmployee?.department_id ?? (typeof selectedEmployee?.department === 'object' ? selectedEmployee?.department?.id : selectedEmployee?.department)
  const selectedDepartmentName = selectedEmployee?.department_name || (typeof selectedEmployee?.department === 'object' ? selectedEmployee.department.name : departments.find(item => String(item.id) === String(selectedDepartmentId))?.name)
  const successfulFinger = finger => history.find(item => item.finger === finger && item.status === 'SUCCESS')
  const firstFinger = successfulFinger('first_finger')
  const secondFinger = successfulFinger('second_finger')
  const chooseEmployee = employee => {
    setError('')
    setNotice('')
    setEnrollment(null)
    setHistory([])
    setDetailLoading(true)
    secondFingerStarted.current = false
    setEnrollOpen(false)
    setSelectedId(String(employee.id))
  }

  // Directory row click: keep the directory on screen and open the registration modal for this employee.
  // This only opens the modal. Enrollment starts only from the modal's Start Enrollment button.
  const openEmployeeEnrollment = employee => {
    chooseEmployee(employee)
    setEnrollOpen(true)
  }

  // The "View" button keeps the existing Selected Employee card (history, progress).
  const viewEmployee = employee => {
    chooseEmployee(employee)
    setShowCard(true)
  }

  const startEnrollment = async () => {
    if (!selectedEmployee || startLock.current || ['ENROLLED', 'PENDING'].includes(selectedStatus)) return
    startLock.current = true
    setStarting(true)
    setError('')
    setNotice('')
    try {
      if (!selectedBranchId) throw new Error('The selected employee has no branch assigned.')
      const available = devices.filter(device => device.is_active && device.status === 'Online' && String(device.branch_id) === String(selectedBranchId))
      if (available.length !== 1) throw new Error(available.length ? 'More than one online device is assigned to this employee branch.' : 'No online fingerprint device is available at the employee branch.')
      secondFingerStarted.current = false
      setSecondStartFailed(false)
      const response = await apiClient.post(`/fingerprints/employees/${selectedEmployee.id}/enrollments/`, {
        device_id: available[0].device_id,
        finger: 'first_finger',
      })
      const next = unwrap(response)
      setEnrollment(next)
      setNotice('Enrollment started. Follow the device prompts for two captures on each of two fingers.')
      if (terminalStatuses.includes(next.status)) void reload(true)
    } catch (e) {
      setError(statusMessage(e, 'Fingerprint enrollment could not be started.'))
      void reload(true)
    } finally {
      startLock.current = false
      setStarting(false)
    }
  }

  // Opens the modal only. It must never start enrollment; the modal's Start Enrollment button does that.
  const openEnrollment = () => {
    if (!selectedEmployee || starting || selectedStatus === 'ENROLLED') return
    setEnrollOpen(true)
  }

  const retrySecondFinger = async () => {
    if (!enrollment) return
    try {
      const response = await apiClient.post(`/fingerprints/employees/${enrollment.employee_id}/enrollments/`, {
        device_id: enrollment.device_id,
        finger: 'second_finger',
      })
      const next = unwrap(response)
      secondFingerStarted.current = true
      setSecondStartFailed(false)
      setEnrollment(next)
    } catch (e) {
      setError(statusMessage(e, 'The second finger enrollment could not be started.'))
    }
  }

  const cancelEnrollment = async () => {
    if (!currentEnrollment || cancelling) return
    setCancelling(true)
    try {
      const response = await apiClient.delete(`/fingerprints/employees/${currentEnrollment.employee_id}/enrollments/${currentEnrollment.enrollment_id}/`)
      const next = unwrap(response)
      setEnrollment(next)
      setNotice('Enrollment cancelled.')
      void reload(true)
    } catch (e) {
      setError(statusMessage(e, 'Enrollment cancellation failed.'))
    } finally {
      setCancelling(false)
    }
  }

  const openHistory = async () => {
    if (!selectedEmployee) return
    setHistoryOpen(true)
    setHistoryLoading(true)
    setHistory([])
    try {
      const response = await apiClient.get(`/fingerprints/employees/${selectedEmployee.id}/enrollments/`)
      setHistory(unwrap(response) || [])
    } catch (e) {
      setError(statusMessage(e, 'Unable to load fingerprint enrollment history.'))
    } finally {
      setHistoryLoading(false)
    }
  }

  const goBack = () => {
    setShowCard(false)
    setSelectedId('')
    setEnrollment(null)
    setError('')
    setNotice('')
    setEnrollOpen(false)
    secondFingerStarted.current = false
  }
  const changeSearch = value => { setSearch(value); setPage(1) }
  const changeBranch = value => { setBranchFilter(value); setPage(1) }
  const changeStatus = value => { setStatusFilter(value); setPage(1) }
  const changeDepartment = value => { setDepartmentFilter(value); setPage(1) }
  const progress = currentEnrollment
  const progressStage = !progress ? -1
    : ['PENDING', 'WAITING_FOR_FINGER'].includes(progress.status) ? 0
      : progress.status === 'WAITING_FOR_SECOND_SCAN' ? 1
        : progress.status === 'PROCESSING' ? 3
          : progress.status === 'SUCCESS' ? 4
            : -1
  const stageLabels = ['Waiting', 'Scan 1', 'Scan 2', 'Processing', 'Completed']
  const employeeName = selectedEmployee?.name || selectedEmployee?.employee_code || 'Employee'
  const initials = employeeName.split(/\s+/).map(part => part[0]).join('').slice(0, 2).toUpperCase()
  const employeeBranchName = selectedEnrollment?.branch_name || selectedBranch?.name || '—'
  const employeeDepartmentName = selectedEnrollment?.department_name || selectedDepartmentName || '—'
  const enrollmentDevice = currentEnrollment ? devices.find(device => device.device_id === currentEnrollment.device_id) : deviceForEmployee
  const enrollmentDeviceOffline = currentEnrollment && (!enrollmentDevice || enrollmentDevice.status !== 'Online')

  // Finger state, derived only from real enrollment / backend data.
  const modalStatus = currentEnrollment?.status
  const modalScanning = activeStatuses.includes(modalStatus)
  const modalFirstDone = Boolean(firstFinger) || selectedStatus === 'ENROLLED'
    || (currentEnrollment?.finger === 'second_finger')
    || (currentEnrollment?.finger === 'first_finger' && modalStatus === 'SUCCESS')
  const modalSecondDone = Boolean(secondFinger) || selectedStatus === 'ENROLLED'
    || (currentEnrollment?.finger === 'second_finger' && modalStatus === 'SUCCESS')
  const canFinish = modalFirstDone && modalSecondDone
  const fingerCardState = done => done ? 'ENROLLED' : selectedStatus === 'PENDING' ? 'PENDING' : selectedStatus === 'FAILED' ? 'FAILED' : 'NOT_ENROLLED'
  const lastEnrolledAt = history
    .filter(item => item.status === 'SUCCESS' && (item.completed_at || item.created_at))
    .map(item => item.completed_at || item.created_at)
    .sort((a, b) => new Date(b) - new Date(a))[0]
  const activeFingerLabel = currentEnrollment?.finger === 'second_finger' ? 'Second Finger' : 'First Finger'
  const closeEnrollment = () => {
    setEnrollOpen(false)
    // Opened from the directory: return to the directory with nothing selected.
    if (!showCard) setSelectedId('')
  }

  const handleCancelEnrollment = async () => {
    if (starting || cancelling || finishing) return
    // Stop the automatic second-finger start while the modal is being dismissed.
    secondFingerStarted.current = true
    if (currentEnrollment && activeStatuses.includes(currentEnrollment.status)) await cancelEnrollment()
    else setError('')
    closeEnrollment()
  }

  const handleFinishEnrollment = async () => {
    if (!canFinish || finishing) return
    setFinishing(true)
    try {
      await reload(true)
      closeEnrollment()
    } finally {
      setFinishing(false)
    }
  }

  const renderEmployeeCard = inModal => <>
          <Box sx={{ px: 1.75, py: 1.1, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 1, bgcolor: 'primary.main', color: 'primary.contrastText' }}>
            <Stack direction="row" alignItems="center" spacing={0.9}><User size={16} aria-hidden="true" /><Typography variant="subtitle2" fontWeight={700}>Selected Employee</Typography></Stack>
            <DirectoryStatusBadge status={selectedStatus} />
          </Box>

          <Box sx={{ px: 2.5, pt: 2.25, pb: 1.75, minWidth: 0 }}>
            <Typography variant="h6" component="p" sx={{ color: 'text.primary', lineHeight: 1.3 }} noWrap>{employeeName}</Typography>
            <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.25 }} noWrap>{selectedEmployee.employee_code || selectedEmployee.id} · {employeeDepartmentName} · {employeeBranchName}</Typography>
          </Box>

          <Box sx={{ mx: 2.5, mb: 1.75, pt: 1.5, borderTop: '1px solid', borderColor: 'divider', display: 'grid', gridTemplateColumns: 'repeat(3, minmax(0, 1fr))', gap: 1 }}>
            {[[Building2, 'Branch', employeeBranchName], [Users, 'Department', employeeDepartmentName], [CalendarClock, 'Last Enrolled', formatDateTime(lastEnrolledAt)]].map(([Icon, label, value]) => <Stack key={label} direction="row" spacing={0.75} alignItems="flex-start" sx={{ minWidth: 0 }}>
              <Box sx={{ color: 'text.secondary', mt: 0.25, display: 'flex' }}><Icon size={14} aria-hidden="true" /></Box>
              <Box sx={{ minWidth: 0 }}>
                <Typography variant="caption" color="text.secondary" sx={{ display: 'block', lineHeight: 1.2 }}>{label}</Typography>
                <Typography variant="caption" fontWeight={700} sx={{ display: 'block', lineHeight: 1.3, overflowWrap: 'anywhere' }}>{value}</Typography>
              </Box>
            </Stack>)}
          </Box>

          <Box sx={{ px: 2.5, pb: 2, display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: 1.25 }}>
            {[['First Finger', modalFirstDone], ['Second Finger', modalSecondDone]].map(([label, done]) => {
              const state = fingerCardState(done)
              return <Paper key={label} variant="outlined" sx={{ p: 1, display: 'flex', alignItems: 'center', gap: 1, borderRadius: 1.5, bgcolor: done ? 'success.50' : 'background.paper', borderColor: done ? 'success.light' : state === 'FAILED' ? 'error.light' : 'divider' }}>
                <FingerprintMark status={state} size={30} />
                <Box sx={{ minWidth: 0 }}>
                  <Typography variant="body2" fontWeight={700} noWrap>{label}</Typography>
                  <Stack direction="row" alignItems="center" spacing={0.4}>
                    {done ? <Check size={12} aria-hidden="true" /> : null}
                    <Typography variant="caption" color={done ? 'success.dark' : state === 'FAILED' ? 'error.main' : 'text.secondary'} noWrap>{statusLabel[state]}</Typography>
                  </Stack>
                </Box>
              </Paper>
            })}
          </Box>

          {detailLoading ? <LinearProgress sx={{ mx: 2.5, mb: 1.25 }} /> : null}

          <Stack direction="row" spacing={1} sx={{ px: 2.5, pb: 2.25 }}>
            <Button variant="contained" size="small" startIcon={starting ? undefined : <Fingerprint size={15} />} disabled={starting || selectedStatus === 'ENROLLED' || (inModal ? (selectedStatus === 'PENDING' || modalScanning || !deviceForEmployee || deviceForEmployee.status !== 'Online') : (selectedStatus !== 'PENDING' && (!deviceForEmployee || deviceForEmployee.status !== 'Online')))} onClick={inModal ? startEnrollment : openEnrollment} sx={{ flex: '1.35 1 0', minWidth: 0, minHeight: 36, whiteSpace: 'nowrap', px: 1 }}>{starting ? <CircularProgress size={16} color="inherit" /> : selectedStatus === 'ENROLLED' ? 'Already Enrolled' : selectedStatus === 'PENDING' ? (inModal ? 'In Progress' : 'Resume Enrollment') : selectedStatus === 'FAILED' ? 'Retry Enrollment' : 'Start Enrollment'}</Button>
            <Button variant="outlined" size="small" startIcon={<Clock3 size={15} />} onClick={openHistory} disabled={historyLoading} sx={{ flex: '1 1 0', minWidth: 0, minHeight: 36, whiteSpace: 'nowrap', px: 1 }}>View History</Button>
            <Tooltip title="Fingerprint removal is unavailable because this system has no backend-to-device slot deletion workflow."><span style={{ flex: '0.9 1 0', minWidth: 0, display: 'flex' }}><Button fullWidth variant="outlined" color="error" size="small" startIcon={<Trash2 size={15} />} disabled sx={{ minHeight: 36, whiteSpace: 'nowrap', px: 1 }}>Remove</Button></span></Tooltip>
          </Stack>

          <Box sx={{ px: 2.5, pt: 2, pb: 2.25, borderTop: '1px solid', borderColor: 'divider' }}>
            <Stack direction="row" alignItems="center" spacing={0.9} sx={{ mb: 1.5 }}>
              <Box component="span" sx={{ display: 'flex', color: 'primary.main' }}><Fingerprint size={17} aria-hidden="true" /></Box>
              <Typography variant="subtitle2" fontWeight={700}>Enrollment Progress</Typography>
              <Box sx={{ flex: 1 }} />
              {progress ? <Chip size="small" label={`${activeFingerLabel} · ${progress.status}`} sx={{ height: 22, fontSize: 11 }} /> : null}
            </Stack>

            {currentEnrollment && ['FAILED', 'EXPIRED', 'CANCELLED'].includes(currentEnrollment.status)
              ? <Alert severity={currentEnrollment.status === 'FAILED' ? 'error' : 'warning'} sx={{ py: 0 }}>{currentEnrollment.status === 'FAILED' ? `Enrollment failed${currentEnrollment.failure_reason ? `: ${currentEnrollment.failure_reason}` : '.'}` : `Enrollment ${currentEnrollment.status.toLowerCase()}.`}</Alert>
              : enrollmentDeviceOffline && activeStatuses.includes(currentEnrollment?.status)
                ? <Alert severity="warning" sx={{ py: 0 }}>The device is offline. Enrollment status will refresh when it reconnects.</Alert>
                : <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(5, minmax(0, 1fr))', alignItems: 'start' }}>
                  {stageLabels.map((label, index) => {
                    const complete = progressStage >= index && progressStage >= 0
                    const current = progressStage === index
                    return <Box key={label} sx={{ textAlign: 'center', position: 'relative', px: 0.25 }}>
                      {index < stageLabels.length - 1 ? <Box sx={{ position: 'absolute', height: 2, bgcolor: progressStage > index ? 'primary.main' : 'divider', left: '50%', right: '-50%', top: 11, zIndex: 0 }} /> : null}
                      <Box sx={{ position: 'relative', zIndex: 1, width: 24, height: 24, borderRadius: '50%', mx: 'auto', display: 'grid', placeItems: 'center', border: '2px solid', borderColor: complete ? 'primary.main' : 'divider', bgcolor: complete ? 'primary.main' : 'background.paper', color: complete ? 'primary.contrastText' : 'text.disabled' }}>{complete && !current ? <Check size={13} /> : current ? <Fingerprint size={13} /> : <span style={{ fontSize: 10 }}>{index + 1}</span>}</Box>
                      <Typography variant="caption" fontWeight={current ? 700 : 500} color={current ? 'primary.main' : 'text.secondary'} sx={{ display: 'block', mt: 0.5, fontSize: 11, lineHeight: 1.2 }}>{label}</Typography>
                    </Box>
                  })}
                </Box>}

            <Stack direction="row" alignItems="center" justifyContent="space-between" spacing={1} sx={{ mt: 1.25, px: 1.25, py: 0.75, borderRadius: 1.5, bgcolor: 'primary.50', color: 'primary.dark' }}>
              <Stack direction="row" spacing={0.9} alignItems="center" sx={{ minWidth: 0 }}><Info size={15} style={{ flex: '0 0 auto' }} /><Typography variant="caption">{activeStatuses.includes(currentEnrollment?.status) ? currentEnrollment.status === 'WAITING_FOR_SECOND_SCAN' ? 'Remove the finger, then place the same finger again when prompted.' : 'Place your finger on the device sensor when prompted.' : 'Start an enrollment to see live progress from the device.'}</Typography></Stack>
              <Stack direction="row" spacing={0.5} sx={{ flex: '0 0 auto' }}>
                {activeStatuses.includes(currentEnrollment?.status) ? <Button size="small" color="inherit" disabled={cancelling} onClick={inModal ? handleCancelEnrollment : cancelEnrollment} sx={{ fontSize: 11.5, py: 0 }}>{cancelling ? <CircularProgress size={14} /> : 'Cancel'}</Button> : null}
                {inModal && !activeStatuses.includes(currentEnrollment?.status) ? <Button size="small" color="inherit" disabled={starting || finishing} onClick={canFinish ? handleFinishEnrollment : handleCancelEnrollment} sx={{ fontSize: 11.5, py: 0 }}>{finishing ? <CircularProgress size={14} /> : 'Close'}</Button> : null}
                {secondStartFailed && enrollment ? <Button size="small" onClick={retrySecondFinger} sx={{ fontSize: 11.5, py: 0 }}>Retry second finger</Button> : null}
              </Stack>
            </Stack>
          </Box>
  </>

  // Employee Biometric Details modal. Same state, handlers and API calls as the card above; presentation only.
  const lastEnrolledValue = selectedEnrollment?.last_enrolled || lastEnrolledAt
  const enrollmentFailedState = currentEnrollment && ['FAILED', 'EXPIRED', 'CANCELLED'].includes(currentEnrollment.status)
  const enrollmentAllDone = currentEnrollment ? currentEnrollment.status === 'SUCCESS' : selectedStatus === 'ENROLLED'
  const enrollmentActiveStep = !currentEnrollment ? -1
    : ['PENDING', 'WAITING_FOR_FINGER'].includes(currentEnrollment.status) ? 0
      : currentEnrollment.status === 'WAITING_FOR_SECOND_SCAN' ? 2
        : currentEnrollment.status === 'PROCESSING' ? 3
          : -1
  const timelineSteps = [['Waiting', Wifi], ['Scan 1', Fingerprint], ['Scan 2', Fingerprint], ['Processing', Settings], ['Completed', Check]].map(([label, Icon], index) => ({
    label,
    Icon,
    state: enrollmentAllDone ? 'done' : enrollmentActiveStep < 0 ? 'todo' : index < enrollmentActiveStep ? 'done' : index === enrollmentActiveStep ? 'current' : 'todo',
    // The status API records no per-step timestamps, so only the final step can show a real time (the saved fingerprint's creation time).
    time: index === 4 && enrollmentAllDone ? formatClock(lastEnrolledValue) : '',
  }))
  const stepColor = state => state === 'done' ? 'success.main' : state === 'current' ? 'info.main' : 'text.disabled'
  const modalActionSx = { minHeight: 44, px: 3 }

  const renderEmployeeModal = () => <>
    <Box sx={{ px: 3, py: 1.75, display: 'flex', alignItems: 'center', gap: 2, bgcolor: 'primary.main', color: 'primary.contrastText' }}>
      <Fingerprint size={26} aria-hidden="true" />
      <Box sx={{ alignSelf: 'stretch', width: '1px', bgcolor: 'rgba(255,255,255,0.28)' }} />
      <Typography variant="h6" component="h2" sx={{ flex: 1, minWidth: 0, fontWeight: 700 }} noWrap>Employee Biometric Details</Typography>
      <IconButton aria-label="Close" color="inherit" disabled={modalScanning || starting} onClick={() => { void handleCancelEnrollment() }} sx={{ mr: -1 }}><X size={22} aria-hidden="true" /></IconButton>
    </Box>

    {error ? <Alert severity="error" sx={{ borderRadius: 0 }} action={secondStartFailed && enrollment ? <Button color="inherit" size="small" onClick={retrySecondFinger}>Retry second finger</Button> : null}>{error}</Alert> : null}

    <Box sx={{ px: 3, pt: 2.5, pb: 3, bgcolor: 'background.paper' }}>
      <Stack direction="row" alignItems="flex-start" justifyContent="space-between" spacing={2} sx={{ pb: 2, borderBottom: '1px solid', borderColor: 'divider' }}>
        <Box sx={{ minWidth: 0 }}>
          <Typography variant="h4" component="p" sx={{ color: 'primary.main', fontWeight: 700, lineHeight: 1.25, overflowWrap: 'anywhere' }}>{employeeName}</Typography>
          <Typography variant="body1" sx={{ color: 'text.secondary', mt: 0.5, overflowWrap: 'anywhere' }}>{selectedEmployee.employee_code || selectedEmployee.id} · {employeeDepartmentName} · {employeeBranchName}</Typography>
        </Box>
        <StatusPill status={selectedStatus} large />
      </Stack>

      <Box sx={{ py: 2, display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'repeat(3, minmax(0, 1fr))' }, rowGap: 1.5 }}>
        {[[Building2, 'Branch', employeeBranchName], [Briefcase, 'Department', employeeDepartmentName], [CalendarClock, 'Last Enrolled', formatDateOnly(lastEnrolledValue)]].map(([Icon, label, value], index) => <Stack key={label} direction="row" spacing={1.5} alignItems="center" sx={{ minWidth: 0, pl: { sm: index === 0 ? 0 : 2.5 }, borderLeft: { sm: index === 0 ? 'none' : '1px solid' }, borderColor: 'divider' }}>
          <Box sx={{ color: 'text.secondary', display: 'flex', flexShrink: 0 }}><Icon size={26} strokeWidth={1.6} aria-hidden="true" /></Box>
          <Box sx={{ minWidth: 0 }}>
            <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', lineHeight: 1.3 }}>{label}</Typography>
            <Typography variant="subtitle1" sx={{ color: 'text.primary', lineHeight: 1.35, overflowWrap: 'anywhere' }}>{value}</Typography>
          </Box>
        </Stack>)}
      </Box>

      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, minmax(0, 1fr))' }, gap: 2 }}>
        {[['First Finger', modalFirstDone], ['Second Finger', modalSecondDone]].map(([label, done]) => {
          const state = fingerCardState(done)
          return <Paper key={label} variant="outlined" sx={{ p: 2, display: 'flex', alignItems: 'center', gap: 2, bgcolor: 'info.light', borderColor: 'divider' }}>
            <Box sx={{ width: 56, height: 56, flexShrink: 0, borderRadius: '50%', display: 'grid', placeItems: 'center', bgcolor: colors.selection, color: 'info.main' }} aria-hidden="true"><Fingerprint size={30} strokeWidth={1.8} /></Box>
            <Box sx={{ alignSelf: 'stretch', width: '1px', bgcolor: 'divider' }} />
            <Box sx={{ minWidth: 0 }}>
              <Typography variant="subtitle1" sx={{ color: 'text.primary', fontWeight: 700, mb: 0.75 }} noWrap>{label}</Typography>
              <StatusPill status={state} />
            </Box>
          </Paper>
        })}
      </Box>

      {detailLoading ? <LinearProgress sx={{ mt: 2 }} /> : null}

      <Paper variant="outlined" sx={{ mt: 2, px: 2.5, py: 2, borderColor: 'divider' }}>
        <Stack direction="row" alignItems="center" spacing={1.25} sx={{ mb: 2 }}>
          <Box sx={{ color: 'info.main', display: 'flex' }}><Signal size={22} aria-hidden="true" /></Box>
          <Typography variant="subtitle1" sx={{ color: 'text.primary', fontWeight: 700, flex: 1 }}>Enrollment Progress</Typography>
          {enrollmentAllDone
            ? <Box component="span" sx={{ display: 'inline-flex', alignItems: 'center', gap: 0.75, height: 32, px: 1.5, borderRadius: '8px', bgcolor: 'success.light', color: 'success.dark', fontSize: '0.875rem', fontWeight: 600 }}><Check size={16} aria-hidden="true" />Completed</Box>
            : progress ? <Chip size="small" label={`${activeFingerLabel} · ${progress.status}`} sx={{ height: 24, fontSize: 12 }} /> : null}
        </Stack>

        {enrollmentFailedState
          ? <Alert severity={currentEnrollment.status === 'FAILED' ? 'error' : 'warning'} sx={{ py: 0 }}>{currentEnrollment.status === 'FAILED' ? `Enrollment failed${currentEnrollment.failure_reason ? `: ${currentEnrollment.failure_reason}` : '.'}` : `Enrollment ${currentEnrollment.status.toLowerCase()}.`}</Alert>
          : enrollmentDeviceOffline && activeStatuses.includes(currentEnrollment?.status)
            ? <Alert severity="warning" sx={{ py: 0 }}>The device is offline. Enrollment status will refresh when it reconnects.</Alert>
            : <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(5, minmax(0, 1fr))', alignItems: 'start' }} role="list" aria-label="Enrollment progress">
              {timelineSteps.map(({ label, Icon, state, time }, index) => {
                const finalDone = index === 4 && state === 'done'
                return <Box key={label} role="listitem" aria-current={state === 'current' ? 'step' : undefined} sx={{ textAlign: 'center', position: 'relative', px: 0.5 }}>
                  {index < timelineSteps.length - 1 ? <Box sx={{ position: 'absolute', height: 2, left: '50%', right: '-50%', top: 19, zIndex: 0, bgcolor: timelineSteps[index + 1].state === 'done' ? 'success.main' : timelineSteps[index + 1].state === 'current' ? 'info.main' : 'divider' }} /> : null}
                  <Box sx={{
                    position: 'relative', zIndex: 1, width: 40, height: 40, borderRadius: '50%', mx: 'auto', display: 'grid', placeItems: 'center',
                    border: '2px solid', borderColor: state === 'done' ? 'success.main' : state === 'current' ? 'info.main' : 'transparent',
                    bgcolor: finalDone ? 'success.main' : state === 'done' ? 'success.light' : state === 'current' ? 'info.light' : 'action.hover',
                    color: finalDone ? 'success.contrastText' : stepColor(state),
                  }}><Icon size={20} strokeWidth={finalDone ? 2.5 : 1.9} aria-hidden="true" /></Box>
                  <Typography variant="body2" sx={{ display: 'block', mt: 0.75, fontWeight: 600, lineHeight: 1.3, color: state === 'current' ? 'info.main' : state === 'done' ? 'text.primary' : 'text.secondary' }}>{label}</Typography>
                  {time ? <Typography variant="caption" sx={{ display: 'block', color: 'text.secondary', lineHeight: 1.4, fontVariantNumeric: 'tabular-nums' }}>{time}</Typography> : null}
                </Box>
              })}
            </Box>}

        {modalScanning ? <Stack direction="row" spacing={0.9} alignItems="center" sx={{ mt: 1.5, color: 'text.secondary' }}><Info size={15} style={{ flex: '0 0 auto' }} aria-hidden="true" /><Typography variant="caption">{currentEnrollment.status === 'WAITING_FOR_SECOND_SCAN' ? 'Remove the finger, then place the same finger again when prompted.' : 'Place your finger on the device sensor when prompted.'}</Typography></Stack> : null}
      </Paper>

      <Stack direction="row" spacing={1.5} justifyContent="flex-end" flexWrap="wrap" useFlexGap sx={{ mt: 3, pt: 2.5, borderTop: '1px solid', borderColor: 'divider' }}>
        <Button variant="outlined" startIcon={<Clock3 size={18} aria-hidden="true" />} onClick={openHistory} disabled={historyLoading} sx={{ ...modalActionSx, color: 'text.primary' }}>View History</Button>
        {secondStartFailed && enrollment ? <Button variant="outlined" onClick={retrySecondFinger} sx={modalActionSx}>Retry second finger</Button> : null}
        {selectedStatus !== 'ENROLLED' ? <Button variant="contained" startIcon={starting ? undefined : <Fingerprint size={18} aria-hidden="true" />} disabled={starting || selectedStatus === 'PENDING' || modalScanning || !deviceForEmployee || deviceForEmployee.status !== 'Online'} onClick={startEnrollment} sx={modalActionSx}>{starting ? <CircularProgress size={18} color="inherit" /> : selectedStatus === 'PENDING' ? 'In Progress' : selectedStatus === 'FAILED' ? 'Retry Enrollment' : 'Start Enrollment'}</Button> : null}
        {modalScanning
          ? <Button variant="contained" disabled={cancelling} onClick={handleCancelEnrollment} sx={{ ...modalActionSx, background: 'none', bgcolor: 'primary.main', boxShadow: 'none', '&:hover': { background: 'none', bgcolor: 'primary.main', opacity: 0.92, boxShadow: 'none' } }}>{cancelling ? <CircularProgress size={18} color="inherit" /> : 'Cancel'}</Button>
          : <Button variant="contained" disabled={starting || finishing} onClick={canFinish ? handleFinishEnrollment : handleCancelEnrollment} sx={{ ...modalActionSx, background: 'none', bgcolor: 'primary.main', boxShadow: 'none', '&:hover': { background: 'none', bgcolor: 'primary.main', opacity: 0.92, boxShadow: 'none' } }}>{finishing ? <CircularProgress size={18} color="inherit" /> : 'Close'}</Button>}
      </Stack>
    </Box>
  </>

  return <Box sx={showCard ? { p: { xs: 1.5, md: 2.5 }, maxWidth: 1500, mx: 'auto', width: '100%', minWidth: 0 } : { minWidth: 0, maxWidth: '100%' }}>
    {error ? <Alert severity="error" onClose={() => setError('')} sx={{ mb: 1.5, ...(showCard ? { maxWidth: CARD_MAX_WIDTH, mx: 'auto' } : {}) }}>{error}</Alert> : null}
    {notice ? <Alert severity="info" onClose={() => setNotice('')} sx={{ mb: 1.5, ...(showCard ? { maxWidth: CARD_MAX_WIDTH, mx: 'auto' } : {}) }}>{notice}</Alert> : null}

    {!showCard ? <>
      <PageHeader title="Fingerprint Enrollment" subtitle="Manage and monitor employee fingerprint registration." />

      <Card sx={{ mb: 2 }}>
        <Box sx={{ p: { xs: 1.5, sm: 2 } }}>
          <Stack direction={{ xs: 'column', md: 'row' }} sx={{ gap: 1.5, alignItems: { md: 'center' }, justifyContent: 'space-between' }}>
            <Typography variant="h6" component="h2" sx={{ color: 'text.primary', whiteSpace: 'nowrap' }}>Employee Directory</Typography>
            <Stack direction={{ xs: 'column', sm: 'row' }} sx={{ gap: 1, alignItems: { sm: 'center' }, flexWrap: { sm: 'wrap' }, minWidth: 0, maxWidth: '100%' }}>
              <Box sx={{ width: { xs: '100%', sm: 320 }, maxWidth: '100%' }}>
                <SearchInput value={search} onChange={changeSearch} label="Search employees" placeholder="Search by name or ID..." />
              </Box>
              <FormControl size="small" sx={{ minWidth: 140 }}><Select displayEmpty value={branchFilter} onChange={event => changeBranch(event.target.value)} inputProps={{ 'aria-label': 'Filter by branch' }} renderValue={value => value ? branches.find(branch => String(branch.id) === String(value))?.name || 'Branch' : 'All Branches'}><MenuItem value="">All Branches</MenuItem>{branches.map(branch => <MenuItem key={branch.id} value={String(branch.id)}>{branch.name}</MenuItem>)}</Select></FormControl>
              <FormControl size="small" sx={{ minWidth: 160 }}><Select displayEmpty value={departmentFilter} onChange={event => changeDepartment(event.target.value)} inputProps={{ 'aria-label': 'Filter by department' }} renderValue={value => value ? departments.find(item => String(item.id) === String(value))?.name || 'Department' : 'All Departments'}><MenuItem value="">All Departments</MenuItem>{departments.map(item => <MenuItem key={item.id} value={String(item.id)}>{item.name}</MenuItem>)}</Select></FormControl>
              <FormControl size="small" sx={{ minWidth: 140 }}><Select value={statusFilter} onChange={event => changeStatus(event.target.value)} inputProps={{ 'aria-label': 'Filter by status' }}>{[['ALL', 'All Status'], ['ENROLLED', 'Enrolled'], ['NOT_ENROLLED', 'Not Enrolled'], ['PENDING', 'Pending'], ['FAILED', 'Failed']].map(([value, label]) => <MenuItem key={value} value={value}>{label}</MenuItem>)}</Select></FormControl>
            </Stack>
          </Stack>
        </Box>
      </Card>

      <Paper variant="outlined" sx={{ overflow: 'hidden', minWidth: 0, maxWidth: '100%' }}>
        {loading && employees.length === 0 ? (
          <LoadingState label="Loading employees…" />
        ) : filteredEmployees.length === 0 ? (
          <EmptyState compact={false} title="No matching employees" description="Try a different search or clear the filters." />
        ) : (
          <>
            <TableContainer sx={{ border: 0, borderRadius: 0, maxHeight: 'max(calc(100vh - 300px), 448px)', '& .MuiTableHead-root .MuiTableCell-head': { position: 'sticky', top: 0, zIndex: 2 } }}>
              <Table aria-label="Employee fingerprint directory" size="small" sx={{ minWidth: 800, tableLayout: 'fixed' }}>
                <colgroup>
                  <col style={{ width: '20%' }} /><col style={{ width: '14%' }} /><col style={{ width: '20%' }} /><col style={{ width: '20%' }} /><col style={{ width: '10%' }} /><col style={{ width: '16%' }} />
                </colgroup>
                <TableHead>
                  <TableRow>
                    <TableCell sx={headCellSx}>Employee</TableCell>
                    <TableCell sx={headCellSx}>Employee ID</TableCell>
                    <TableCell sx={headCellSx}>Branch</TableCell>
                    <TableCell sx={headCellSx}>Department</TableCell>
                    <TableCell sx={headCellSx}>Fingers</TableCell>
                    <TableCell sx={headCellSx}>Status</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {pageEmployees.map(employee => {
                    const state = enrollmentStatus(employee)
                    const branchId = employee.branch_id ?? (typeof employee.branch === 'object' ? employee.branch?.id : employee.branch)
                    const departmentId = employee.department_id ?? (typeof employee.department === 'object' ? employee.department?.id : employee.department)
                    const department = employee.department_name || (typeof employee.department === 'object' ? employee.department?.name : departments.find(item => String(item.id) === String(departmentId))?.name)
                    const branch = branches.find(item => String(item.id) === String(branchId))
                    const count = Number(employee.fingerprint_enrollment?.fingerprint_count || 0)
                    const person = employee.name || employee.employee_code || 'Employee'
                    return <TableRow key={employee.id} hover onClick={() => openEmployeeEnrollment(employee)} sx={{ height: 64, cursor: 'pointer', '& td': { py: 1.25, px: 1.5, fontSize: '0.875rem', verticalAlign: 'middle', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' } }}>
                      <TableCell><Typography variant="body2" sx={{ fontWeight: 600, color: 'text.primary', lineHeight: 1.35 }} noWrap>{person}</Typography></TableCell>
                      <TableCell>{employee.employee_code || employee.id}</TableCell>
                      <TableCell>{branch?.name || employee.fingerprint_enrollment?.branch_name || '—'}</TableCell>
                      <TableCell>{department || employee.fingerprint_enrollment?.department_name || '—'}</TableCell>
                      <TableCell>{count} / 2</TableCell>
                      <TableCell><DirectoryStatusBadge status={state} /></TableCell>
                    </TableRow>
                  })}
                </TableBody>
              </Table>
            </TableContainer>
            <TablePagination
              component="div"
              count={filteredEmployees.length}
              page={safePage - 1}
              onPageChange={(_event, next) => setPage(next + 1)}
              rowsPerPage={rowsPerPage}
              onRowsPerPageChange={event => { setRowsPerPage(Number(event.target.value)); setPage(1) }}
              rowsPerPageOptions={ROWS_PER_PAGE_OPTIONS}
              labelRowsPerPage="Rows"
              sx={{ borderTop: '1px solid', borderColor: 'divider', '& .MuiTablePagination-toolbar': { minHeight: 52, alignItems: 'center' }, '& .MuiTablePagination-selectLabel, & .MuiTablePagination-displayedRows': { m: 0 } }}
              slotProps={{ select: { inputProps: { 'aria-label': 'Rows per page' } } }}
            />
          </>
        )}
      </Paper>
    </> : !selectedEmployee ? <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: { md: 'calc(100vh - 220px)' } }}>
      <Paper variant="outlined" sx={{ p: 3, borderRadius: 2, width: '100%', maxWidth: CARD_MAX_WIDTH }}><Button startIcon={<ArrowLeft size={16} />} onClick={goBack}>Employee Directory</Button><Typography color="text.secondary" sx={{ mt: 2 }}>Employee details are no longer available in the current list.</Typography></Paper>
    </Box> : <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: { md: 'calc(100vh - 220px)' } }}>
      <Stack spacing={1.25} sx={{ width: '100%', maxWidth: CARD_MAX_WIDTH }}>
        <Box><Button size="small" variant="outlined" startIcon={<ArrowLeft size={16} />} onClick={goBack}>Employee Directory</Button></Box>

        <Paper variant="outlined" sx={{ borderRadius: 2, overflow: 'hidden' }}>
          {renderEmployeeCard(false)}
        </Paper>
      </Stack>
    </Box>}

    <Dialog
      open={enrollOpen && Boolean(selectedEmployee)}
      onClose={() => { if (!modalScanning && !starting) void handleCancelEnrollment() }}
      aria-label={ENROLL_DIALOG_LAYOUT === 'card' ? 'Selected Employee' : 'Employee Biometric Details'}
      sx={{ '& .MuiDialog-paper': { width: `min(calc(100% - 32px), ${ENROLL_DIALOG_LAYOUT === 'card' ? CARD_MAX_WIDTH : MODAL_WIDTH}px)`, maxWidth: `${ENROLL_DIALOG_LAYOUT === 'card' ? CARD_MAX_WIDTH : MODAL_WIDTH}px`, m: 2, borderRadius: 2, overflow: 'hidden', boxShadow: 6 } }}
    >
      {selectedEmployee ? (ENROLL_DIALOG_LAYOUT === 'card' ? renderEmployeeCard(true) : renderEmployeeModal()) : null}
    </Dialog>

    <Dialog open={historyOpen} onClose={() => setHistoryOpen(false)} fullWidth maxWidth="md">
      <DialogTitle>Fingerprint Enrollment History · {selectedEmployee?.name || selectedEmployee?.employee_code}</DialogTitle>
      <DialogContent dividers>
        {historyLoading ? <Box sx={{ display: 'grid', placeItems: 'center', py: 4 }}><CircularProgress size={26} /></Box>
          : history.length ? <Table size="small"><TableHead><TableRow><TableCell>Started</TableCell><TableCell>Finger</TableCell><TableCell>Device</TableCell><TableCell>Status</TableCell><TableCell>Slot</TableCell><TableCell>Details</TableCell></TableRow></TableHead><TableBody>{history.map(item => <TableRow key={item.enrollment_id}><TableCell>{item.created_at ? new Date(item.created_at).toLocaleString() : '—'}</TableCell><TableCell>{item.finger?.replaceAll('_', ' ') || '—'}</TableCell><TableCell>{item.device_id || '—'}</TableCell><TableCell><Typography variant="body2" fontWeight={650}>{item.status}</Typography></TableCell><TableCell>{item.fingerprint_slot ?? '—'}</TableCell><TableCell>{item.failure_reason || (item.completed_at ? new Date(item.completed_at).toLocaleString() : '—')}</TableCell></TableRow>)}</TableBody></Table>
            : <Typography color="text.secondary" sx={{ py: 3, textAlign: 'center' }}>No enrollment history is available for this employee.</Typography>}
      </DialogContent>
      <DialogActions><Button onClick={() => setHistoryOpen(false)}>Close</Button></DialogActions>
    </Dialog>
  </Box>
}
