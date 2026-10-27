import apiClient from '../../../services/apiClient'
import { departmentsApi } from '../../departments/api/departmentsApi'

const unwrap = (response) => response.data?.data ?? response.data
const list = async (url, params) => {
  const data = unwrap(await apiClient.get(url, { params }))
  return Array.isArray(data) ? data : []
}

export const designationsApi = {
  list: (params) => list('/designations/', params),
  get: async (id) => unwrap(await apiClient.get('/designations/' + id + '/')),
  create: (payload) => apiClient.post('/designations/', payload),
  update: (id, payload) => apiClient.patch('/designations/' + id + '/', payload),
  remove: (id) => apiClient.delete('/designations/' + id + '/'),
  listDepartments: (params) => departmentsApi.list(params),
}