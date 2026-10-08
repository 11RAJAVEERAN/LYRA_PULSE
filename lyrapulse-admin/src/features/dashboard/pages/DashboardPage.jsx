import {
  Activity,
  ArrowUpRight,
  CalendarCheck2,
  ChevronRight,
  Clock3,
  FileText,
  UserPlus,
  Users,
} from "lucide-react";

import { Box, Card, CardContent, Grid, Paper, Typography } from "@mui/material";

import { AttendanceChart } from "../../../components/charts/AttendanceChart";
import { PageHeader } from "../../../components/common/PageHeader";
import { StatsCard } from "../components/StatsCard";
import { useAuth } from "../../auth/hooks/useAuth";

const attendanceData = [
  { day: "Mon", present: 72, absent: 10 },
  { day: "Tue", present: 78, absent: 4 },
  { day: "Wed", present: 74, absent: 8 },
  { day: "Thu", present: 81, absent: 1 },
  { day: "Fri", present: 76, absent: 6 },
  { day: "Sat", present: 58, absent: 12 },
];

const recentActivity = [
  {
    name: "Angel",
    status: "Present",
    time: "08:58 AM",
    branch: "LyraTech ",
  },
  {
    name: "Misha",
    status: "Late",
    time: "09:14 AM",
    branch: "LyraTech",
  },
  {
    name: "maddy",
    status: "On Leave",
    time: "All Day",
    branch: "chennai",
  },
  {
    name: "Surya",
    status: "Present",
    time: "08:46 AM",
    branch: "Hyderabad",
  },
  {
    name: "Priya Sharma",
    status: "Present",
    time: "08:52 AM",
    branch: "Head Office",
  },
];

const leaveRequests = [
  {
    label: "Total Requests",
    value: 18,
    description: "This month",
    color: "#2563EB",
    bg: "#EFF6FF",
  },
  {
    label: "Pending",
    value: 5,
    description: "Needs review",
    color: "#F59E0B",
    bg: "#FFF7ED",
  },
  {
    label: "Approved",
    value: 10,
    description: "This month",
    color: "#16A34A",
    bg: "#ECFDF5",
  },
  {
    label: "Rejected",
    value: 3,
    description: "This month",
    color: "#DC2626",
    bg: "#FEF2F2",
  },
];

const quickActions = [
  {
    label: "Add Employee",
    description: "Create a new employee profile",
    icon: UserPlus,
  },
  {
    label: "Review Attendance",
    description: "Check today's attendance",
    icon: CalendarCheck2,
  },
  {
    label: "Approve Leave",
    description: "Review pending leave requests",
    icon: Clock3,
  },
  {
    label: "Generate Report",
    description: "Create attendance report",
    icon: FileText,
  },
];

