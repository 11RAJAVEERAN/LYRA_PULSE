// Form state, validation and API mapping for the Add/Edit "Details" panel.
// Backend validation stays authoritative; this only gives early feedback.

export const emptyEmployeeForm = {
  employee_code: '', name: '', display_name: '', phone_number: '', email: '',
  branch: '', department: '', designation: '', employee_type: '', door_lock_permission: 'yes',
  pf_number: '', uan_number: '', esic_number: '', address: '',
  joining_date: '', salary_type: 'MONTHLY', monthly_salary: '', payroll_group: '',
  bank_name: '', bank_branch_name: '', bank_account_number: '', bank_ifsc_code: '',
  emergency_contact_number: '', emergency_contact_name: '', emergency_contact_relation: '', emergency_contact_address: '',
  date_of_birth: '', is_active: true,
  biometric_attendance_enabled: false, mobile_gps_attendance_enabled: false, photo_attendance_enabled: false,
}

export const DOCUMENT_SLOTS = [
  { key: 'AADHAAR:FRONT', docType: 'AADHAAR', side: 'FRONT' },
  { key: 'AADHAAR:BACK', docType: 'AADHAAR', side: 'BACK' },
  { key: 'DRIVING_LICENCE:FRONT', docType: 'DRIVING_LICENCE', side: 'FRONT' },
  { key: 'DRIVING_LICENCE:BACK', docType: 'DRIVING_LICENCE', side: 'BACK' },
  { key: 'PAN:SINGLE', docType: 'PAN', side: 'SINGLE' },
  { key: 'PHOTO:SINGLE', docType: 'PHOTO', side: 'SINGLE' },
]

const MAX_IMAGE_BYTES = 10 * 1024 * 1024
const MAX_PDF_BYTES = 1024 * 1024

export function checkDocumentFile(file) {
  const extension = file.name.includes('.') ? file.name.split('.').pop().toLowerCase() : ''
  if (!['png', 'jpg', 'jpeg', 'pdf'].includes(extension)) return 'Supported formats: PNG, JPG, JPEG and PDF.'
  if (file.size === 0) return 'The file is empty.'
  if (extension === 'pdf' && file.size > MAX_PDF_BYTES) return 'PDF files must be 1 MB or smaller.'
  if (extension !== 'pdf' && file.size > MAX_IMAGE_BYTES) return 'Images must be 10 MB or smaller.'
  return ''
}

const IFSC = /^[A-Z]{4}0[A-Z0-9]{6}$/i

export function validateEmployeeForm(form, { requirePayrollGroup, sensitiveEditable }) {
  const errors = {}
  if (!form.employee_code.trim()) errors.employee_code = 'Employee code is required'
  if (!form.name.trim()) errors.name = 'Employee name is required'
  if (!/^\d{10}$/.test(form.phone_number)) errors.phone_number = 'Enter a valid 10-digit mobile number'
  if (form.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) errors.email = 'Enter a valid email address'
  if (!form.department) errors.department = 'Department is required'
  if (!form.designation) errors.designation = 'Designation is required'
  if (form.uan_number && !/^\d{12}$/.test(form.uan_number)) errors.uan_number = 'UAN must be 12 digits'
  if (form.esic_number && !/^\d{10}$/.test(form.esic_number)) errors.esic_number = 'ESIC IP number must be 10 digits'
  if (form.emergency_contact_number && !/^\d{10}$/.test(form.emergency_contact_number)) errors.emergency_contact_number = 'Enter a valid 10-digit number'
  if (form.date_of_birth && form.date_of_birth >= new Date().toISOString().slice(0, 10)) errors.date_of_birth = 'Date of birth must be in the past'
  if (sensitiveEditable) {
    if (form.salary_type === 'MONTHLY') {
      if (form.monthly_salary === '' || Number(form.monthly_salary) < 0 || Number.isNaN(Number(form.monthly_salary))) errors.monthly_salary = 'Enter the monthly salary'
    }
    if (requirePayrollGroup && !form.payroll_group) errors.payroll_group = 'Payroll group is required'
    if (form.bank_ifsc_code && !IFSC.test(form.bank_ifsc_code)) errors.bank_ifsc_code = 'Enter a valid IFSC code (e.g. SBIN0001234)'
    if (form.bank_account_number && !/^[A-Za-z0-9]{6,34}$/.test(form.bank_account_number.replace(/\s+/g, ''))) errors.bank_account_number = 'Enter a valid account number'
  }
  return errors
}

const idOrNull = (value) => (value === '' || value == null ? null : Number(value))

