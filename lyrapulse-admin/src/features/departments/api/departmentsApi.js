import apiClient from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data
const list = async (url, params) => {
  const data = unwrap(await apiClient.get(url, { params }))
  return Array.isArray(data) ? data : []
}

export const departmentsApi = {
  list: (params) => list('/departments/', params),
  get: async (id) => unwrap(await apiClient.get('/departments/' + id + '/')),
  create: (payload) => apiClient.post('/departments/', payload),
  update: (id, payload) => apiClient.patch('/departments/' + id + '/', payload),
  remove: (id) => apiClient.delete('/departments/' + id + '/'),
  listBranches: (params) => list('/branches/', params),
}