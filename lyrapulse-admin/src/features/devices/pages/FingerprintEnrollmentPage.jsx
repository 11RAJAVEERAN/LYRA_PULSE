import { useEffect, useMemo, useRef, useState } from 'react'
import {
  Alert, Avatar, Box, Button, Chip, CircularProgress, Dialog, DialogActions, DialogContent,
  DialogTitle, FormControl, InputAdornment, LinearProgress, MenuItem, Paper, Select, Stack, Table,
  TableBody, TableCell, TableContainer, TableHead, TableRow, TextField, Tooltip, Typography,
} from '@mui/material'
import {
  ArrowLeft, BadgeCheck, Building2, CalendarClock, Check, CircleAlert, Clock3, Eye, Fingerprint, Info,
  Search, Trash2, User, Users,
} from 'lucide-react'
import apiClient, { BRANCH_CONTEXT_EVENT } from '../../../services/apiClient'

const unwrap = response => response.data?.data ?? response.data
const terminalStatuses = ['SUCCESS', 'FAILED', 'EXPIRED', 'CANCELLED']
const activeStatuses = ['PENDING', 'WAITING_FOR_FINGER', 'WAITING_FOR_SECOND_SCAN', 'PROCESSING']
const enrollmentStatus = employee => employee?.fingerprint_enrollment?.status || 'NOT_ENROLLED'
const statusLabel = { ENROLLED: 'Enrolled', NOT_ENROLLED: 'Not Enrolled', PENDING: 'Pending', FAILED: 'Failed' }
const statusColor = { ENROLLED: 'success', NOT_ENROLLED: 'default', PENDING: 'warning', FAILED: 'error' }
const CARD_MAX_WIDTH = 440
const MODAL_WIDTH = 440

