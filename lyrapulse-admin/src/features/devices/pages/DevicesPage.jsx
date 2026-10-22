import { useEffect, useState } from 'react'
import { Alert, Box, Button, CircularProgress, Dialog, DialogActions, DialogContent, DialogTitle, MenuItem, Paper, Stack, Switch, Table, TableBody, TableCell, TableHead, TableRow, TextField, Typography } from '@mui/material'
import apiClient from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data

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
  const [notice, setNotice] = useState('')
  const [enrollment, setEnrollment] = useState(null)

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
    event.preventDefault(); setError(''); setNotice('')
    try {
      const response = await apiClient.post('/devices/', form)
      const data = unwrap(response)
      setToken(data.provisioning_token || '')
      setForm({ device_id: '', name: '', branch_id: '' })
      setNotice('Device provisioned. Copy the one-time token into secure device configuration.')
      await reload()
    } catch (e) { setError(e?.response?.data?.message || 'Device provisioning failed.') }
  }
  const toggle = async (device) => {
    try {
      await apiClient.patch('/devices/', { device_id: device.device_id, is_active: !device.is_active })
      await reload()
    } catch (e) { setError(e?.response?.data?.message || 'Device update failed.') }
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
        <TextField label="Device ID" required value={form.device_id} onChange={e => setForm({ ...form, device_id: e.target.value })} />
        <TextField label="Name" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} />
        <TextField select label="Branch" required value={form.branch_id} onChange={e => setForm({ ...form, branch_id: e.target.value })} sx={{ minWidth: 180 }}>
          {branches.map(b => <MenuItem key={b.id} value={b.id}>{b.name}</MenuItem>)}
        </TextField>
        <Button type="submit" variant="contained">Provision</Button>
      </Stack>
    </Paper>
    <Paper sx={{ p: 2 }}>
      <Typography variant="h6" sx={{ mb: 1 }}>Registered devices</Typography>
      {loading ? <CircularProgress size={24} /> : <Table size="small"><TableHead><TableRow><TableCell>Device</TableCell><TableCell>Branch</TableCell><TableCell>Active</TableCell><TableCell /></TableRow></TableHead><TableBody>
        {devices.map(d => <TableRow key={d.device_id}><TableCell>{d.name || d.device_id}<Typography variant="caption" display="block">{d.device_id}</Typography></TableCell><TableCell>{d.branch_name}</TableCell><TableCell>{d.is_active ? 'Yes' : 'No'}</TableCell><TableCell><Switch checked={d.is_active} onChange={() => toggle(d)} inputProps={{ 'aria-label': `Activate ${d.device_id}` }} /></TableCell></TableRow>)}
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
    <Dialog open={Boolean(token)} onClose={() => setToken('')} fullWidth maxWidth="sm"><DialogTitle>Copy device token</DialogTitle><DialogContent><Alert severity="warning" sx={{ mb: 2 }}>This credential is shown once. Store it securely and configure device firmware for HTTPS.</Alert><TextField fullWidth multiline value={token} inputProps={{ readOnly: true }} /></DialogContent><DialogActions><Button onClick={() => { navigator.clipboard?.writeText(token); setToken('') }}>Copy and close</Button></DialogActions></Dialog>
  </Box>
}
