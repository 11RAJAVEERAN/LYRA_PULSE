import {
  Building2,
  CalendarCheck2,
  ChevronLeft,
  ChevronRight,
  ClipboardList,
  LayoutDashboard,
  NotebookPen,
  UserCog,
  Users,
} from "lucide-react";

import {
  Box,
  Divider,
  IconButton,
  List,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
} from "@mui/material";

import { NavLink } from "react-router-dom";

const navItems = [
  {
    label: "Dashboard",
    path: "/dashboard",
    icon: LayoutDashboard,
  },
  {
    label: "Employees",
    path: "/employees",
    icon: Users,
  },
  {
    label: "Attendance",
    path: "/attendance",
    icon: CalendarCheck2,
  },
  {
    label: "Leaves",
    path: "/leaves",
    icon: NotebookPen,
  },
  {
    label: "Branches",
    path: "/branches",
    icon: Building2,
  },
  {
    label: "Reports",
    path: "/reports",
    icon: ClipboardList,
  },
  {
    label: "Admin Users",
    path: "/admin-users",
    icon: UserCog,
    superadminOnly: true,
  },
];

export function Sidebar({ collapsed, onToggle, onNavigate }) {
  let user = null;

  try {
    user = JSON.parse(
      localStorage.getItem("lyrapulse_admin_user") ||
        sessionStorage.getItem("lyrapulse_admin_user") ||
        "null",
    );
  } catch {
    user = null;
  }

  const visibleItems = navItems.filter(({ superadminOnly, path }) => {
    if (superadminOnly) {
      return user?.role === "SUPERADMIN";
    }

    if (path === "/employees") {
      return (
        user?.role === "SUPERADMIN" ||
        user?.permissions?.includes("employees.view_employee")
      );
    }

    return user?.role === "SUPERADMIN";
  });

  const sidebarWidth = collapsed ? 88 : 260;

  return (
    <Box
      sx={{
        width: `${sidebarWidth}px`,
        height: "100vh",
        position: "fixed",
        top: 0,
        left: 0,
        zIndex: 1200,

        backgroundColor: "#0f172a",
        color: "#e2e8f0",

        borderRight: "1px solid rgba(148, 163, 184, 0.15)",

        display: "flex",
        flexDirection: "column",

        overflow: "hidden",

        transition: "width 0.2s ease",

        boxSizing: "border-box",
      }}
    >
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",

          px: 2,
          py: 1.5,

          minHeight: 72,
          flexShrink: 0,

          boxSizing: "border-box",
        }}
      >
        {!collapsed ? (
          <Box>
            <Typography
              variant="h6"
              sx={{
                color: "#ffffff",
                fontWeight: 700,
                lineHeight: 1.2,
              }}
            >
              Lyra Pulse
            </Typography>

            <Typography
              variant="caption"
              sx={{
                color: "#94a3b8",
              }}
            >
              Admin Console
            </Typography>
          </Box>
        ) : (
          <Box
            sx={{
              width: "100%",
              display: "flex",
              justifyContent: "center",
            }}
          >
            <Typography
              variant="h6"
              sx={{
                color: "#ffffff",
                fontWeight: 800,
              }}
            >
              L
            </Typography>
          </Box>
        )}

        <IconButton
          onClick={onToggle}
          size="small"
          sx={{
            color: "#cbd5e1",

            border: "1px solid rgba(148,163,184,0.2)",

            "&:hover": {
              backgroundColor: "rgba(148,163,184,0.08)",
            },
          }}
        >
          {collapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
        </IconButton>
      </Box>

      <Divider
        sx={{
          borderColor: "rgba(148,163,184,0.15)",
          flexShrink: 0,
        }}
      />

      <List
        sx={{
          px: 1.5,
          py: 2,

          flex: 1,

          overflow: "hidden",

          boxSizing: "border-box",
        }}
      >
        {visibleItems.map(({ label, path, icon: Icon }) => (
          <ListItemButton
            key={path}
            component={NavLink}
            to={path}
            onClick={onNavigate}
            sx={{
              borderRadius: 2,
              mb: 0.5,

              color: "#cbd5e1",

              minHeight: 44,

              "&.active": {
                backgroundColor: "rgba(59,130,246,0.18)",

                color: "#ffffff",

                "& .MuiListItemIcon-root": {
                  color: "#ffffff",
                },
              },

              "&:hover": {
                backgroundColor: "rgba(148,163,184,0.08)",
              },
            }}
          >
            <ListItemIcon
              sx={{
                color: "inherit",
                minWidth: collapsed ? 28 : 36,

                display: "flex",
                alignItems: "center",
              }}
            >
              <Icon size={18} />
            </ListItemIcon>

            {!collapsed && (
              <ListItemText
                primary={label}
                primaryTypographyProps={{
                  fontSize: 14,
                  fontWeight: 500,
                }}
              />
            )}
          </ListItemButton>
        ))}
      </List>
    </Box>
  );
}
