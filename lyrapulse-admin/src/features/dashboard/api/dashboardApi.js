export const dashboardApi = {
  getOverview: async () => ({
    totalEmployees: 1284,
    presentToday: 903,
    absentToday: 142,
    onLeave: 68,
    lateToday: 61,
    attendanceData: [
      { day: 'Mon', present: 520, late: 46 },
      { day: 'Tue', present: 650, late: 59 },
      { day: 'Wed', present: 610, late: 53 },
      { day: 'Thu', present: 690, late: 65 },
      { day: 'Fri', present: 720, late: 61 },
      { day: 'Sat', present: 470, late: 32 },
    ],
    leavesByType: [
      { name: 'Annual', value: 52 },
      { name: 'Sick', value: 25 },
      { name: 'Casual', value: 18 },
      { name: 'Maternity', value: 7 },
    ],
  }),
}
