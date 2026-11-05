export const apiConfig = {
  baseUrl: import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000/api/v1',
  timeout: 15000,
  refreshEnabled: true,
}
