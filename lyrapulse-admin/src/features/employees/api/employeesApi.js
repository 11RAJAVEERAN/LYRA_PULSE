import apiClient from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data
const list = (data) => (Array.isArray(data) ? data : [])

export const employeesApi = {
  list: async () => list(unwrap(await apiClient.get('/employees/'))),
  get: async (id) => unwrap(await apiClient.get(`/employees/${id}/`)),
  create: async (payload) => unwrap(await apiClient.post('/employees/', payload)),
  update: async (id, payload) => unwrap(await apiClient.patch(`/employees/${id}/`, payload)),
  formAccess: async () => unwrap(await apiClient.get('/employees/form-access/')),
  employeeTypes: async () => list(unwrap(await apiClient.get('/employee-types/'))),
  payrollGroups: async () => list(unwrap(await apiClient.get('/payroll-groups/'))),
  uploadDocument: async (employeeId, { docType, side, file }) => {
    const body = new FormData()
    body.append('doc_type', docType)
    body.append('side', side)
    body.append('file', file)
    // Let the browser set the multipart boundary; drop the client's default JSON content type for this call.
    return unwrap(await apiClient.post(`/employees/${employeeId}/documents/`, body, { headers: { 'Content-Type': undefined } }))
  },
  removeDocument: async (employeeId, documentId) => apiClient.delete(`/employees/${employeeId}/documents/${documentId}/`),
  fetchDocumentBlob: async (employeeId, documentId) => {
    const response = await apiClient.get(`/employees/${employeeId}/documents/${documentId}/download/`, { responseType: 'blob' })
    return response.data
  },
}