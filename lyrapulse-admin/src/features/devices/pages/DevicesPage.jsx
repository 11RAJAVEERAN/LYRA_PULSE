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
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [form, setForm] = useState({ device_id: '', name: '', branch_id: '', replace_device_id: '' })
  const [token, setToken] = useState('')
  const [tokenInfo, setTokenInfo] = useState(null)
  const [showToken, setShowToken] = useState(true)
  const [copied, setCopied] = useState(false)
  const [rotationTarget, setRotationTarget] = useState(null)
  const [rotatingDeviceId, setRotatingDeviceId] = useState('')
  const [rotationError, setRotationError] = useState('')
  const [provisioning, setProvisioning] = useState(false)
  const [notice, setNotice] = useState('')
  const [diagnosticDevice, setDiagnosticDevice] = useState(null)
  const [diagnostics, setDiagnostics] = useState([])
  const [diagnosticsLoading, setDiagnosticsLoading] = useState(false)
  const provisionLock = useRef(false)
  const rotationLock = useRef(false)

  const reload = async (silent = false) => {
    if (!silent) setLoading(true)
    setError('')
    try {
      const [deviceRes, branchRes] = await Promise.all([
        apiClient.get('/devices/'), apiClient.get('/branches/'),
      ])
      setDevices(unwrap(deviceRes) || [])
      setBranches(unwrap(branchRes) || [])
    } catch (e) { setError(e?.response?.data?.message || 'Unable to load devices. Check your role and branch access.') }
    finally { if (!silent) setLoading(false) }
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
  const viewDiagnostics = async (device) => {
    setDiagnosticDevice(device); setDiagnostics([]); setDiagnosticsLoading(true)
    try {
      const response = await apiClient.get(`/devices/${encodeURIComponent(device.device_id)}/diagnostics/?limit=50`)
      setDiagnostics(unwrap(response) || [])
    } catch (e) { setError(e?.response?.data?.message || 'Unable to load device diagnostics.') }
    finally { setDiagnosticsLoading(false) }
  }

  return <Box sx={{ p: { xs: 2, md: 3 }, display: 'grid', gap: 2 }}>
    <Box><Typography variant="h4">Device Management</Typography><Typography color="text.secondary">Provision devices, manage branch association, and monitor registered fingerprint devices.</Typography></Box>
    {error ? <Alert severity="error">{error}</Alert> : null}{notice ? <Alert severity="info">{notice}</Alert> : null}
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
