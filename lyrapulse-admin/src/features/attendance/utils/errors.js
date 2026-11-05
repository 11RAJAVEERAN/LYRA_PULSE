function flattenErrors(errors) {
  if (!errors) return ''
  if (typeof errors === 'string') return errors
  return Object.values(errors).map((value) => (Array.isArray(value) ? value.join(' ') : flattenErrors(value))).join(' ')
}

// Turns an axios error into a short message that is safe to show. Never exposes raw server output.
export function attendanceErrorMessage(error, parsedBody) {
  const response = error?.response
  if (!response) return 'Unable to reach the server. Check your connection and try again.'
  const data = parsedBody ?? response.data
  switch (response.status) {
    case 400: return flattenErrors(data?.errors) || 'One of the selected filters is not valid.'
    case 401: return 'Your session has expired. Please sign in again.'
    case 403: return 'You do not have permission to view attendance.'
    case 404: return data?.message && data.message !== 'Request failed' ? data.message : 'The requested attendance data was not found.'
    default: return 'The server could not complete this request. Please try again.'
  }
}

// Export requests use responseType "blob", so an error body arrives as a Blob and must be decoded first.
export async function exportErrorMessage(error) {
  let parsed
  const body = error?.response?.data
  if (body instanceof Blob) {
    try { parsed = JSON.parse(await body.text()) } catch { parsed = undefined }
  }
  return attendanceErrorMessage(error, parsed)
}
