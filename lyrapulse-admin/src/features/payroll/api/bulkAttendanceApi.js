import apiClient from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data

export const bulkAttendanceApi = {
  grid: async (params, signal) => unwrap(await apiClient.get('/attendance/admin/bulk-adjustments/', { params, signal, skipBranchContext: true })),
  codes: async (signal) => unwrap(await apiClient.get('/attendance/admin/bulk-adjustments/codes/', { signal })),
  save: async (changes) => unwrap(await apiClient.post('/attendance/admin/bulk-adjustments/save/', { changes })),
  export: async (params) => {
    const response = await apiClient.get('/attendance/admin/bulk-adjustments/export/', { params, responseType: 'blob', timeout: 120000, skipBranchContext: true })
    const disposition = response.headers?.['content-disposition'] ?? ''
    const match = /filename\*?=(?:UTF-8'')?"?([^";]+)"?/i.exec(disposition)
    return { blob: response.data, filename: match ? decodeURIComponent(match[1]) : null }
  },
  branches: async (signal) => unwrap(await apiClient.get('/branches/', { params: { include_inactive: true }, signal })),
}

export function downloadExcel(blob, filename) {
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  link.remove()
  setTimeout(() => URL.revokeObjectURL(url), 1000)
}
