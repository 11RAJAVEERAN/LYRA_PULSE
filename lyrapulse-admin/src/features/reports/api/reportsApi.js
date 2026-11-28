import apiClient from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data

export const reportsApi = {
  list: async (report, params, signal) => unwrap(await apiClient.get(`/reports/${report}/`, { params, signal, skipBranchContext: true })),
  branches: async (signal) => unwrap(await apiClient.get('/branches/', { signal, skipBranchContext: true })),
  export: async (report, params) => {
    const response = await apiClient.get(`/reports/${report}/export/`, {
      params,
      responseType: 'blob',
      timeout: 120000,
      skipBranchContext: true,
    })
    const disposition = response.headers?.['content-disposition'] ?? ''
    const match = /filename\*?=(?:UTF-8'')?"?([^";]+)"?/i.exec(disposition)
    return { blob: response.data, filename: match ? decodeURIComponent(match[1]) : null }
  },
}

export function downloadReport({ blob, filename }, fallback) {
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename || fallback
  document.body.appendChild(link)
  link.click()
  link.remove()
  URL.revokeObjectURL(url)
}