const formatDateTime = value => {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return '—'
  return date.toLocaleString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false })
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
  const [page, setPage] = useState(1)
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
  const [autoStartId, setAutoStartId] = useState('')
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
    const matchesStatus = statusFilter === 'ALL' || enrollmentStatus(employee) === statusFilter
    return matchesSearch && matchesBranch && matchesStatus
  }), [employees, search, branchFilter, statusFilter])
  const pageSize = 7
  const pageCount = Math.max(1, Math.ceil(filteredEmployees.length / pageSize))
  const pageEmployees = filteredEmployees.slice((page - 1) * pageSize, page * pageSize)
  const firstVisiblePage = Math.max(1, Math.min(page - 2, pageCount - 4))
  const pageNumbers = Array.from({ length: Math.min(pageCount, 5) }, (_, index) => firstVisiblePage + index)
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
  const openEmployeeEnrollment = employee => {
    chooseEmployee(employee)
    setEnrollOpen(true)
    setAutoStartId(String(employee.id))
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

  const openEnrollment = () => {
    if (!selectedEmployee || starting || selectedStatus === 'ENROLLED') return
    setEnrollOpen(true)
    if (selectedStatus !== 'PENDING') void startEnrollment()
  }

  // Runs once the clicked employee is the selected one, so the existing startEnrollment sees the right employee.
  useEffect(() => {
    if (!autoStartId || !selectedEmployee || String(selectedEmployee.id) !== autoStartId) return
    setAutoStartId('')
    if (enrollOpen && selectedStatus !== 'PENDING') void startEnrollment()
  }, [autoStartId, selectedEmployee?.id])

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
            <StatusBadge status={selectedStatus} />
          </Box>

          <Stack direction="row" alignItems="center" spacing={1.5} sx={{ px: 2, pt: 1.75, pb: 1.25 }}>
            <Avatar sx={{ width: 52, height: 52, fontWeight: 700, bgcolor: 'primary.light', color: 'primary.dark' }}>{initials}</Avatar>
            <Box sx={{ flex: 1, minWidth: 0 }}>
              <Typography variant="subtitle1" fontWeight={750} noWrap>{employeeName}</Typography>
              <Typography variant="body2" color="text.secondary" noWrap>{selectedEmployee.employee_code || selectedEmployee.id} · {employeeDepartmentName} · {employeeBranchName}</Typography>
            </Box>
          </Stack>

          <Box sx={{ mx: 2, mb: 1.5, pt: 1.25, borderTop: '1px solid', borderColor: 'divider', display: 'grid', gridTemplateColumns: 'repeat(3, minmax(0, 1fr))', gap: 1 }}>
            {[[Building2, 'Branch', employeeBranchName], [Users, 'Department', employeeDepartmentName], [CalendarClock, 'Last Enrolled', formatDateTime(lastEnrolledAt)]].map(([Icon, label, value]) => <Stack key={label} direction="row" spacing={0.75} alignItems="flex-start" sx={{ minWidth: 0 }}>
              <Box sx={{ color: 'text.secondary', mt: 0.25, display: 'flex' }}><Icon size={14} aria-hidden="true" /></Box>
              <Box sx={{ minWidth: 0 }}>
                <Typography variant="caption" color="text.secondary" sx={{ display: 'block', lineHeight: 1.2 }}>{label}</Typography>
                <Typography variant="caption" fontWeight={700} sx={{ display: 'block', lineHeight: 1.3, overflowWrap: 'anywhere' }}>{value}</Typography>
              </Box>
            </Stack>)}
          </Box>

          <Box sx={{ px: 2, pb: 1.5, display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: 1 }}>
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

          {detailLoading ? <LinearProgress sx={{ mx: 2, mb: 1.25 }} /> : null}

          <Stack direction="row" spacing={0.75} sx={{ px: 2, pb: 1.75 }}>
            <Button variant="contained" size="small" startIcon={starting ? undefined : <Fingerprint size={15} />} disabled={starting || selectedStatus === 'ENROLLED' || (inModal ? (selectedStatus === 'PENDING' || modalScanning || !deviceForEmployee || deviceForEmployee.status !== 'Online') : (selectedStatus !== 'PENDING' && (!deviceForEmployee || deviceForEmployee.status !== 'Online')))} onClick={inModal ? startEnrollment : openEnrollment} sx={{ flex: '1.35 1 0', minWidth: 0, minHeight: 36, whiteSpace: 'nowrap', fontSize: 12.5, px: 1 }}>{starting ? <CircularProgress size={16} color="inherit" /> : selectedStatus === 'ENROLLED' ? 'Already Enrolled' : selectedStatus === 'PENDING' ? (inModal ? 'In Progress' : 'Resume Enrollment') : selectedStatus === 'FAILED' ? 'Retry Enrollment' : 'Start Enrollment'}</Button>
            <Button variant="outlined" size="small" startIcon={<Clock3 size={15} />} onClick={openHistory} disabled={historyLoading} sx={{ flex: '1 1 0', minWidth: 0, minHeight: 36, whiteSpace: 'nowrap', fontSize: 12.5, px: 1 }}>View History</Button>
            <Tooltip title="Fingerprint removal is unavailable because this system has no backend-to-device slot deletion workflow."><span style={{ flex: '0.9 1 0', minWidth: 0, display: 'flex' }}><Button fullWidth variant="outlined" color="error" size="small" startIcon={<Trash2 size={15} />} disabled sx={{ minHeight: 36, whiteSpace: 'nowrap', fontSize: 12.5, px: 1 }}>Remove</Button></span></Tooltip>
          </Stack>

          <Box sx={{ px: 2, pt: 1.5, pb: 1.75, borderTop: '1px solid', borderColor: 'divider' }}>
            <Stack direction="row" alignItems="center" spacing={0.9} sx={{ mb: 1.25 }}>
              <Fingerprint size={17} color="#2563eb" aria-hidden="true" />
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

  return <Box sx={{ p: { xs: 1.5, md: 2.5 }, maxWidth: 1500, mx: 'auto', width: '100%', minWidth: 0 }}>
    {error ? <Alert severity="error" onClose={() => setError('')} sx={{ mb: 1.5, ...(showCard ? { maxWidth: CARD_MAX_WIDTH, mx: 'auto' } : {}) }}>{error}</Alert> : null}
    {notice ? <Alert severity="info" onClose={() => setNotice('')} sx={{ mb: 1.5, ...(showCard ? { maxWidth: CARD_MAX_WIDTH, mx: 'auto' } : {}) }}>{notice}</Alert> : null}

    {!showCard ? <Paper variant="outlined" sx={{ borderRadius: 2, overflow: 'hidden' }}>
      <Box sx={{ p: { xs: 1.5, md: 2 }, display: 'flex', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between', gap: 1.25, borderBottom: '1px solid', borderColor: 'divider' }}>
        <Stack direction="row" alignItems="center" spacing={1}><Users size={21} color="#2563eb" /><Typography variant="h6" fontWeight={700}>Employee Directory</Typography></Stack>
        <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1} sx={{ width: { xs: '100%', sm: 'auto' } }}>
          <TextField size="small" placeholder="Search employee..." value={search} onChange={event => changeSearch(event.target.value)} sx={{ width: { xs: '100%', sm: 230 } }} InputProps={{ startAdornment: <InputAdornment position="start"><Search size={17} /></InputAdornment> }} />
          <FormControl size="small" sx={{ minWidth: 130 }}><Select displayEmpty value={branchFilter} onChange={event => changeBranch(event.target.value)} renderValue={value => value ? branches.find(branch => String(branch.id) === String(value))?.name || 'Branch' : 'All Branches'}><MenuItem value="">All Branches</MenuItem>{branches.map(branch => <MenuItem key={branch.id} value={String(branch.id)}>{branch.name}</MenuItem>)}</Select></FormControl>
          <FormControl size="small" sx={{ minWidth: 125 }}><Select value={statusFilter} onChange={event => changeStatus(event.target.value)}>{[['ALL', 'All Status'], ['ENROLLED', 'Enrolled'], ['NOT_ENROLLED', 'Not Enrolled'], ['PENDING', 'Pending'], ['FAILED', 'Failed']].map(([value, label]) => <MenuItem key={value} value={value}>{label}</MenuItem>)}</Select></FormControl>
        </Stack>
      </Box>
      <TableContainer sx={{ overflowX: 'auto' }}>
        <Table size="small" aria-label="Employee fingerprint directory">
          <TableHead><TableRow>{['Employee', 'ID', 'Branch', 'Department', 'Fingers', 'Status', 'Action'].map(label => <TableCell key={label} sx={{ py: 1.25, fontWeight: 700, whiteSpace: 'nowrap', bgcolor: 'grey.50' }}>{label}</TableCell>)}</TableRow></TableHead>
          <TableBody>
            {loading ? <TableRow><TableCell colSpan={7} align="center" sx={{ py: 4 }}><CircularProgress size={24} /></TableCell></TableRow>
              : pageEmployees.length ? pageEmployees.map(employee => {
                const state = enrollmentStatus(employee)
                const branchId = employee.branch_id ?? (typeof employee.branch === 'object' ? employee.branch?.id : employee.branch)
                const departmentId = employee.department_id ?? (typeof employee.department === 'object' ? employee.department?.id : employee.department)
                const department = employee.department_name || (typeof employee.department === 'object' ? employee.department?.name : departments.find(item => String(item.id) === String(departmentId))?.name)
                const branch = branches.find(item => String(item.id) === String(branchId))
                const count = Number(employee.fingerprint_enrollment?.fingerprint_count || 0)
                const person = employee.name || employee.employee_code || 'Employee'
                const avatarText = person.split(/\s+/).map(part => part[0]).join('').slice(0, 2).toUpperCase()
                return <TableRow key={employee.id} hover onClick={() => openEmployeeEnrollment(employee)} sx={{ cursor: 'pointer', '& > .MuiTableCell-root': { py: 1.15 } }}>
                  <TableCell><Stack direction="row" alignItems="center" spacing={1}><Avatar sx={{ width: 30, height: 30, fontSize: 12, fontWeight: 700, bgcolor: 'primary.light', color: 'primary.dark' }}>{avatarText}</Avatar><Typography variant="body2" fontWeight={650} noWrap>{person}</Typography></Stack></TableCell>
                  <TableCell sx={{ whiteSpace: 'nowrap' }}>{employee.employee_code || employee.id}</TableCell>
                  <TableCell sx={{ whiteSpace: 'nowrap' }}>{branch?.name || employee.fingerprint_enrollment?.branch_name || '—'}</TableCell>
                  <TableCell sx={{ whiteSpace: 'nowrap' }}>{department || employee.fingerprint_enrollment?.department_name || '—'}</TableCell>
                  <TableCell sx={{ whiteSpace: 'nowrap' }}>{count} / 2</TableCell>
                  <TableCell><StatusBadge status={state} /></TableCell>
                  <TableCell><Button size="small" variant="outlined" startIcon={<Eye size={15} />} onClick={event => { event.stopPropagation(); viewEmployee(employee) }}>View</Button></TableCell>
                </TableRow>
              }) : <TableRow><TableCell colSpan={7} align="center" sx={{ py: 4 }}><Typography variant="body2" color="text.secondary">No employees match these filters.</Typography></TableCell></TableRow>}
          </TableBody>
        </Table>
      </TableContainer>
      <Stack direction={{ xs: 'column', sm: 'row' }} alignItems="center" justifyContent="space-between" spacing={1} sx={{ px: 2, py: 1.25, borderTop: '1px solid', borderColor: 'divider' }}>
        <Typography variant="body2" color="text.secondary">Showing {filteredEmployees.length ? (page - 1) * pageSize + 1 : 0}–{Math.min(page * pageSize, filteredEmployees.length)} of {filteredEmployees.length} employees</Typography>
        <Stack direction="row" spacing={0.5} alignItems="center">
          <Button size="small" variant="outlined" disabled={page <= 1} onClick={() => setPage(value => Math.max(1, value - 1))} aria-label="Previous page">‹</Button>
          {pageNumbers.map(number => <Button key={number} size="small" variant={number === page ? 'contained' : 'outlined'} onClick={() => setPage(number)} aria-current={number === page ? 'page' : undefined}>{number}</Button>)}
          <Button size="small" variant="outlined" disabled={page >= pageCount} onClick={() => setPage(value => Math.min(pageCount, value + 1))} aria-label="Next page">›</Button>
        </Stack>
      </Stack>
    </Paper> : !selectedEmployee ? <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: { md: 'calc(100vh - 220px)' } }}>
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
      aria-label="Selected Employee"
      sx={{ '& .MuiDialog-paper': { width: `min(calc(100% - 32px), ${MODAL_WIDTH}px)`, maxWidth: `${MODAL_WIDTH}px`, m: 2, borderRadius: 2, overflow: 'hidden', boxShadow: 6 } }}
    >
      {error ? <Alert severity="error" sx={{ borderRadius: 0 }} action={secondStartFailed && enrollment ? <Button color="inherit" size="small" onClick={retrySecondFinger}>Retry second finger</Button> : null}>{error}</Alert> : null}
      {selectedEmployee ? renderEmployeeCard(true) : null}
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
