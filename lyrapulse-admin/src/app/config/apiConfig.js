export const apiConfig = {
  baseUrl: import.meta.env.VITE_API_BASE_URL ?? 'http://10.174.138.23:8000/api/v1',
  timeout: 15000,
  refreshEnabled: true,
}
