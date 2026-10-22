import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  Accordion, AccordionDetails, AccordionSummary, Alert, Box, Button, CircularProgress, Drawer, FormControl, FormControlLabel,
  FormHelperText, FormLabel, IconButton, InputAdornment, MenuItem, Radio, RadioGroup, Switch, TextField, Typography,
} from '@mui/material'
import { ChevronDown, X } from 'lucide-react'
import { colors } from '../../../theme/colors'
import { employeesApi } from '../api/employeesApi'
import { DocumentSlot } from './DocumentSlot'
import {
  DOCUMENT_SLOTS, checkDocumentFile, emptyEmployeeForm, employeeToForm, formToPayload, mapBackendErrors, validateEmployeeForm,
} from '../employeeFormModel'

const sameId = (left, right) => left !== '' && left != null && right !== '' && right != null && String(left) === String(right)
const digitsOnly = (value, max) => value.replace(/\D/g, '').slice(0, max)

const SECTIONS = [
  { id: 'basic', title: 'Basic Details' },
  { id: 'salary', title: 'Salary Details' },
  { id: 'bank', title: 'Bank Details' },
  { id: 'legal', title: 'Legal Documents' },
  { id: 'emergency', title: 'Emergency Contact Information' },
  { id: 'personal', title: 'Personal Information' },
  { id: 'attendance', title: 'Attendance Permissions' },
]

const DOCUMENT_GROUPS = [
  { title: 'Aadhar Card', docType: 'AADHAAR', sides: [['FRONT', 'Front Side'], ['BACK', 'Back Side']] },
  { title: 'Driving Licence', docType: 'DRIVING_LICENCE', sides: [['FRONT', 'Front Side'], ['BACK', 'Back Side']] },
  { title: 'Pan Card', docType: 'PAN', sides: [['SINGLE', '']] },
  { title: 'Passport Size Photo', docType: 'PHOTO', sides: [['SINGLE', '']] },
]

// Two columns on wider screens, single column on narrow ones; `fullRow` spans both columns.
const sectionBlock = { display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, minmax(0, 1fr))' }, columnGap: 2, rowGap: 1.75, px: 3, py: 2 }
const fullRow = { gridColumn: '1 / -1' }

// Scoped to this drawer only: compact, consistent inputs that follow the Login screen's field look
// (the border/hover/focus/error states and selection controls now come from theme.js).
const formFieldStyles = {
  '& .MuiInputBase-root:not(.MuiInputBase-multiline)': { minHeight: 44 },
  '& .MuiOutlinedInput-input::placeholder': { color: colors.textSecondary, opacity: 0.75 },
  '& .MuiInputLabel-root': { fontWeight: 500 },
  '& .MuiFormHelperText-root': { marginTop: 0.5, lineHeight: 1.35 },
}