export function employeeToForm(employee) {
  const form = { ...emptyEmployeeForm }
  const name = [employee.first_name, employee.last_name].filter(Boolean).join(' ')
  Object.assign(form, {
    employee_code: employee.employee_code ?? '', name, display_name: employee.display_name ?? '',
    phone_number: employee.phone_number ?? '', email: employee.email ?? '',
    branch: employee.branch ?? '', department: employee.department ?? '', designation: employee.designation ?? '',
    employee_type: employee.employee_type ?? '', door_lock_permission: employee.door_lock_permission === false ? 'no' : 'yes',
    pf_number: employee.pf_number ?? '', uan_number: employee.uan_number ?? '', esic_number: employee.esic_number ?? '',
    address: employee.address ?? '', joining_date: employee.joining_date ?? '',
    salary_type: employee.salary_type ?? 'MONTHLY', monthly_salary: employee.monthly_salary ?? '',
    payroll_group: employee.payroll_group ?? '',
    bank_name: employee.bank_name ?? '', bank_branch_name: employee.bank_branch_name ?? '', bank_ifsc_code: employee.bank_ifsc_code ?? '',
    bank_account_number: '', // never returned by the API; blank on edit keeps the stored value
    emergency_contact_number: employee.emergency_contact_number ?? '', emergency_contact_name: employee.emergency_contact_name ?? '',
    emergency_contact_relation: employee.emergency_contact_relation ?? '', emergency_contact_address: employee.emergency_contact_address ?? '',
    date_of_birth: employee.date_of_birth ?? '', is_active: employee.is_active ?? true,
    biometric_attendance_enabled: employee.biometric_attendance_enabled ?? false,
    mobile_gps_attendance_enabled: employee.mobile_gps_attendance_enabled ?? false,
    photo_attendance_enabled: employee.photo_attendance_enabled ?? false,
  })
  return form
}

export function formToPayload(form, { sensitiveEditable, attendancePermissionsEditable = false }) {
  const [firstName, ...rest] = form.name.trim().split(/\s+/)
  const payload = {
    employee_code: form.employee_code.trim(), first_name: firstName ?? '', last_name: rest.join(' '),
    display_name: form.display_name.trim(), phone_number: form.phone_number, email: form.email.trim(),
    branch: idOrNull(form.branch), department: idOrNull(form.department), designation: idOrNull(form.designation),
    employee_type: idOrNull(form.employee_type), door_lock_permission: form.door_lock_permission === 'yes',
    pf_number: form.pf_number.trim(), uan_number: form.uan_number, esic_number: form.esic_number, address: form.address,
    joining_date: form.joining_date || null, date_of_birth: form.date_of_birth || null, is_active: form.is_active,
    emergency_contact_number: form.emergency_contact_number, emergency_contact_name: form.emergency_contact_name.trim(),
    emergency_contact_relation: form.emergency_contact_relation.trim(), emergency_contact_address: form.emergency_contact_address,
  }
  if (sensitiveEditable) {
    payload.salary_type = form.salary_type
    payload.monthly_salary = form.salary_type === 'MONTHLY' && form.monthly_salary !== '' ? form.monthly_salary : null
    payload.payroll_group = idOrNull(form.payroll_group)
    payload.bank_name = form.bank_name.trim()
    payload.bank_branch_name = form.bank_branch_name.trim()
    payload.bank_ifsc_code = form.bank_ifsc_code.trim().toUpperCase()
    if (form.bank_account_number.trim()) payload.bank_account_number = form.bank_account_number.replace(/\s+/g, '')
  }
  if (attendancePermissionsEditable) {
    payload.biometric_attendance_enabled = Boolean(form.biometric_attendance_enabled)
    payload.mobile_gps_attendance_enabled = Boolean(form.mobile_gps_attendance_enabled)
    payload.photo_attendance_enabled = Boolean(form.photo_attendance_enabled)
  }
  return payload
}

const FIELD_ALIASES = { first_name: 'name', last_name: 'name' }

// Map a DRF error body ({ errors: { field: [msgs] } }) to { formField: 'message' }.
export function mapBackendErrors(error) {
  const raw = error?.response?.data?.errors
  const fieldErrors = {}
  let general = ''
  if (raw && typeof raw === 'object') {
    for (const [field, messages] of Object.entries(raw)) {
      const text = Array.isArray(messages) ? messages.join(' ') : String(messages)
      const target = FIELD_ALIASES[field] ?? field
      fieldErrors[target] = fieldErrors[target] ? `${fieldErrors[target]} ${text}` : text
    }
  } else {
    general = error?.response?.data?.detail ?? error?.response?.data?.message ?? error?.message ?? 'Unable to complete this request.'
  }
  return { fieldErrors, general }
}
