export const apiConfig = {
  baseUrl:
    import.meta.env.VITE_API_BASE_URL ?? "http://192.168.1.100:8000/api/v1",
  timeout: 15000,
  refreshEnabled: true,
};
