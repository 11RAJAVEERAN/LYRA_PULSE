import { useEffect, useRef, useState } from 'react'
import { Alert, Box, Button, Chip, CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle, InputAdornment, MenuItem, Paper, Stack, Switch, Table, TableBody, TableCell, TableHead, TableRow, TextField, Typography } from '@mui/material'
import { BadgeCheck, CircleAlert, Fingerprint, Timer } from 'lucide-react'
import apiClient, { BRANCH_CONTEXT_EVENT } from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data
const enrollmentErrorMessage = (error, fallback) => {
  const data = error?.response?.data
  if (typeof data?.message === 'string' && data.message.trim()) return data.message
  if (typeof data?.detail === 'string' && data.detail.trim()) return data.detail
  const errors = data?.errors
  if (typeof errors === 'string') return errors
  if (Array.isArray(errors)) return errors.map(String).join(' ')
  if (errors && typeof errors === 'object') {
    const messages = Object.values(errors).flatMap(value => Array.isArray(value) ? value : [value]).filter(value => typeof value === 'string')
    if (messages.length) return messages.join(' ')
  }
  return error?.message || fallback
}
const readOneTimeToken = (data, field) => {
  const value = data?.[field]
  if (typeof value !== 'string' || value.trim() === '') {
    throw new Error(`The backend response did not include ${field}. The token may have rotated; rotate it again and copy the new token.`)
  }
  return value
}

