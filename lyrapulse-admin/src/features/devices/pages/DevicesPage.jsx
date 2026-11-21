import { useEffect, useRef, useState } from 'react'
import { Alert, Box, Button, CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle, InputAdornment, MenuItem, Paper, Stack, Switch, Table, TableBody, TableCell, TableHead, TableRow, TextField, Typography } from '@mui/material'
import apiClient, { BRANCH_CONTEXT_EVENT } from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data
const readOneTimeToken = (data, field) => {
  const value = data?.[field]
  if (typeof value !== 'string' || value.trim() === '') {
    throw new Error(`The backend response did not include ${field}. The token may have rotated; rotate it again and copy the new token.`)
  }
  return value
}

export function DevicesPage() {
  const [devices, setDevices] = useState([])
  const [branches, setBranches] = useState([])
  const [employees, setEmployees] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [form, setForm] = useState({ device_id: '', name: '', branch_id: '' })
  const [employeeId, setEmployeeId] = useState('')
  const [deviceId, setDeviceId] = useState('')
  const [finger, setFinger] = useState('right_index')
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
  const provisionLock = useRef(false)
  const rotationLock = useRef(false)

  const reload = async () => {
    setLoading(true); setError('')
    try {
      const [deviceRes, branchRes, employeeRes] = await Promise.all([
        apiClient.get('/devices/'), apiClient.get('/branches/'), apiClient.get('/employees/'),
      ])
      setDevices(unwrap(deviceRes) || [])
      setBranches(unwrap(branchRes) || [])
      setEmployees(unwrap(employeeRes) || [])
    } catch (e) { setError(e?.response?.data?.message || 'Unable to load devices. Check your role and branch access.') }
    finally { setLoading(false) }
  }
  useEffect(() => { reload() }, [])
  useEffect(() => {
    window.addEventListener(BRANCH_CONTEXT_EVENT, reload)
    return () => window.removeEventListener(BRANCH_CONTEXT_EVENT, reload)
  }, [])

  useEffect(() => {
    if (!enrollment || ['SUCCESS', 'FAILED', 'EXPIRED', 'CANCELLED'].includes(enrollment.status)) return undefined
    const timer = setInterval(async () => {
      try {
        const response = await apiClient.get(`/fingerprints/employees/${enrollment.employee_id}/enrollments/${enrollment.enrollment_id}/`)
        setEnrollment(unwrap(response))
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
      const response = await apiClient.post('/devices/', form)
      const data = unwrap(response)
      setToken(readOneTimeToken(data, 'provisioning_token'))
      setTokenInfo({ kind: 'provision', device_id: data.device_id || form.device_id, name: data.name || form.name })
      setShowToken(true)
      setCopied(false)
      setForm({ device_id: '', name: '', branch_id: '' })
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
  const enroll = async (event) => {
    event.preventDefault(); setError(''); setNotice('')
    try {
      const response = await apiClient.post(`/fingerprints/employees/${employeeId}/enrollments/`, { device_id: deviceId, finger })
      const data = unwrap(response)
      setEnrollment(data)
      setNotice(`Enrollment ${data.enrollment_id} started. Ask the employee to complete the two scans at the selected device.`)
    } catch (e) { setError(e?.response?.data?.message || 'Fingerprint enrollment could not be started. Confirm employee biometric permission and branch access.') }
  }

  return <Box sx={{ p: { xs: 2, md: 3 }, display: 'grid', gap: 2 }}>
    <Box><Typography variant="h4">Fingerprint Devices</Typography><Typography color="text.secondary">Provision devices, manage branch association, and start fingerprint enrollment.</Typography></Box>
    {error ? <Alert severity="error">{error}</Alert> : null}{notice ? <Alert severity="info">{notice}</Alert> : null}
    {enrollment ? <Alert severity={enrollment.status === 'SUCCESS' ? 'success' : ['FAILED', 'EXPIRED', 'CANCELLED'].includes(enrollment.status) ? 'warning' : 'info'}>Enrollment {enrollment.enrollment_id}: {enrollment.status}{enrollment.fingerprint_slot != null ? ` · slot ${enrollment.fingerprint_slot}` : ''}</Alert> : null}
    <Paper component="form" onSubmit={provision} sx={{ p: 2 }}>
      <Typography variant="h6" sx={{ mb: 1 }}>Provision device</Typography>
      <Stack direction={{ xs: 'column', md: 'row' }} gap={1.5}>
        <TextField label="Device ID" required disabled={provisioning} value={form.device_id} onChange={e => setForm({ ...form, device_id: e.target.value })} />
        <TextField label="Name" disabled={provisioning} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} />
        <TextField select label="Branch" required disabled={provisioning} value={form.branch_id} onChange={e => setForm({ ...form, branch_id: e.target.value })} sx={{ minWidth: 180 }}>
          {branches.map(b => <MenuItem key={b.id} value={b.id}>{b.name}</MenuItem>)}
        </TextField>
        <Button type="submit" variant="contained" disabled={provisioning}>{provisioning ? <CircularProgress size={18} color="inherit" /> : 'Provision'}</Button>
      </Stack>
    </Paper>
    <Paper sx={{ p: 2 }}>
      <Typography variant="h6" sx={{ mb: 1 }}>Registered devices</Typography>
      {loading ? <CircularProgress size={24} /> : <Table size="small" sx={{ '& .MuiTableBody-root .MuiTableRow-root': { height: 64, '& > .MuiTableCell-root': { py: 1.25, px: 1.5, fontSize: '0.875rem', verticalAlign: 'middle', whiteSpace: 'nowrap' } } }}><TableHead><TableRow><TableCell>Device</TableCell><TableCell>Branch</TableCell><TableCell>Active</TableCell><TableCell>Status</TableCell><TableCell>Last seen</TableCell><TableCell>Actions</TableCell></TableRow></TableHead><TableBody>
        {devices.map(d => <TableRow key={d.device_id}><TableCell>{d.name || d.device_id}<Typography variant="caption" display="block">{d.device_id}</Typography></TableCell><TableCell>{d.branch_name}</TableCell><TableCell>{d.is_active ? 'Yes' : 'No'}</TableCell><TableCell>{d.status || 'Offline'}</TableCell><TableCell>{d.last_seen ? new Date(d.last_seen).toLocaleString() : 'Never'}</TableCell><TableCell><Stack direction="row" alignItems="center"><Switch checked={d.is_active} onChange={() => toggle(d)} inputProps={{ 'aria-label': `Activate ${d.device_id}` }} /><Button size="small" disabled={Boolean(rotatingDeviceId)} onClick={() => setRotationTarget(d)}>{rotatingDeviceId === d.device_id ? <CircularProgress size={18} /> : 'Rotate token'}</Button></Stack></TableCell></TableRow>)}
      </TableBody></Table>}
    </Paper>
    <Paper component="form" onSubmit={enroll} sx={{ p: 2 }}>
      <Typography variant="h6" sx={{ mb: 1 }}>Enroll fingerprint</Typography>
      <Stack direction={{ xs: 'column', md: 'row' }} gap={1.5}>
        <TextField select label="Employee" required value={employeeId} onChange={e => setEmployeeId(e.target.value)} sx={{ minWidth: 220 }}>{employees.map(e => <MenuItem key={e.id} value={e.id}>{e.name || e.employee_code} · {e.employee_code}</MenuItem>)}</TextField>
        <TextField select label="Device" required value={deviceId} onChange={e => setDeviceId(e.target.value)} sx={{ minWidth: 180 }}>{devices.filter(d => d.is_active).map(d => <MenuItem key={d.device_id} value={d.device_id}>{d.name || d.device_id}</MenuItem>)}</TextField>
        <TextField select label="Finger" value={finger} onChange={e => setFinger(e.target.value)}>{['left_thumb','left_index','left_middle','left_ring','left_little','right_thumb','right_index','right_middle','right_ring','right_little'].map(v => <MenuItem key={v} value={v}>{v.replace('_',' ')}</MenuItem>)}</TextField>
        <Button type="submit" variant="contained">Start enrollment</Button>
      </Stack>
    </Paper>
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
