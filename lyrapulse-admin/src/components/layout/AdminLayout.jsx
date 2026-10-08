import { Box, Drawer, useMediaQuery, useTheme } from "@mui/material";
import { useState } from "react";
import { Outlet } from "react-router-dom";
import { Sidebar } from "./Sidebar";
import { Topbar } from "./Topbar";

export function AdminLayout() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("md"));

  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(false);

  const sidebarWidth = collapsed ? 88 : 260;

  const sidebarContent = (
    <Sidebar
      collapsed={isMobile ? false : collapsed}
      onToggle={() => setCollapsed((value) => !value)}
      onNavigate={() => setSidebarOpen(false)}
    />
  );

  return (
    <Box
      sx={{
        width: "100%",
        minHeight: "100vh",
        backgroundColor: "#f3f7fb",
      }}
    >
      {!isMobile ? (
        <Box
          sx={{
            display: "flex",
            width: "100%",
            minHeight: "100vh",
            alignItems: "stretch",
          }}
        >
          <Box
            sx={{
              width: sidebarWidth,
              minWidth: sidebarWidth,
              flexShrink: 0,
              transition: "width 0.2s ease",
            }}
          >
            {sidebarContent}
          </Box>

          <Box
            sx={{
              flex: 1,
              minWidth: 0,
              minHeight: "100vh",
              display: "flex",
              flexDirection: "column",
            }}
          >
            <Topbar title="Overview" />

            <Box
              component="main"
              sx={{
                flex: 1,
                minWidth: 0,
                p: {
                  xs: 2,
                  md: 3,
                },
                boxSizing: "border-box",
              }}
            >
              <Outlet />
            </Box>
          </Box>
        </Box>
      ) : (
        <Box
          sx={{
            width: "100%",
            minHeight: "100vh",
          }}
        >
          <Drawer
            variant="temporary"
            open={sidebarOpen}
            onClose={() => setSidebarOpen(false)}
            ModalProps={{
              keepMounted: true,
            }}
            slotProps={{
              paper: {
                sx: {
                  width: 260,
                  backgroundColor: "#0f172a",
                  overflow: "hidden",
                },
              },
            }}
          >
            {sidebarContent}
          </Drawer>

          <Box
            sx={{
              width: "100%",
              minHeight: "100vh",
              display: "flex",
              flexDirection: "column",
            }}
          >
            <Topbar title="Overview" onMenuClick={() => setSidebarOpen(true)} />

            <Box
              component="main"
              sx={{
                flex: 1,
                width: "100%",
                boxSizing: "border-box",
                p: {
                  xs: 2,
                  md: 3,
                },
              }}
            >
              <Outlet />
            </Box>
          </Box>
        </Box>
      )}
    </Box>
  );
}
