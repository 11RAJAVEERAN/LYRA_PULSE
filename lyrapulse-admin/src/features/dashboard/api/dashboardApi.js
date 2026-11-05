import apiClient from '../../../services/apiClient'

const unwrap = (response) => response.data?.data ?? response.data

// The backend currently exposes employee data only (GET /employees/, scoped to the signed-in user's branches).
// There is no attendance, leave or aggregate dashboard endpoint, so those sections are reported as `null`
// (unavailable) instead of being estimated or filled with sample values.
export const dashboardApi = {
  getOverview: async () => {
    const data = unwrap(await apiClient.get('/employees/'))

    if (!Array.isArray(data)) {
      throw new Error('The employee list returned an unexpected response.')
    }

    const active = data.filter((employee) => employee.is_active === true).length
    const branchIds = new Set(
      data.map((employee) => employee.branch).filter((branch) => branch !== null && branch !== undefined),
    )

    return {
      employees: {
        total: data.length,
        active,
        inactive: data.length - active,
        branchCount: branchIds.size,
      },
      attendance: null,
      leaves: null,
    }
  },
}