export function DashboardPage() {
  const { currentUser } = useAuth();

  return (
    <Box
      sx={{
        minHeight: "100%",
        backgroundColor: "#f8fafc",
        p: { xs: 1, md: 0 },
      }}
    >
      <PageHeader
        title="Dashboard"
        subtitle={`Welcome back, ${currentUser?.name ?? "LyraTech Admin"}`}
      />

      <Grid container spacing={2.5} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="Total Employees"
            value="82"
            subtitle="Across 3 branches"
            trend="+3.8%"
            icon={<Users size={18} />}
            tone="primary"
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="Present Today"
            value="68"
            subtitle="82.9% of workforce"
            trend="+4.2%"
            icon={<Activity size={18} />}
            tone="success"
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="Absent Today"
            value="8"
            subtitle="9.8% of workforce"
            trend="-2.1%"
            icon={<Clock3 size={18} />}
            tone="warning"
          />
        </Grid>

        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <StatsCard
            title="On Leave"
            value="6"
            subtitle="2 requests pending"
            trend="+1"
            icon={<CalendarCheck2 size={18} />}
            tone="error"
          />
        </Grid>
      </Grid>

      <Grid container spacing={2.5} sx={{ mb: 3 }}>
        <Grid size={{ xs: 12, lg: 8 }}>
          <Paper
            sx={{
              p: { xs: 2, md: 3 },
              borderRadius: 3,
              height: "100%",
              border: "1px solid #e2e8f0",
              boxShadow: "0 2px 10px rgba(15, 23, 42, 0.04)",
            }}
          >
            <Box
              sx={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                mb: 2,
              }}
            >
              <Box>
                <Typography
                  variant="h6"
                  sx={{
                    fontWeight: 700,
                    color: "#0f172a",
                  }}
                >
                  Attendance Overview
                </Typography>

                <Typography
                  variant="body2"
                  sx={{
                    color: "#64748b",
                    mt: 0.4,
                  }}
                >
                  Employee attendance for this week
                </Typography>
              </Box>

              <Box
                sx={{
                  display: "flex",
                  alignItems: "center",
                  gap: 0.7,
                  px: 1.2,
                  py: 0.7,
                  borderRadius: 2,
                  backgroundColor: "#eff6ff",
                  color: "#2563eb",
                }}
              >
                <ArrowUpRight size={15} />
                <Typography variant="caption" sx={{ fontWeight: 700 }}>
                  4.2%
                </Typography>
              </Box>
            </Box>

            <AttendanceChart data={attendanceData} />
          </Paper>
        </Grid>

        <Grid size={{ xs: 12, lg: 4 }}>
          <Card
            sx={{
              height: "100%",
              borderRadius: 3,
              border: "1px solid #e2e8f0",
              boxShadow: "0 2px 10px rgba(15, 23, 42, 0.04)",
            }}
          >
            <CardContent sx={{ p: 3 }}>
              <Box
                sx={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "flex-start",
                  mb: 2.5,
                }}
              >
                <Box>
                  <Typography
                    variant="h6"
                    sx={{
                      fontWeight: 700,
                      color: "#0f172a",
                    }}
                  >
                    Leave Requests
                  </Typography>

                  <Typography
                    variant="body2"
                    sx={{
                      color: "#64748b",
                      mt: 0.5,
                    }}
                  >
                    Monthly leave overview
                  </Typography>
                </Box>

                <Box
                  sx={{
                    width: 36,
                    height: 36,
                    borderRadius: 2,
                    display: "grid",
                    placeItems: "center",
                    backgroundColor: "#eff6ff",
                    color: "#2563eb",
                  }}
                >
                  <CalendarCheck2 size={18} />
                </Box>
              </Box>

              <Box
                sx={{
                  display: "grid",
                  gridTemplateColumns: "1fr 1fr",
                  gap: 1.5,
                }}
              >
                {leaveRequests.map((item) => (
                  <Box
                    key={item.label}
                    sx={{
                      p: 1.7,
                      borderRadius: 2.5,
                      backgroundColor: item.bg,
                      border: `1px solid ${item.color}18`,
                    }}
                  >
                    <Typography
                      sx={{
                        fontSize: 11,
                        fontWeight: 600,
                        color: "#64748b",
                      }}
                    >
                      {item.label}
                    </Typography>

                    <Typography
                      sx={{
                        mt: 0.5,
                        fontSize: 24,
                        lineHeight: 1.1,
                        fontWeight: 750,
                        color: item.color,
                      }}
                    >
                      {item.value}
                    </Typography>

                    <Typography
                      sx={{
                        mt: 0.5,
                        fontSize: 10,
                        color: "#94a3b8",
                      }}
                    >
                      {item.description}
                    </Typography>
                  </Box>
                ))}
              </Box>

              <Box
                sx={{
                  mt: 2,
                  pt: 1.5,
                  borderTop: "1px solid #e2e8f0",
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                }}
              >
                <Typography
                  sx={{
                    fontSize: 11,
                    color: "#64748b",
                  }}
                >
                  Pending requests need attention
                </Typography>

                <Typography
                  sx={{
                    fontSize: 11,
                    fontWeight: 700,
                    color: "#2563eb",
                    cursor: "pointer",
                  }}
                >
                  View All
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Grid container spacing={2.5}>
        <Grid size={{ xs: 12, lg: 7 }}>
          <Card
            sx={{
              borderRadius: 3,
              border: "1px solid #e2e8f0",
              boxShadow: "0 2px 10px rgba(15, 23, 42, 0.04)",
            }}
          >
            <CardContent sx={{ p: 3 }}>
              <Box
                sx={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  mb: 2.5,
                }}
              >
                <Box>
                  <Typography
                    variant="h6"
                    sx={{
                      fontWeight: 700,
                      color: "#0f172a",
                    }}
                  >
                    Recent Attendance
                  </Typography>

                  <Typography
                    variant="body2"
                    sx={{
                      color: "#64748b",
                      mt: 0.4,
                    }}
                  >
                    Latest employee activity
                  </Typography>
                </Box>

                <Typography
                  variant="body2"
                  sx={{
                    color: "#2563eb",
                    fontWeight: 600,
                    cursor: "pointer",
                  }}
                >
                  View all
                </Typography>
              </Box>

              <Box
                sx={{
                  display: "flex",
                  flexDirection: "column",
                }}
              >
                {recentActivity.map((activity, index) => (
                  <Box
                    key={activity.name}
                    sx={{
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      py: 1.6,
                      borderBottom:
                        index === recentActivity.length - 1
                          ? "none"
                          : "1px solid #f1f5f9",
                    }}
                  >
                    <Box
                      sx={{
                        display: "flex",
                        alignItems: "center",
                        gap: 1.5,
                      }}
                    >
                      <Box
                        sx={{
                          width: 38,
                          height: 38,
                          borderRadius: "50%",
                          backgroundColor: "#eff6ff",
                          color: "#2563eb",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          fontWeight: 700,
                          fontSize: 14,
                        }}
                      >
                        {activity.name
                          .split(" ")
                          .map((name) => name[0])
                          .join("")
                          .slice(0, 2)}
                      </Box>

                      <Box>
                        <Typography
                          variant="body2"
                          sx={{
                            fontWeight: 600,
                            color: "#0f172a",
                          }}
                        >
                          {activity.name}
                        </Typography>

                        <Typography
                          variant="caption"
                          sx={{
                            color: "#64748b",
                          }}
                        >
                          {activity.branch} • {activity.time}
                        </Typography>
                      </Box>
                    </Box>

                    <Typography
                      variant="caption"
                      sx={{
                        px: 1.2,
                        py: 0.6,
                        borderRadius: 999,
                        fontWeight: 700,
                        backgroundColor:
                          activity.status === "Late"
                            ? "#fff7ed"
                            : activity.status === "On Leave"
                              ? "#fef2f2"
                              : "#f0fdf4",
                        color:
                          activity.status === "Late"
                            ? "#ea580c"
                            : activity.status === "On Leave"
                              ? "#dc2626"
                              : "#16a34a",
                      }}
                    >
                      {activity.status}
                    </Typography>
                  </Box>
                ))}
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid size={{ xs: 12, lg: 5 }}>
          <Card
            sx={{
              borderRadius: 3,
              border: "1px solid #e2e8f0",
              boxShadow: "0 2px 10px rgba(15, 23, 42, 0.04)",
            }}
          >
            <CardContent sx={{ p: 3 }}>
              <Typography
                variant="h6"
                sx={{
                  fontWeight: 700,
                  color: "#0f172a",
                }}
              >
                Quick Actions
              </Typography>

              <Typography
                variant="body2"
                sx={{
                  color: "#64748b",
                  mt: 0.5,
                  mb: 2,
                }}
              >
                Common admin activities
              </Typography>

              <Box
                sx={{
                  display: "flex",
                  flexDirection: "column",
                  gap: 1.2,
                }}
              >
                {quickActions.map((action) => {
                  const Icon = action.icon;

                  return (
                    <Box
                      key={action.label}
                      sx={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        p: 1.5,
                        borderRadius: 2.5,
                        border: "1px solid #e2e8f0",
                        backgroundColor: "#ffffff",
                        cursor: "pointer",
                        transition: "all 0.2s ease",

                        "&:hover": {
                          backgroundColor: "#f8fafc",
                          borderColor: "#bfdbfe",
                          transform: "translateY(-1px)",
                        },
                      }}
                    >
                      <Box
                        sx={{
                          display: "flex",
                          alignItems: "center",
                          gap: 1.5,
                        }}
                      >
                        <Box
                          sx={{
                            width: 38,
                            height: 38,
                            borderRadius: 2,
                            backgroundColor: "#eff6ff",
                            color: "#2563eb",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                          }}
                        >
                          <Icon size={18} />
                        </Box>

                        <Box>
                          <Typography
                            variant="body2"
                            sx={{
                              fontWeight: 700,
                              color: "#0f172a",
                            }}
                          >
                            {action.label}
                          </Typography>

                          <Typography
                            variant="caption"
                            sx={{
                              color: "#64748b",
                            }}
                          >
                            {action.description}
                          </Typography>
                        </Box>
                      </Box>

                      <ChevronRight size={17} color="#94a3b8" />
                    </Box>
                  );
                })}
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
}