const enrollmentStatus = employee => employee?.fingerprint_enrollment?.status || 'NOT_ENROLLED'
const statusLabels = { ENROLLED: 'Enrolled', NOT_ENROLLED: 'Not Enrolled', PENDING: 'Pending', FAILED: 'Failed' }
const StatusBadge = ({ status }) => {
  const palette = { ENROLLED: 'success', NOT_ENROLLED: 'default', PENDING: 'warning', FAILED: 'error' }
  const Icon = { ENROLLED: BadgeCheck, NOT_ENROLLED: Fingerprint, PENDING: Timer, FAILED: CircleAlert }[status] || Fingerprint
  return <Chip size="small" color={palette[status] || 'default'} icon={<Icon size={14} aria-hidden="true" />} label={statusLabels[status] || 'Not Enrolled'} sx={{ height: 24, fontWeight: 650, '& .MuiChip-icon': { ml: 0.75 } }} />
}
const FingerprintMark = ({ status }) => <Box component="span" sx={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', width: 32, height: 32, flex: '0 0 32px', borderRadius: 1.5, color: status === 'ENROLLED' ? 'primary.main' : status === 'FAILED' ? 'error.main' : status === 'PENDING' ? 'warning.dark' : 'text.disabled', bgcolor: 'action.hover' }} aria-hidden="true"><Fingerprint size={19} strokeWidth={1.8} /></Box>

export function DevicesPage() {
  const [devices, setDevices] = useState([])
  const [branches, setBranches] = useState([])
  const [employees, setEmployees] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [form, setForm] = useState({ device_id: '', name: '', branch_id: '', replace_device_id: '' })
  const [employeeId, setEmployeeId] = useState('')
  const [deviceId, setDeviceId] = useState('')
  const [enrollmentStep, setEnrollmentStep] = useState(0)
  const [firstFingerSlot, setFirstFingerSlot] = useState(null)
  const [secondStartFailed, setSecondStartFailed] = useState(false)
  const [token, setToken] = useState('')
  const [tokenInfo, setTokenInfo] = useState(null)
  const [showToken, setShowToken] = useState(true)
  const [copied, setCopied] = useState(false)
  const [rotationTarget, setRotationTarget] = useState(null)
  const [rotatingDeviceId, setRotatingDeviceId] = useState('')
  const [rotationError, setRotationError] = useState('')
  const [provisioning, setProvisioning] = useState(false)
  const [notice, setNotice] = useState('')
  const [enrollment, setEnrollment] = useState(null)
  const [diagnosticDevice, setDiagnosticDevice] = useState(null)
  const [diagnostics, setDiagnostics] = useState([])
  const [diagnosticsLoading, setDiagnosticsLoading] = useState(false)
  const provisionLock = useRef(false)
  const rotationLock = useRef(false)
  const secondFingerStarted = useRef(false)

  const reload = async (silent = false) => {
    if (!silent) setLoading(true)
    setError('')
    try {
      const [deviceRes, branchRes, employeeRes] = await Promise.all([
        apiClient.get('/devices/'), apiClient.get('/branches/'), apiClient.get('/employees/'),
      ])
      setDevices(unwrap(deviceRes) || [])
      setBranches(unwrap(branchRes) || [])
      setEmployees(unwrap(employeeRes) || [])
    } catch (e) { setError(e?.response?.data?.message || 'Unable to load devices. Check your role and branch access.') }
    finally { if (!silent) setLoading(false) }
  }
  useEffect(() => {
    if (enrollment?.status === 'SUCCESS' && enrollment.finger === 'first_finger' && !secondFingerStarted.current) {
      secondFingerStarted.current = true
      setSecondStartFailed(false)
      setFirstFingerSlot(enrollment.fingerprint_slot)
      apiClient.post(`/fingerprints/employees/${enrollment.employee_id}/enrollments/`, {
        device_id: enrollment.device_id,
        finger: 'second_finger',
      }).then(response => {
        const data = unwrap(response)
        setEnrollment(data)
        setEnrollmentStep(2)
        if (['SUCCESS', 'FAILED', 'EXPIRED', 'CANCELLED'].includes(data.status)) void reload(true)
      }).catch(e => {
        setSecondStartFailed(true)
        setError(enrollmentErrorMessage(e, 'First finger is saved, but the second enrollment could not be started. Retry it from this dialog.'))
      })
    }
  }, [enrollment?.status, enrollment?.finger, enrollment?.employee_id, enrollment?.device_id])

  useEffect(() => {
    void reload()
    const timer = setInterval(() => { void reload(true) }, 15000)
    return () => clearInterval(timer)
  }, [])
  useEffect(() => {
    window.addEventListener(BRANCH_CONTEXT_EVENT, reload)
    return () => window.removeEventListener(BRANCH_CONTEXT_EVENT, reload)
  }, [])

  useEffect(() => {
    if (!enrollment || ['SUCCESS', 'FAILED', 'EXPIRED', 'CANCELLED'].includes(enrollment.status)) return undefined
    const timer = setInterval(async () => {
      try {
        const response = await apiClient.get(`/fingerprints/employees/${enrollment.employee_id}/enrollments/${enrollment.enrollment_id}/`)
        const data = unwrap(response)
        setEnrollment(data)
        if (['SUCCESS', 'FAILED', 'EXPIRED', 'CANCELLED'].includes(data.status)) void reload(true)
      } catch (e) { setError(e?.response?.data?.message || 'Unable to refresh enrollment status.') }
    }, 2500)
    return () => clearInterval(timer)
  }, [enrollment?.enrollment_id, enrollment?.employee_id, enrollment?.status])

  const provision = async (event) => {
    event.preventDefault()
    if (provisionLock.current) return
    provisionLock.current = true
    setProvisioning(true); setError(''); setNotice('')
    try {
      const selectedBranchDevice = devices.find(d => String(d.branch_id) === String(form.branch_id) && d.is_active)
      if (selectedBranchDevice && form.replace_device_id !== selectedBranchDevice.device_id) {
        throw new Error('Select the current active device to confirm replacement.')
      }
      const payload = { ...form }
      if (!payload.replace_device_id) delete payload.replace_device_id
      const response = await apiClient.post('/devices/', payload)
      const data = unwrap(response)
      setToken(readOneTimeToken(data, 'provisioning_token'))
      setTokenInfo({ kind: 'provision', device_id: data.device_id || form.device_id, name: data.name || form.name })
      setShowToken(true)
      setCopied(false)
      setForm({ device_id: '', name: '', branch_id: '', replace_device_id: '' })
      setNotice('Device provisioned. Copy the one-time token into secure device configuration.')
      await reload()
    } catch (e) { setError(e?.response?.data?.message || e?.message || 'Device provisioning failed.') }
    finally { provisionLock.current = false; setProvisioning(false) }
  }
  const toggle = async (device) => {
    try {
      await apiClient.patch('/devices/', { device_id: device.device_id, is_active: !device.is_active })
      await reload()
    } catch (e) { setError(e?.response?.data?.message || 'Device update failed.') }
  }
  const rotateToken = async () => {
    if (!rotationTarget || rotationLock.current) return
    const device = rotationTarget
    rotationLock.current = true
    setError(''); setRotationError(''); setNotice(''); setRotatingDeviceId(device.device_id)
    try {
      const response = await apiClient.post(`/devices/${encodeURIComponent(device.device_id)}/rotate-token/`)
      const data = unwrap(response)
      const rotatedToken = readOneTimeToken(data, 'rotated_token')
      setToken(rotatedToken)
      setTokenInfo({ kind: 'rotation', device_id: data.device_id || device.device_id, name: data.name || device.name })
      setShowToken(true)
      setCopied(false)
      setRotationTarget(null)
      setNotice('Device token rotated. The previous token is no longer valid.')
      void reload()
    } catch (e) {
      const message = e?.response?.data?.message || e?.message || 'Device token rotation failed.'
      setRotationError(message)
      setError(message)
    }
    finally { rotationLock.current = false; setRotatingDeviceId('') }
  }
  const closeToken = () => {
    setToken('')
    setTokenInfo(null)
    setShowToken(true)
    setCopied(false)
  }
  const copyToken = async () => {
    if (!token) return
    try {
      await navigator.clipboard.writeText(token)
      setCopied(true)
    } catch {
      setError('Unable to copy the token. Select and copy it manually before closing this dialog.')
    }
  }
  const currentFingerIndex = enrollment?.finger === 'second_finger' ? 2 : 1
  const currentFingerScans = enrollment?.status === 'WAITING_FOR_SECOND_SCAN' ? 1
    : ['PROCESSING', 'SUCCESS'].includes(enrollment?.status) ? 2 : 0
  const completedScans = (currentFingerIndex === 2 ? 2 : 0) + currentFingerScans
  const selectedEmployee = employees.find(item => String(item.id) === String(employeeId))
  const selectedStatus = enrollmentStatus(selectedEmployee)
  const enroll = async (event) => {
    event.preventDefault(); setError(''); setNotice('')
    try {
      const employee = employees.find(item => String(item.id) === String(employeeId))
      if (!employee) throw new Error('Select a valid employee before starting fingerprint enrollment.')
      if (['ENROLLED', 'PENDING'].includes(enrollmentStatus(employee))) throw new Error(enrollmentStatus(employee) === 'ENROLLED' ? 'This employee is already enrolled.' : 'This employee already has an enrollment in progress.')
      // EmployeeSerializer returns the FK as `branch`; the devices endpoint
      // returns the matching value as `branch_id`.
      const employeeBranchId = employee.branch_id ?? (typeof employee.branch === 'object' ? employee.branch?.id : employee.branch)
      if (employeeBranchId == null) throw new Error('The selected employee has no branch assigned.')
      const available = devices.filter(item => item.is_active && item.status === 'Online' && String(item.branch_id) === String(employeeBranchId))
      if (available.length !== 1) throw new Error(available.length ? 'More than one online device is assigned to this employee branch.' : 'No online fingerprint device is available at the employee branch.')
      secondFingerStarted.current = false
      setFirstFingerSlot(null)
      setSecondStartFailed(false)
      setEnrollmentStep(1)
      setDeviceId(available[0].device_id)
      const response = await apiClient.post(`/fingerprints/employees/${employee.id}/enrollments/`, { device_id: available[0].device_id, finger: 'first_finger' })
      const data = unwrap(response)
      setEnrollment(data)
      setNotice('Enrollment started. Complete two captures for each of two different fingers at the device.')
      if (['SUCCESS', 'FAILED', 'EXPIRED', 'CANCELLED'].includes(data.status)) void reload(true)
    } catch (e) { setError(enrollmentErrorMessage(e, 'Fingerprint enrollment could not be started.')); void reload(true) }
  }
  const viewDiagnostics = async (device) => {
    setDiagnosticDevice(device); setDiagnostics([]); setDiagnosticsLoading(true)
    try {
      const response = await apiClient.get(`/devices/${encodeURIComponent(device.device_id)}/diagnostics/?limit=50`)
      setDiagnostics(unwrap(response) || [])
    } catch (e) { setError(e?.response?.data?.message || 'Unable to load device diagnostics.') }
    finally { setDiagnosticsLoading(false) }
  }

  return <Box sx={{ p: { xs: 2, md: 3 }, display: 'grid', gap: 2 }}>
    <Box><Typography variant="h4">Fingerprint Devices</Typography><Typography color="text.secondary">Provision devices, manage branch association, and start fingerprint enrollment.</Typography></Box>
    {error ? <Alert severity="error">{error}</Alert> : null}{notice ? <Alert severity="info">{notice}</Alert> : null}
    {enrollment ? <Alert severity={enrollment.status === 'SUCCESS' ? 'success' : ['FAILED', 'EXPIRED', 'CANCELLED'].includes(enrollment.status) ? 'warning' : 'info'}>Enrollment {enrollment.enrollment_id}: {enrollment.status}{enrollment.fingerprint_slot != null ? ` · slot ${enrollment.fingerprint_slot}` : ''}</Alert> : null}
    <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', lg: 'minmax(0, 1.55fr) minmax(330px, 1fr)' }, gap: 2, alignItems: 'stretch' }}>
    <Paper component="form" onSubmit={provision} sx={{ p: { xs: 1.75, md: 2.25 }, border: '1px solid', borderColor: 'divider', borderRadius: 2, minWidth: 0 }}>
      <Typography variant="h6" sx={{ mb: 1.5, fontWeight: 700 }}>Provision Device</Typography>
      <Stack direction={{ xs: 'column', md: 'row' }} gap={1.25} alignItems="stretch">
        <TextField label="Device ID" required fullWidth disabled={provisioning} value={form.device_id} onChange={e => setForm({ ...form, device_id: e.target.value })} />
        <TextField label="Name" fullWidth disabled={provisioning} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} />
        <TextField select label="Branch" required fullWidth disabled={provisioning} value={form.branch_id} onChange={e => setForm({ ...form, branch_id: e.target.value, replace_device_id: '' })} sx={{ minWidth: { md: 155 } }}>
          {branches.map(b => <MenuItem key={b.id} value={b.id}>{b.name}</MenuItem>)}
        </TextField>
        {devices.some(d => String(d.branch_id) === String(form.branch_id) && d.is_active) ? <TextField select label="Replace active device" required fullWidth disabled={provisioning} value={form.replace_device_id} onChange={e => setForm({ ...form, replace_device_id: e.target.value })} sx={{ minWidth: { md: 180 } }}>
          <MenuItem value="">Select current device</MenuItem>
          {devices.filter(d => String(d.branch_id) === String(form.branch_id) && d.is_active).map(d => <MenuItem key={d.device_id} value={d.device_id}>{d.name || d.device_id}</MenuItem>)}
        </TextField> : null}
        <Button type="submit" variant="contained" disabled={provisioning} sx={{ minWidth: 118, minHeight: 56, whiteSpace: 'nowrap' }}>{provisioning ? <CircularProgress size={18} color="inherit" /> : 'Provision'}</Button>
      </Stack>
    </Paper>
    <Paper component="form" onSubmit={enroll} sx={{ p: { xs: 1.75, md: 2.25 }, border: '1px solid', borderColor: 'divider', borderRadius: 2, minWidth: 0 }}>
      <Typography variant="h6" sx={{ mb: 1.5, fontWeight: 700 }}>Enroll Fingerprint</Typography>
      <Stack direction={{ xs: 'column', sm: 'row' }} gap={1.25} alignItems="stretch">
        <TextField select fullWidth required label="Employee" value={employeeId} onChange={e => setEmployeeId(e.target.value)} SelectProps={{
          MenuProps: { PaperProps: { sx: { maxHeight: 360, width: { xs: 'min(360px, calc(100vw - 24px))', sm: 380 }, maxWidth: 'calc(100vw - 24px)', mt: 0.5, border: '1px solid', borderColor: 'divider', boxShadow: 6 } } },
          renderValue: value => {
            const employee = employees.find(item => String(item.id) === String(value))
            if (!employee) return 'Select employee'
            const state = enrollmentStatus(employee)
            return <Stack direction="row" alignItems="center" spacing={1}><FingerprintMark status={state} /><Box sx={{ minWidth: 0, flex: 1 }}><Typography noWrap variant="body2" fontWeight={650}>{employee.name || employee.employee_code}</Typography><Typography noWrap variant="caption" color="text.secondary">{employee.employee_code}</Typography></Box><StatusBadge status={state} /></Stack>
          },
        }} sx={{ '& .MuiSelect-select': { display: 'flex', alignItems: 'center', minHeight: '56px !important', boxSizing: 'border-box' } }}>
          {employees.map(employee => {
            const state = enrollmentStatus(employee)
            return <MenuItem key={employee.id} value={employee.id} selected={String(employee.id) === String(employeeId)} sx={{ display: 'flex', gap: 1.25, minHeight: 56, py: 0.75, '&.Mui-selected': { bgcolor: 'action.selected' }, '&.Mui-selected:hover': { bgcolor: 'action.hover' } }}>
              <FingerprintMark status={state} />
              <Box sx={{ flex: 1, minWidth: 0 }}><Typography noWrap variant="body2" fontWeight={600}>{employee.name || employee.employee_code}</Typography><Typography noWrap variant="caption" color="text.secondary">{employee.employee_code}</Typography></Box>
              <StatusBadge status={state} />
            </MenuItem>
          })}
        </TextField>
        <Button type="submit" variant="contained" disabled={!selectedEmployee || ['ENROLLED', 'PENDING'].includes(selectedStatus) || Boolean(enrollment && !['SUCCESS','FAILED','EXPIRED','CANCELLED'].includes(enrollment.status))} sx={{ minWidth: 180, minHeight: 56, whiteSpace: 'nowrap' }}>
          {selectedStatus === 'ENROLLED' ? 'Already Enrolled' : selectedStatus === 'PENDING' ? 'Enrollment in Progress' : selectedStatus === 'FAILED' ? 'Retry Enrollment' : 'Start Enrollment'}
        </Button>
      </Stack>
      {selectedEmployee ? <Paper variant="outlined" sx={{ mt: 1.5, p: 1.5, borderRadius: 1.5, bgcolor: 'background.default' }}>
        <Stack direction="row" alignItems="center" spacing={1.25} sx={{ minWidth: 0 }}>
          <FingerprintMark status={selectedStatus} />
          <Box sx={{ flex: 1, minWidth: 0 }}><Typography variant="body2" fontWeight={700} noWrap>{selectedEmployee.name || selectedEmployee.employee_code}</Typography><Typography variant="caption" color="text.secondary" noWrap>{selectedEmployee.employee_code} · {selectedEmployee.fingerprint_enrollment?.branch_name || selectedEmployee.branch_name || 'Branch unavailable'}{selectedEmployee.fingerprint_enrollment?.department_name ? ' · ' + selectedEmployee.fingerprint_enrollment.department_name : ''}</Typography></Box>
          <StatusBadge status={selectedStatus} />
        </Stack>
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'repeat(3, minmax(0, 1fr))' }, gap: 1, mt: 1.5, pt: 1.25, borderTop: '1px solid', borderColor: 'divider' }}>
          <Box><Typography variant="caption" color="text.secondary">Registered fingerprints</Typography><Typography variant="body2" fontWeight={650}>{selectedEmployee.fingerprint_enrollment?.fingerprint_count ?? '—'}</Typography></Box>
          <Box><Typography variant="caption" color="text.secondary">Last enrolled</Typography><Typography variant="body2" fontWeight={650}>{selectedEmployee.fingerprint_enrollment?.last_enrolled ? new Date(selectedEmployee.fingerprint_enrollment.last_enrolled).toLocaleDateString() : '—'}</Typography></Box>
          <Box><Typography variant="caption" color="text.secondary">Device</Typography><Typography variant="body2" fontWeight={650} noWrap title={selectedEmployee.fingerprint_enrollment?.device_id || ''}>{selectedEmployee.fingerprint_enrollment?.device_id || '—'}</Typography></Box>
        </Box>
        {selectedStatus === 'PENDING' ? <Typography variant="caption" color="warning.dark" display="block" sx={{ mt: 1 }}>An enrollment is already in progress for this employee.</Typography> : null}
        {selectedStatus === 'FAILED' && selectedEmployee.fingerprint_enrollment?.failure_reason ? <Typography variant="caption" color="error.main" display="block" sx={{ mt: 1 }}>Last attempt failed: {selectedEmployee.fingerprint_enrollment.failure_reason}</Typography> : null}
        {selectedStatus === 'ENROLLED' ? <Typography variant="caption" color="success.dark" display="block" sx={{ mt: 1 }}>This employee has an active fingerprint enrollment. A new enrollment cannot be started.</Typography> : null}
      </Paper> : <Typography variant="body2" color="text.secondary" sx={{ mt: 1.5 }}>Select an employee to see the backend enrollment status and details.</Typography>}
    </Paper>
    </Box>
    <Paper sx={{ p: 2 }}>
      <Typography variant="h6" sx={{ mb: 1 }}>Registered devices</Typography>
      {loading ? <CircularProgress size={24} /> : <Table size="small" sx={{ '& .MuiTableBody-root .MuiTableRow-root': { height: 64, '& > .MuiTableCell-root': { py: 1.25, px: 1.5, fontSize: '0.875rem', verticalAlign: 'middle', whiteSpace: 'nowrap' } } }}><TableHead><TableRow><TableCell>Device</TableCell><TableCell>Branch</TableCell><TableCell>Active</TableCell><TableCell>Connection</TableCell><TableCell>Health</TableCell><TableCell>Queue / Heap</TableCell><TableCell>Last seen</TableCell><TableCell>Actions</TableCell></TableRow></TableHead><TableBody>
        {devices.map(d => <TableRow key={d.device_id}><TableCell>{d.name || d.device_id}<Typography variant="caption" display="block">{d.device_id}</Typography></TableCell><TableCell>{d.branch_name}</TableCell><TableCell>{d.is_active ? 'Yes' : 'No'}</TableCell><TableCell>{d.status || 'Offline'}</TableCell><TableCell>{d.health_status || 'UNKNOWN'}{d.health_details?.sensor_ready === false ? ' · Sensor unavailable' : d.health_details?.sensor_ready === true ? ' · Sensor ready' : ''}</TableCell><TableCell>{d.health_details?.pending_events ?? '—'} pending · {d.health_details?.free_heap != null ? `${Math.round(d.health_details.free_heap / 1024)} KB` : '—'}</TableCell><TableCell>{d.last_seen ? new Date(d.last_seen).toLocaleString() : 'Never'}</TableCell><TableCell><Stack direction="row" alignItems="center"><Switch checked={d.is_active} onChange={() => toggle(d)} inputProps={{ 'aria-label': `Activate ${d.device_id}` }} /><Button size="small" onClick={() => viewDiagnostics(d)}>Logs</Button><Button size="small" disabled={Boolean(rotatingDeviceId)} onClick={() => setRotationTarget(d)}>{rotatingDeviceId === d.device_id ? <CircularProgress size={18} /> : 'Rotate token'}</Button></Stack></TableCell></TableRow>)}
      </TableBody></Table>}
    </Paper>
    <Dialog open={Boolean(diagnosticDevice)} onClose={() => setDiagnosticDevice(null)} fullWidth maxWidth="md">
      <DialogTitle>Device diagnostics · {diagnosticDevice?.name || diagnosticDevice?.device_id}</DialogTitle>
      <DialogContent dividers>
        {diagnosticsLoading ? <CircularProgress size={24} /> : diagnostics.length ? <Stack spacing={1}>{diagnostics.map(item => <Alert key={item.id} severity={item.severity === 'ERROR' ? 'error' : item.severity === 'WARNING' ? 'warning' : 'info'}>
          <strong>{item.code}</strong> · {item.subsystem} · {new Date(item.created_at).toLocaleString()}<br />{item.message || 'No additional detail'}{item.resolved_at ? ` · Resolved ${new Date(item.resolved_at).toLocaleString()}` : ' · Unresolved'}
        </Alert>)}</Stack> : <Typography color="text.secondary">No device diagnostics have been reported.</Typography>}
      </DialogContent>
      <DialogActions><Button onClick={() => viewDiagnostics(diagnosticDevice)} disabled={!diagnosticDevice || diagnosticsLoading}>Refresh</Button><Button onClick={() => setDiagnosticDevice(null)}>Close</Button></DialogActions>
    </Dialog>
    <Dialog open={Boolean(enrollment)} onClose={() => {}} fullWidth maxWidth="sm">
      <DialogTitle>Fingerprint Registration (Secure)</DialogTitle>
      <DialogContent dividers>
        <Stack spacing={2} alignItems="center" sx={{ py: 2 }}>
          <Typography variant="h6">{enrollment?.status === 'SUCCESS' && enrollment?.finger === 'second_finger' ? 'Fingerprint Registration Successful' : enrollment?.finger === 'second_finger' || enrollmentStep === 2 ? 'Scan your second fingerprint' : 'Scan your first fingerprint'}</Typography>
          <Box sx={{ width: 110, height: 110, borderRadius: '50%', bgcolor: 'primary.50', display: 'grid', placeItems: 'center', border: '1px solid', borderColor: 'primary.light' }} aria-hidden="true">
            <svg width="72" height="72" viewBox="0 0 72 72" fill="none">
              <path d="M36 8a28 28 0 1 0 28 28" stroke="currentColor" strokeWidth="2" opacity=".28" />
              <path d="M36 15a21 21 0 1 0 21 21" stroke="currentColor" strokeWidth="2" opacity=".45" />
              <path d="M36 22a14 14 0 1 0 14 14" stroke="currentColor" strokeWidth="2" opacity=".65" />
              <path d="M36 29a7 7 0 1 0 7 7M36 36c0 10-3 18-9 24M43 36c0 8-1 14-4 20M29 36c0 5-1 9-3 12" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" />
            </svg>
          </Box>
          <Typography color="text.secondary" textAlign="center">
            {enrollment?.status === 'WAITING_FOR_SECOND_SCAN'
              ? 'Remove your finger, then place the SAME finger again.'
              : enrollment?.status === 'PROCESSING'
                ? 'Checking and storing this finger. Keep the sensor clear.'
                : 'Place your finger on the sensor and lift it after successfully scanned. Use the same finger twice, then another finger.'}
          </Typography>
          <Box sx={{ display: 'flex', gap: 1 }} aria-label={`Capture progress ${completedScans} of 4`}>{[1,2,3,4].map(n => <Box key={n} sx={{ width: 14, height: 14, borderRadius: '50%', bgcolor: n <= completedScans ? 'primary.main' : 'grey.300', animation: n === completedScans + 1 && enrollment?.status !== 'SUCCESS' ? 'pulse 1.2s ease-in-out infinite' : 'none', '@keyframes pulse': { '50%': { opacity: 0.35 } } }} />)}</Box>
          <Alert severity={enrollment?.status === 'SUCCESS' && enrollment?.finger === 'second_finger' ? 'success' : ['FAILED','EXPIRED','CANCELLED'].includes(enrollment?.status) ? 'error' : 'info'} sx={{ width: '100%' }}>
            {enrollment?.status === 'SUCCESS' && enrollment?.finger === 'second_finger'
              ? `Employee: ${employees.find(item => String(item.id) === String(enrollment.employee_id))?.name || 'Employee'} · ID ${enrollment.employee_id}. First finger registered · slot ${firstFingerSlot ?? '—'}. Second finger registered · slot ${enrollment.fingerprint_slot}. Enrollment status: COMPLETED.`
              : `First finger: ${firstFingerSlot != null ? `Registered · slot ${firstFingerSlot}` : enrollment?.finger === 'first_finger' ? enrollment?.status : 'Registered'}. Second finger: ${enrollment?.finger === 'second_finger' ? enrollment?.status : 'Waiting'}.`}
          </Alert>
        </Stack>
      </DialogContent>
      <DialogActions>
        {secondStartFailed ? <Button onClick={async () => {
          try {
            const response = await apiClient.post(`/fingerprints/employees/${enrollment.employee_id}/enrollments/`, { device_id: enrollment.device_id, finger: 'second_finger' })
            setSecondStartFailed(false)
            setEnrollmentStep(2)
            const data = unwrap(response)
            setEnrollment(data)
            if (['SUCCESS', 'FAILED', 'EXPIRED', 'CANCELLED'].includes(data.status)) void reload(true)
          } catch (e) { setError(enrollmentErrorMessage(e, 'Second finger enrollment could not be started.')) }
        }}>Retry second finger</Button> : null}
        {!['SUCCESS','FAILED','EXPIRED','CANCELLED'].includes(enrollment?.status) ? <Button onClick={async () => { try { await apiClient.delete(`/fingerprints/employees/${enrollment.employee_id}/enrollments/${enrollment.enrollment_id}/`); setEnrollment(null); setEnrollmentStep(0) } catch (e) { setError(e?.response?.data?.message || 'Cancellation failed.') } }}>Cancel</Button> : null}
        {['FAILED','EXPIRED','CANCELLED'].includes(enrollment?.status) ? <Button onClick={async () => {
          try {
            const nextFinger = enrollment.finger || 'first_finger'
            const response = await apiClient.post(`/fingerprints/employees/${enrollment.employee_id}/enrollments/`, { device_id: enrollment.device_id, finger: nextFinger })
            secondFingerStarted.current = nextFinger === 'second_finger'
            const data = unwrap(response)
            setEnrollment(data)
            if (['SUCCESS', 'FAILED', 'EXPIRED', 'CANCELLED'].includes(data.status)) void reload(true)
          } catch (e) { setError(enrollmentErrorMessage(e, 'Enrollment retry failed.')) }
        }}>Retry</Button> : null}
        {enrollment?.status === 'SUCCESS' && enrollment?.finger === 'second_finger' ? <Button variant="contained" onClick={() => { setEnrollment(null); setEnrollmentStep(0) }}>Done</Button> : null}
      </DialogActions>
    </Dialog>
    <Dialog open={Boolean(rotationTarget)} onClose={() => rotatingDeviceId ? null : setRotationTarget(null)} fullWidth maxWidth="sm">
      <DialogTitle>Rotate Device Token?</DialogTitle>
      <DialogContent>
        {rotationError ? <Alert severity="error" sx={{ mb: 2 }}>{rotationError}</Alert> : null}
        <Typography>Rotating this device token will immediately invalidate the current credential.</Typography>
        <Typography sx={{ mt: 1 }}>Update the ESP32 device&apos;s local <code>config_local.py</code> with the new token. Until that is done, the device cannot authenticate with the backend.</Typography>
      </DialogContent>
      <DialogActions>
        <Button disabled={Boolean(rotatingDeviceId)} onClick={() => { setRotationError(''); setRotationTarget(null) }}>Cancel</Button>
        <Button variant="contained" disabled={Boolean(rotatingDeviceId)} onClick={rotateToken}>{rotatingDeviceId ? <CircularProgress size={18} /> : 'Confirm Rotation'}</Button>
      </DialogActions>
    </Dialog>
    <Dialog open={Boolean(token)} onClose={() => {}} fullWidth maxWidth="sm" scroll="paper">
      <DialogTitle>{tokenInfo?.kind === 'rotation' ? 'New Device Token Generated' : 'Device Token Generated'}</DialogTitle>
      <DialogContent>
        <Typography sx={{ mb: 2 }}>
          {tokenInfo?.kind === 'rotation'
            ? 'Your new device authentication token has been generated successfully.'
            : 'Your device authentication token has been generated successfully. Copy and securely store it before closing this window. The original token cannot be retrieved again after this dialog is closed.'}
        </Typography>
        <Stack spacing={1.5} sx={{ mb: 2 }}>
          <TextField label="Device Name" fullWidth value={tokenInfo?.name || '—'} inputProps={{ readOnly: true }} />
          <TextField label="Device ID" fullWidth value={tokenInfo?.device_id || ''} inputProps={{ readOnly: true }} />
          <TextField
            label={tokenInfo?.kind === 'rotation' ? 'New Token' : 'Generated Token'}
            fullWidth multiline minRows={3} maxRows={8}
            value={showToken ? token : '•'.repeat(token.length)}
            inputProps={{ readOnly: true, 'aria-label': 'Device authentication token', style: { overflowWrap: 'anywhere', wordBreak: 'break-all', fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace' } }}
            InputProps={{ endAdornment: <InputAdornment position="end"><Button onClick={() => setShowToken(value => !value)}>{showToken ? 'Hide' : 'Show'}</Button></InputAdornment> }}
          />
        </Stack>
        <Alert severity="warning">
          {tokenInfo?.kind === 'rotation'
            ? 'The previous token is no longer valid. Update the ESP32 config_local.py with this new token.'
            : 'Copy this token and add it to the ESP32 config_local.py. The original token is shown only once.'}
        </Alert>
        {copied ? <Alert severity="success" sx={{ mt: 2 }}>Token copied successfully.</Alert> : null}
      </DialogContent>
      <DialogActions>
        <Button variant="contained" onClick={copyToken}>Copy Token</Button>
        <Button onClick={closeToken}>Close</Button>
      </DialogActions>
    </Dialog>
  </Box>
}