export function EmployeeDetailsPanel({ open, employeeId, rows, options, optionsLoading, optionsError, onRetryOptions, onClose, onSaved }) {
  const isEdit = Boolean(employeeId)
  const [form, setForm] = useState(emptyEmployeeForm)
  const [errors, setErrors] = useState({})
  const [touched, setTouched] = useState({})
  const [expanded, setExpanded] = useState(['basic'])
  const [loading, setLoading] = useState(false)
  const [loadError, setLoadError] = useState('')
  const [saving, setSaving] = useState(false)
  const [formError, setFormError] = useState('')
  const [access, setAccess] = useState({ can_view_sensitive: false, can_change_sensitive: false, can_edit_attendance_permissions: false })
  const [masters, setMasters] = useState({ employeeTypes: [], payrollGroups: [] })
  const [mastersError, setMastersError] = useState('')
  const [storedDocs, setStoredDocs] = useState([])
  const [stagedDocs, setStagedDocs] = useState({})
  const [docErrors, setDocErrors] = useState({})
  const [busyDoc, setBusyDoc] = useState('')
  const [activeEmployeeId, setActiveEmployeeId] = useState(null)
  const [maskedAccount, setMaskedAccount] = useState('')
  const [manualAttendanceNotice, setManualAttendanceNotice] = useState('')
  const [manualAttendanceBusy, setManualAttendanceBusy] = useState(false)

  const sensitiveVisible = access.can_view_sensitive || access.can_change_sensitive
  const sensitiveEditable = access.can_change_sensitive

  const loadPanelData = useCallback(async () => {
    setLoading(true)
    setLoadError('')
    setMastersError('')
    try {
      const [accessData, employeeTypes, payrollGroups] = await Promise.all([
        employeesApi.formAccess(), employeesApi.employeeTypes(), employeesApi.payrollGroups(),
      ])
      setAccess(accessData)
      setMasters({ employeeTypes, payrollGroups })
    } catch (error) {
      setMastersError(mapBackendErrors(error).general || 'Unable to load dropdown options.')
    }
    if (employeeId) {
      try {
        const employee = await employeesApi.get(employeeId)
        setForm(employeeToForm(employee))
        setStoredDocs(employee.documents ?? [])
        setMaskedAccount(employee.bank_account_number_masked ?? '')
      } catch (error) {
        setLoadError(mapBackendErrors(error).general || 'Unable to load this employee.')
      }
    }
    setLoading(false)
  }, [employeeId])

  useEffect(() => {
    if (!open) return
    setErrors({})
    setTouched({})
    setFormError('')
    setStagedDocs({})
    setDocErrors({})
    setStoredDocs([])
    setMaskedAccount('')
    setExpanded(['basic'])
    setActiveEmployeeId(employeeId ?? null)
    if (!employeeId) {
      // Suggest the next numeric employee code; the backend still enforces uniqueness.
      const numeric = rows.map((row) => Number(row.employee_code)).filter((value) => Number.isInteger(value) && value > 0)
      setForm({ ...emptyEmployeeForm, employee_code: numeric.length ? String(Math.max(...numeric) + 1) : '' })
    } else {
      setForm(emptyEmployeeForm)
    }
    loadPanelData()
  }, [open, employeeId, loadPanelData]) // eslint-disable-line react-hooks/exhaustive-deps

  const requirePayrollGroup = masters.payrollGroups.length > 0
  const clientErrors = useMemo(
    () => validateEmployeeForm(form, { requirePayrollGroup, sensitiveEditable }),
    [form, requirePayrollGroup, sensitiveEditable],
  )
  const isValid = Object.keys(clientErrors).length === 0
  const visibleError = (name) => errors[name] || (touched[name] ? clientErrors[name] : '')

  const setValue = (name, value) => {
    setForm((current) => ({ ...current, [name]: value }))
    setErrors((current) => (current[name] ? { ...current, [name]: undefined } : current))
  }
  const touch = (name) => setTouched((current) => ({ ...current, [name]: true }))

  const inputProps = (name, extra = {}) => ({
    name, fullWidth: true, size: 'small', value: form[name], disabled: saving,
    onChange: (event) => setValue(name, extra.digits ? digitsOnly(event.target.value, extra.digits) : event.target.value),
    onBlur: () => touch(name),
    error: Boolean(visibleError(name)), helperText: visibleError(name) || extra.helper || undefined,
    ...extra.props,
  })

  const branchItems = useMemo(() => options.branches.filter((item) => item.is_active || sameId(item.id, form.branch)), [options.branches, form.branch])
  const departmentItems = useMemo(
    () => options.departments.filter((item) => sameId(item.id, form.department) || (sameId(item.branch, form.branch) && item.is_active)),
    [options.departments, form.branch, form.department],
  )
  const designationItems = useMemo(
    () => options.designations.filter((item) => sameId(item.id, form.designation) || (sameId(item.department, form.department) && item.is_active)),
    [options.designations, form.department, form.designation],
  )

  const changeBranch = (event) => {
    const branch = event.target.value
    setForm((current) => {
      const department = options.departments.find((item) => sameId(item.id, current.department))
      const keepDepartment = department && sameId(department.branch, branch)
      const designation = options.designations.find((item) => sameId(item.id, current.designation))
      const keepDesignation = keepDepartment && designation && sameId(designation.department, current.department)
      return { ...current, branch, department: keepDepartment ? current.department : '', designation: keepDesignation ? current.designation : '' }
    })
  }
  const changeDepartment = (event) => {
    const department = event.target.value
    setForm((current) => {
      const designation = options.designations.find((item) => sameId(item.id, current.designation))
      return { ...current, department, designation: designation && sameId(designation.department, department) ? current.designation : '' }
    })
  }

  const selectField = ({ name, label, items, onChange, placeholder, required, disabled, helper, sx }) => (
    <TextField
      select size="small" fullWidth name={name} label={label} required={required} sx={sx}
      value={form[name] !== '' && items.some((item) => sameId(item.id, form[name])) ? form[name] : ''}
      onChange={onChange ?? ((event) => setValue(name, event.target.value))}
      onBlur={() => touch(name)}
      disabled={saving || optionsLoading || disabled}
      error={Boolean(visibleError(name))} helperText={visibleError(name) || helper || undefined}
      slotProps={{ inputLabel: { shrink: true }, select: { displayEmpty: true, MenuProps: { slotProps: { paper: { sx: { maxHeight: 260 } } } } } }}
    >
      <MenuItem value=""><Typography component="span" color="text.secondary">{optionsLoading ? 'Loading…' : placeholder}</Typography></MenuItem>
      {items.map((item) => <MenuItem key={item.id} value={item.id}>{item.is_active === false ? `${item.name} (inactive)` : item.name}</MenuItem>)}
    </TextField>
  )

  const mobileField = (name, label, required) => (
    <TextField
      {...inputProps(name, { digits: 10 })} label={label} required={required} type="tel" placeholder="Enter Number"
      slotProps={{ input: { startAdornment: <InputAdornment position="start">+91</InputAdornment> }, htmlInput: { inputMode: 'numeric', maxLength: 10 } }}
    />
  )

  const radioGroup = (name, label, choices, required, disabled) => (
    <FormControl error={Boolean(visibleError(name))} disabled={saving || disabled} sx={fullRow}>
      <FormLabel id={`${name}-label`} required={required} sx={{ fontSize: 13, fontWeight: 500 }}>{label}</FormLabel>
      <RadioGroup row aria-labelledby={`${name}-label`} name={name} value={form[name]} onChange={(event) => setValue(name, event.target.value)}>
        {choices.map(([value, text]) => <FormControlLabel key={value} value={value} control={<Radio size="small" />} label={text} />)}
      </RadioGroup>
      {visibleError(name) ? <FormHelperText>{visibleError(name)}</FormHelperText> : null}
    </FormControl>
  )

  // ---- documents ----
  const slotStored = (docType, side) => storedDocs.find((doc) => doc.doc_type === docType && doc.side === side)
  const pickDocument = (key, file) => {
    const problem = checkDocumentFile(file)
    setDocErrors((current) => ({ ...current, [key]: problem }))
    if (!problem) setStagedDocs((current) => ({ ...current, [key]: file }))
  }
  const unstageDocument = (key) => {
    setStagedDocs((current) => { const next = { ...current }; delete next[key]; return next })
    setDocErrors((current) => ({ ...current, [key]: '' }))
  }
  const viewDocument = async (doc) => {
    try {
      const blob = await employeesApi.fetchDocumentBlob(activeEmployeeId, doc.id)
      const url = URL.createObjectURL(blob)
      window.open(url, '_blank', 'noopener')
      setTimeout(() => URL.revokeObjectURL(url), 60000)
    } catch (error) {
      setDocErrors((current) => ({ ...current, [`${doc.doc_type}:${doc.side}`]: mapBackendErrors(error).general || 'Unable to open the document.' }))
    }
  }
  const removeStoredDocument = async (doc) => {
    const key = `${doc.doc_type}:${doc.side}`
    setBusyDoc(key)
    try {
      await employeesApi.removeDocument(activeEmployeeId, doc.id)
      setStoredDocs((current) => current.filter((item) => item.id !== doc.id))
      setDocErrors((current) => ({ ...current, [key]: '' }))
    } catch (error) {
      setDocErrors((current) => ({ ...current, [key]: mapBackendErrors(error).general || 'Unable to remove the document.' }))
    } finally {
      setBusyDoc('')
    }
  }

  const recordManualAttendance = async () => {
    if (!activeEmployeeId || manualAttendanceBusy) return
    if (!window.confirm('Record a manual attendance action for this employee? The action will check in or check out based on the current open session.')) return
    setManualAttendanceBusy(true)
    setManualAttendanceNotice('')
    try {
      const result = await employeesApi.manualAttendance(activeEmployeeId)
      setManualAttendanceNotice(`Manual ${String(result.action || '').toLowerCase().replace('_', ' ')} recorded.`)
    } catch (error) {
      setManualAttendanceNotice(mapBackendErrors(error).general || 'Manual attendance could not be recorded.')
    } finally { setManualAttendanceBusy(false) }
  }

  // ---- save ----
  const save = async (event) => {
    event?.preventDefault()
    if (saving) return
    setTouched(Object.fromEntries(Object.keys(form).map((name) => [name, true])))
    if (!isValid) {
      const sectionOf = (name) => (['monthly_salary', 'payroll_group'].includes(name) ? 'salary' : name.startsWith('bank_') ? 'bank'
        : name.startsWith('emergency_') ? 'emergency' : name === 'date_of_birth' ? 'personal' : 'basic')
      setExpanded((current) => [...new Set([...current, ...Object.keys(clientErrors).map(sectionOf)])])
      setFormError('Please fix the highlighted fields.')
      return
    }
    setSaving(true)
    setFormError('')
    const payload = formToPayload(form, { sensitiveEditable, attendancePermissionsEditable: access.can_edit_attendance_permissions })
    let savedId = activeEmployeeId
    try {
      const saved = savedId ? await employeesApi.update(savedId, payload) : await employeesApi.create(payload)
      savedId = saved.id
      setActiveEmployeeId(savedId)
    } catch (error) {
      const { fieldErrors, general } = mapBackendErrors(error)
      setErrors(fieldErrors)
      setFormError(general || (Object.keys(fieldErrors).length ? 'The server rejected some fields. Please review them.' : 'Unable to save the employee.'))
      setSaving(false)
      return
    }

    const failures = []
    for (const slot of DOCUMENT_SLOTS) {
      const file = stagedDocs[slot.key]
      if (!file) continue
      setBusyDoc(slot.key)
      try {
        const doc = await employeesApi.uploadDocument(savedId, { docType: slot.docType, side: slot.side, file })
        setStoredDocs((current) => [...current.filter((item) => !(item.doc_type === slot.docType && item.side === slot.side)), doc])
        unstageDocument(slot.key)
      } catch (error) {
        const { fieldErrors, general } = mapBackendErrors(error)
        const message = fieldErrors.file || general || 'Upload failed.'
        failures.push(slot.key)
        setDocErrors((current) => ({ ...current, [slot.key]: message }))
      }
    }
    setBusyDoc('')
    setSaving(false)
    if (failures.length) {
      setExpanded((current) => [...new Set([...current, 'legal'])])
      setFormError('The employee was saved, but some documents could not be uploaded. Fix them below and press Save Details again.')
      onSaved(null, { keepOpen: true })
      return
    }
    onSaved(isEdit || activeEmployeeId ? 'Employee updated successfully.' : 'Employee added successfully.')
  }

  const toggleSection = (id) => setExpanded((current) => (current.includes(id) ? current.filter((item) => item !== id) : [...current, id]))
  const handleClose = () => { if (!saving) onClose() }

  const sensitiveNote = (
    <Alert severity="info" sx={{ mx: 3, my: 2, ...fullRow }}>You do not have permission to view or change this information.</Alert>
  )

  return (
    <Drawer anchor="right" open={open} onClose={handleClose} slotProps={{ paper: { sx: { width: { xs: '100%', sm: 600, lg: 680 }, maxWidth: '100%' } }, backdrop: { sx: { backgroundColor: 'rgba(15, 23, 42, 0.32)' } } }}>
      <Box component="form" onSubmit={save} noValidate sx={{ display: 'flex', flexDirection: 'column', height: '100%', minHeight: 0, color: colors.textPrimary, ...formFieldStyles }}>
        <Box sx={{ bgcolor: colors.surface, px: 3, py: 1.75, display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 2, borderBottom: `1px solid ${colors.border}` }}>
          <Box sx={{ minWidth: 0 }}>
            <Typography variant="h6" component="h2" sx={{ fontWeight: 650, lineHeight: 1.3 }}>{isEdit ? 'Edit Details' : 'Add Employee'}</Typography>
            <Typography variant="caption" sx={{ display: 'block', color: colors.textSecondary }}>
              {isEdit ? 'Update this employee’s profile and documents.' : 'Enter the employee’s profile, payroll and documents.'}
            </Typography>
          </Box>
          <IconButton aria-label="Close" onClick={handleClose} disabled={saving} size="small" sx={{ color: colors.textSecondary }}><X size={20} /></IconButton>
        </Box>

        <Box sx={{ flex: 1, minHeight: 0, overflowY: 'auto', overflowX: 'hidden', bgcolor: colors.surface }}>
          {loading ? (
            <Box sx={{ py: 6, display: 'flex', justifyContent: 'center' }}><CircularProgress size={26} aria-label="Loading" /></Box>
          ) : loadError ? (
            <Alert severity="error" sx={{ m: 3 }} action={<Button color="inherit" size="small" onClick={loadPanelData}>Retry</Button>}>{loadError}</Alert>
          ) : (
            <>
              {formError ? <Alert severity={activeEmployeeId && !isEdit ? 'warning' : 'error'} sx={{ mx: 3, mt: 1.5 }}>{formError}</Alert> : null}
              {optionsError ? (
                <Alert severity="warning" sx={{ mx: 3, mt: 1.5 }} action={<Button color="inherit" size="small" onClick={onRetryOptions}>Retry</Button>}>
                  Branch, department and designation options could not be loaded. {optionsError}
                </Alert>
              ) : null}
              {mastersError ? (
                <Alert severity="warning" sx={{ mx: 3, mt: 1.5 }} action={<Button color="inherit" size="small" onClick={loadPanelData}>Retry</Button>}>
                  Some dropdown options could not be loaded. {mastersError}
                </Alert>
              ) : null}

              {SECTIONS.map((section) => (
                <Accordion key={section.id} expanded={expanded.includes(section.id)} onChange={() => toggleSection(section.id)} disableGutters square elevation={0}
                  sx={{ borderBottom: `1px solid ${colors.border}`, '&::before': { display: 'none' }, '&.Mui-expanded': { margin: 0 } }}>
                  <AccordionSummary expandIcon={<ChevronDown size={18} />} aria-controls={`${section.id}-content`} id={`${section.id}-header`}
                    sx={{ px: 3, minHeight: 48, '&.Mui-expanded': { minHeight: 48 }, '&:hover': { bgcolor: colors.hover }, '&.Mui-focusVisible': { bgcolor: colors.selected }, '& .MuiAccordionSummary-content': { my: 1.25 }, '& .MuiAccordionSummary-expandIconWrapper': { color: colors.textSecondary } }}>
                    <Typography sx={{ fontWeight: 600, fontSize: '0.9375rem' }}>{section.title}</Typography>
                  </AccordionSummary>
                  <AccordionDetails sx={{ p: 0 }} id={`${section.id}-content`}>
                    {section.id === 'basic' ? (
                      <Box sx={sectionBlock}>
                        <TextField {...inputProps('employee_code')} label="Employee Code" required />
                        <TextField {...inputProps('name')} label="Employee Name" required placeholder="Enter Employee Name" autoComplete="name" />
                        <TextField {...inputProps('display_name')} label="Display Name" placeholder="Enter Display Name" />
                        {mobileField('phone_number', 'Mobile Number', true)}
                        <TextField {...inputProps('email')} label="Email" type="email" placeholder="Enter Employee Email" sx={fullRow} />
                        {selectField({ name: 'branch', label: 'Master Branch', items: branchItems, onChange: changeBranch, placeholder: 'Select Master Branches' })}
                        {selectField({ name: 'department', label: 'Department', required: true, items: departmentItems, onChange: changeDepartment, placeholder: 'Select Department', disabled: form.branch === '', helper: form.branch === '' ? 'Select a branch first' : undefined })}
                        {selectField({ name: 'designation', label: 'Designation', required: true, items: designationItems, placeholder: 'Select Designation', disabled: form.department === '', helper: form.department === '' ? 'Select a department first' : undefined })}
                        {selectField({ name: 'employee_type', label: 'Employee Type', items: masters.employeeTypes, placeholder: 'Select Employee Type', helper: masters.employeeTypes.length === 0 && !loading ? 'No employee types are configured yet.' : undefined })}
                        {radioGroup('door_lock_permission', 'Door Lock Permission', [['yes', 'Yes'], ['no', 'No']], true)}
                        <TextField {...inputProps('pf_number')} label="Provident Fund (PF)" placeholder="Enter PF Account Number" />
                        <TextField {...inputProps('uan_number', { digits: 12 })} label="Universal Account Number (UAN)" placeholder="Enter 12-Digit UAN Number" slotProps={{ htmlInput: { inputMode: 'numeric', maxLength: 12 } }} />
                        <TextField sx={fullRow} {...inputProps('esic_number', { digits: 10 })} label="Employee State Insurance Corporation (ESIC)" placeholder="Enter 10-Digit ESIC IP Number" slotProps={{ htmlInput: { inputMode: 'numeric', maxLength: 10 } }} />
                        <TextField {...inputProps('address')} label="Address" multiline minRows={2} sx={fullRow} />
                        {isEdit ? (
                          <FormControlLabel sx={fullRow} control={<Switch checked={form.is_active} onChange={(event) => setValue('is_active', event.target.checked)} disabled={saving} />}
                            label={form.is_active ? 'Active employee' : 'Inactive employee'} />
                        ) : null}
                      </Box>
                    ) : null}

                    {section.id === 'salary' ? (
                      <Box sx={sectionBlock}>
                        <TextField {...inputProps('joining_date')} label="Date of Joining" type="date" slotProps={{ inputLabel: { shrink: true } }} />
                        {sensitiveVisible ? (
                          <>
                            {radioGroup('salary_type', 'Salary Type', [['MONTHLY', 'Monthly'], ['HOURLY', 'Hourly'], ['COMPLIANCE', 'Compliance']], true, !sensitiveEditable)}
                            {form.salary_type === 'MONTHLY' ? (
                              <TextField {...inputProps('monthly_salary', { props: { disabled: saving || !sensitiveEditable } })} label="Monthly Salary" required type="number"
                                slotProps={{ input: { startAdornment: <InputAdornment position="start">₹</InputAdornment> }, htmlInput: { min: 0, step: '0.01' } }} />
                            ) : null}
                            {selectField({ name: 'payroll_group', label: 'Payroll Group', required: requirePayrollGroup, items: masters.payrollGroups, placeholder: 'Select Payroll Group', disabled: !sensitiveEditable, helper: masters.payrollGroups.length === 0 && !loading ? 'No payroll groups are configured yet.' : undefined })}
                          </>
                        ) : sensitiveNote}
                      </Box>
                    ) : null}

                    {section.id === 'bank' ? (
                      sensitiveVisible ? (
                        <Box sx={sectionBlock}>
                          <TextField {...inputProps('bank_name', { props: { disabled: saving || !sensitiveEditable } })} label="Bank Name" placeholder="Enter Bank Name" />
                          <TextField {...inputProps('bank_branch_name', { props: { disabled: saving || !sensitiveEditable } })} label="Branch Name" placeholder="Enter Branch Name" />
                          <TextField {...inputProps('bank_account_number', { props: { disabled: saving || !sensitiveEditable }, helper: isEdit && maskedAccount ? `Saved account: ${maskedAccount}. Leave blank to keep it.` : undefined })}
                            label="Account No" placeholder="Enter Account No" autoComplete="off" />
                          <TextField {...inputProps('bank_ifsc_code', { props: { disabled: saving || !sensitiveEditable } })} label="IFSC Code" placeholder="Enter IFSC Code"
                            onChange={(event) => setValue('bank_ifsc_code', event.target.value.toUpperCase().slice(0, 11))} />
                        </Box>
                      ) : sensitiveNote
                    ) : null}

                    {section.id === 'legal' ? (
                      sensitiveVisible ? (
                        <Box sx={sectionBlock}>
                          <Alert severity="info" icon={false} sx={{ py: 0.5, ...fullRow }}>Supported: PNG, JPG, JPEG, and PDF | Max size: 10 MB (Img) and 1 MB (PDFs)</Alert>
                          {DOCUMENT_GROUPS.map((group) => (
                            <Box key={group.docType} sx={{ ...fullRow, minWidth: 0, border: `1px solid ${colors.border}`, bgcolor: colors.surface, borderRadius: 1.5, p: 1.5, display: 'grid', gap: 1 }}>
                              <Typography sx={{ fontWeight: 600, fontSize: '0.875rem' }}>{group.title}</Typography>
                              <Box sx={{ display: 'grid', gridTemplateColumns: group.sides.length > 1 ? { xs: '1fr', sm: '1fr 1fr' } : '1fr', gap: 1.5 }}>
                                {group.sides.map(([side, label]) => {
                                  const key = `${group.docType}:${side}`
                                  const stored = slotStored(group.docType, side)
                                  return (
                                    <DocumentSlot key={key} label={label} stored={stored} staged={stagedDocs[key]} error={docErrors[key]} busy={busyDoc === key}
                                      disabled={saving || !sensitiveEditable} onPick={(file) => pickDocument(key, file)} onRemoveStaged={() => unstageDocument(key)}
                                      onView={() => viewDocument(stored)} onRemoveStored={() => removeStoredDocument(stored)} />
                                  )
                                })}
                              </Box>
                            </Box>
                          ))}
                          {!isEdit && !activeEmployeeId ? <Typography variant="caption" color="text.secondary" sx={fullRow}>Selected files are uploaded when you press Save Details.</Typography> : null}
                        </Box>
                      ) : sensitiveNote
                    ) : null}

                    {section.id === 'emergency' ? (
                      <Box sx={sectionBlock}>
                        {mobileField('emergency_contact_number', 'Contact Number', false)}
                        <TextField {...inputProps('emergency_contact_name')} label="Contact Person Name" placeholder="Enter Person Name" />
                        <TextField {...inputProps('emergency_contact_relation')} label="Relation with the Contact" placeholder="Enter Relation" />
                        <TextField {...inputProps('emergency_contact_address')} label="Address" multiline minRows={2} sx={fullRow} />
                      </Box>
                    ) : null}

                    {section.id === 'personal' ? (
                      <Box sx={sectionBlock}>
                        <TextField {...inputProps('date_of_birth', { props: { slotProps: { inputLabel: { shrink: true }, htmlInput: { max: new Date().toISOString().slice(0, 10) } } } })}
                          label="Date of Birth" type="date" />
                      </Box>
                    ) : null}

                    {section.id === 'attendance' ? (
                      access.can_edit_attendance_permissions ? (
                        <Box sx={sectionBlock}>
                          <Alert severity="info" sx={fullRow}>New employees have all attendance methods disabled. Mobile check-in and check-out require GPS; a photo is required for both actions when Photo Attendance is enabled.</Alert>
                          <FormControlLabel control={<Switch checked={form.biometric_attendance_enabled} onChange={(event) => setValue('biometric_attendance_enabled', event.target.checked)} disabled={saving} />} label="Biometric Attendance" />
                          <FormControlLabel control={<Switch checked={form.mobile_gps_attendance_enabled} onChange={(event) => setValue('mobile_gps_attendance_enabled', event.target.checked)} disabled={saving} />} label="Mobile GPS Attendance" />
                          <FormControlLabel control={<Switch checked={form.photo_attendance_enabled} onChange={(event) => setValue('photo_attendance_enabled', event.target.checked)} disabled={saving} />} label="Photo Attendance" />
                          {isEdit ? <Box sx={fullRow}><Button variant="outlined" onClick={recordManualAttendance} disabled={manualAttendanceBusy || saving}>{manualAttendanceBusy ? 'Recording…' : 'Record Admin Manual Attendance'}</Button>{manualAttendanceNotice ? <Typography role="status" variant="body2" sx={{ mt: 1 }}>{manualAttendanceNotice}</Typography> : null}<Typography variant="caption" display="block" color="text.secondary">This action alternates between check-in and check-out and is recorded with the acting administrator.</Typography></Box> : null}
                        </Box>
                      ) : <Alert severity="info" sx={{ m: 3 }}>Attendance permissions can be changed by Super Admin and Admin users.</Alert>
                    ) : null}
                  </AccordionDetails>
                </Accordion>
              ))}
            </>
          )}
        </Box>

        <Box sx={{ flexShrink: 0, bgcolor: colors.surface, px: 3, py: 1.5, display: 'flex', justifyContent: 'flex-end', gap: 1.5, borderTop: `1px solid ${colors.border}`, boxShadow: '0 -2px 8px rgba(15, 23, 42, 0.04)' }}>
          <Button type="button" variant="outlined" color="inherit" onClick={handleClose} disabled={saving} sx={{ bgcolor: colors.surface }}>Close</Button>
          <Button type="submit" variant="contained" disabled={saving || loading || Boolean(loadError) || !isValid}>
            {saving ? 'Saving…' : 'Save Details'}
          </Button>
        </Box>
      </Box>
    </Drawer>
  )
}
