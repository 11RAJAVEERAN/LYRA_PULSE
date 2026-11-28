import { useMemo, useState } from "react";
import { Box, Button, MenuItem, TextField, Typography } from "@mui/material";
import { Download, FileText, Search } from "lucide-react";
import { colors, palette } from "../theme/colors";
import { typography } from "../theme/typography";
import { ReportTableStyles } from "./ReportTableStyles";

const employeesData = [
  {
    id: 1501,
    name: "ANBALAGAN S",
    role: "Operation Executive",
    department: "Operation",
    branch: "Chennai",
    full: 26,
    half: 0,
    absent: 3,
    weekOff: 0,
    leaves: 0,
    holidays: 0,
  },
  {
    id: 1502,
    name: "GANESAN S",
    role: "Driver",
    department: "FO",
    branch: "Chennai",
    full: 26,
    half: 0,
    absent: 3,
    weekOff: 0,
    leaves: 0,
    holidays: 0,
  },
  {
    id: 1503,
    name: "AARUMUGAM T",
    role: "Operation Executive",
    department: "Operation",
    branch: "Chennai",
    full: 27,
    half: 0,
    absent: 2,
    weekOff: 0,
    leaves: 0,
    holidays: 0,
  },
  {
    id: 1504,
    name: "SELVAM V",
    role: "General Technician",
    department: "Maintenance",
    branch: "Head Office",
    full: 28,
    half: 0,
    absent: 1,
    weekOff: 0,
    leaves: 0,
    holidays: 0,
  },
  {
    id: 1505,
    name: "RAJESH K",
    role: "Supervisor",
    department: "Operations",
    branch: "Hyderabad",
    full: 24,
    half: 2,
    absent: 2,
    weekOff: 1,
    leaves: 0,
    holidays: 0,
  },
];

const makeDates = (from, to) => {
  if (!from || !to || from > to) return [];
  const result = [];
  const current = new Date(`${from}T12:00:00`);
  const end = new Date(`${to}T12:00:00`);

  while (current <= end && result.length < 100) {
    result.push(new Date(current));
    current.setDate(current.getDate() + 1);
  }

  return result;
};

const exportCsv = (filename, rows) => {
  const csv = rows
    .map((row) =>
      row
        .map((value) => `"${String(value ?? "").replace(/"/g, '""')}"`)
        .join(","),
    )
    .join("\r\n");

  const blob = new Blob(["\uFEFF" + csv], {
    type: "text/csv;charset=utf-8;",
  });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
};

const inputSx = {
  minWidth: 165,
  "& .MuiOutlinedInput-root": {
    height: 40,
    borderRadius: "8px",
    backgroundColor: colors.surface,
    fontSize: "13px",
  },
  "& .MuiInputLabel-root": { fontSize: "13px" },
};

const exportButtonSx = {
  height: 40,
  px: 2,
  gap: 1,
  borderRadius: "8px",
  border: "1px solid transparent",
  background:
    palette?.lyra?.primaryGradient ||
    colors.primaryBlue ||
    `linear-gradient(90deg, ${colors.primary}, ${colors.secondary})`,
  color: colors.surface,
  boxShadow: palette?.lyra?.actionShadow || "0 2px 6px rgba(37, 99, 235, 0.22)",
  fontWeight: 600,
  fontSize: "13px",
  textTransform: "none",
  whiteSpace: "nowrap",
  "&:hover": {
    opacity: 0.94,
    background:
      palette?.lyra?.primaryGradient ||
      colors.primaryBlue ||
      `linear-gradient(90deg, ${colors.primary}, ${colors.secondary})`,
    boxShadow:
      palette?.lyra?.actionShadow || "0 4px 10px rgba(37, 99, 235, 0.28)",
  },
};

const buttonSx = {
  height: 40,
  px: 2,
  borderRadius: "8px",
  fontWeight: 600,
  fontSize: "13px",
  textTransform: "none",
  whiteSpace: "nowrap",
};

const tableSx = {
  width: "max-content",
  minWidth: "100%",
  borderCollapse: "separate",
  borderSpacing: 0,
  fontFamily: typography.fontFamily,
  fontSize: "13px",
  "& th, & td": {
    px: 1.75,
    py: 1.25,
    textAlign: "left",
    whiteSpace: "nowrap",
    borderBottom: `1px solid ${colors.border}`,
    verticalAlign: "middle",
  },
  "& th": {
    position: "sticky",
    top: 0,
    zIndex: 3,
    height: 54,
    backgroundColor: colors.infoBackground,
    color: colors.primary,
    fontWeight: 700,
    lineHeight: 1.35,
    fontSize: "13px",
  },
  "& th span": {
    display: "block",
    marginTop: "2px",
    color: colors.textSecondary,
    fontSize: "12px",
    fontWeight: 400,
  },
  "& tbody tr": {
    height: 60,
    backgroundColor: colors.surface,
    "&:hover": {
      backgroundColor: colors.hover,
      "& td": {
        backgroundColor: colors.hover,
      },
    },
  },
  "& tbody td": {
    backgroundColor: colors.surface,
  },
  "& tbody tr:last-child td": {
    borderBottom: 0,
  },
};

export default function MusterReportPage() {
  const [from, setFrom] = useState("2026-10-01");
  const [to, setTo] = useState("2026-10-29");
  const [branch, setBranch] = useState("All");
  const [search, setSearch] = useState("");
  const [filters, setFilters] = useState({
    from: "2026-10-01",
    to: "2026-10-29",
    branch: "All",
    search: "",
  });

  const dates = useMemo(
    () => makeDates(filters.from, filters.to),
    [filters.from, filters.to],
  );

  const employees = useMemo(
    () =>
      employeesData.filter((employee) => {
        const branchMatch =
          filters.branch === "All" || employee.branch === filters.branch;
        const query = filters.search.trim().toLowerCase();
        const searchMatch =
          employee.name.toLowerCase().includes(query) ||
          String(employee.id).includes(query) ||
          employee.role.toLowerCase().includes(query);

        return branchMatch && searchMatch;
      }),
    [filters],
  );

  const applyFilters = () => {
    if (!from || !to || from > to) return;
    setFilters({ from, to, branch, search });
  };

  const getStatus = (employee, date, index) => {
    if (date.getDay() === 0 && index % 3 === 0) return "WO";
    if (index % 11 === 5) return "A";
    if (index % 13 === 7) return "HD";
    return "FD";
  };

  const handleExport = () => {
    const headers = [
      "Employee",
      "Employee ID",
      "Role",
      "Department",
      "Full Days",
      "Half Days",
      "Absent Days",
      "Week Off",
      "Leaves",
      "Holidays",
      ...dates.map((date) => date.toLocaleDateString("en-GB")),
    ];

    const rows = employees.map((employee) => [
      employee.name,
      employee.id,
      employee.role,
      employee.department,
      employee.full,
      employee.half,
      employee.absent,
      employee.weekOff,
      employee.leaves,
      employee.holidays,
      ...dates.map((date, index) => getStatus(employee, date, index)),
    ]);

    exportCsv("muster-report.csv", [headers, ...rows]);
  };

  const stickyEmployee = {
    position: "sticky",
    left: 0,
    minWidth: 220,
    width: 220,
    zIndex: 2,
    borderRight: `1px solid ${colors.border}`,
  };

  const stickyRole = {
    position: "sticky",
    left: 220,
    minWidth: 210,
    width: 210,
    zIndex: 2,
    borderRight: `1px solid ${colors.borderStrong}`,
    boxShadow: "3px 0 5px rgba(15,23,42,0.025)",
  };

  return (
    <Box
      sx={{
        width: "100%",
        minWidth: 0,
        color: colors.textPrimary,
        fontFamily: typography.fontFamily,
      }}
    >
      <ReportTableStyles />

      {/* Top Header & Blue Export Buttons (matches Attendance Master) */}
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          flexWrap: "wrap",
          gap: 1.5,
          mb: 1.75,
        }}
      >
        <Typography
          variant="h5"
          component="h1"
          sx={{
            fontSize: "24px",
            fontWeight: 700,
            letterSpacing: "-0.015em",
            lineHeight: 1.25,
            color: colors.primary || "#1a237e",
          }}
        >
          Muster Report
        </Typography>

        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            flexWrap: "wrap",
            gap: 1.25,
          }}
        >
          <Button
            variant="contained"
            onClick={handleExport}
            startIcon={<Download size={16} />}
            sx={exportButtonSx}
          >
            Export Excel
          </Button>

          <Button
            variant="contained"
            onClick={() => window.print()}
            startIcon={<FileText size={16} />}
            sx={exportButtonSx}
          >
            Export PDF
          </Button>
        </Box>
      </Box>

      {/* Separate Filter Card */}
      <Box
        component="section"
        sx={{
          width: "100%",
          mb: 2,
          p: { xs: 1.5, md: 2 },
          px: { xs: 2, md: 2.5 },
          bgcolor: colors.surface,
          border: `1px solid ${colors.border}`,
          borderRadius: "12px",
          boxShadow: "0 1px 2px rgba(15, 23, 42, 0.04)",
        }}
      >
        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            flexWrap: "wrap",
            gap: 1.25,
          }}
        >
          <TextField
            label="From Date"
            type="date"
            size="small"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            sx={inputSx}
            slotProps={{ inputLabel: { shrink: true } }}
          />
          <TextField
            label="To Date"
            type="date"
            size="small"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            sx={inputSx}
            slotProps={{ inputLabel: { shrink: true } }}
          />
          <TextField
            select
            label="Choose Branch"
            size="small"
            value={branch}
            onChange={(e) => setBranch(e.target.value)}
            sx={{ ...inputSx, minWidth: 200 }}
          >
            <MenuItem value="All">All Branches</MenuItem>
            <MenuItem value="Chennai">Chennai</MenuItem>
            <MenuItem value="Hyderabad">Hyderabad</MenuItem>
            <MenuItem value="Head Office">Head Office</MenuItem>
          </TextField>
          <TextField
            size="small"
            placeholder="Search employee..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && applyFilters()}
            sx={{ ...inputSx, minWidth: 190 }}
          />
          <Button
            variant="contained"
            onClick={applyFilters}
            startIcon={<Search size={16} />}
            sx={{
              ...buttonSx,
              minWidth: 110,
              background:
                palette?.lyra?.primaryGradient ||
                `linear-gradient(90deg, ${colors.primary}, ${colors.secondary})`,
            }}
          >
            Search
          </Button>
        </Box>
      </Box>

      {/* Separate Table Card */}
      <Box
        component="section"
        sx={{
          width: "100%",
          overflow: "hidden",
          bgcolor: colors.surface,
          border: `1px solid ${colors.border}`,
          borderRadius: "12px",
          boxShadow: "0 1px 2px rgba(15, 23, 42, 0.04)",
        }}
      >
        <Box
          sx={{
            width: "100%",
            overflow: "auto",
            maxHeight: "calc(100vh - 290px)",
            minHeight: 300,
            scrollbarWidth: "thin",
          }}
        >
          <Box component="table" sx={tableSx}>
            <thead>
              <tr>
                <th style={stickyEmployee}>Employee</th>
                <th style={stickyRole}>Roles</th>
                <th>Full Days</th>
                <th>Half Days</th>
                <th>Absent Days</th>
                <th>Week Off</th>
                <th>Leaves</th>
                <th>Holidays</th>
                {dates.map((date) => (
                  <th key={date.toISOString()}>
                    {date.toLocaleDateString("en-GB", {
                      day: "2-digit",
                      month: "2-digit",
                      year: "numeric",
                    })}
                    <span>
                      {date.toLocaleDateString("en-US", { weekday: "long" })}
                    </span>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {employees.map((employee) => (
                <tr key={employee.id}>
                  <td style={stickyEmployee}>
                    <Box sx={{ fontWeight: 600 }}>{employee.name}</Box>
                    <Box sx={{ color: colors.textSecondary, fontSize: 12 }}>
                      {employee.id}
                    </Box>
                  </td>
                  <td style={stickyRole}>
                    <Box sx={{ fontWeight: 500 }}>{employee.role}</Box>
                    <Box sx={{ color: colors.textSecondary, fontSize: 12 }}>
                      {employee.department}
                    </Box>
                  </td>
                  <td>{employee.full}</td>
                  <td>{employee.half}</td>
                  <td>{employee.absent.toFixed(1)}</td>
                  <td>{employee.weekOff}</td>
                  <td>{employee.leaves.toFixed(1)}</td>
                  <td>{employee.holidays}</td>
                  {dates.map((date, index) => {
                    const status = getStatus(employee, date, index);
                    const statusColor = {
                      FD: colors.primary,
                      HD: colors.warningDark,
                      A: colors.error,
                      WO: colors.textSecondary,
                    }[status];

                    return (
                      <td key={date.toISOString()}>
                        <Box
                          component="span"
                          sx={{
                            color: statusColor,
                            fontWeight: 600,
                            textDecoration:
                              status === "FD" ? "underline" : "none",
                            textUnderlineOffset: "3px",
                          }}
                        >
                          {status}
                        </Box>
                      </td>
                    );
                  })}
                </tr>
              ))}
              {employees.length === 0 && (
                <tr>
                  <td
                    colSpan={8 + dates.length}
                    style={{ textAlign: "center", height: 120 }}
                  >
                    No employees found.
                  </td>
                </tr>
              )}
            </tbody>
          </Box>
        </Box>

        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            flexWrap: "wrap",
            gap: 1,
            px: 2.5,
            py: 1.5,
            borderTop: `1px solid ${colors.border}`,
            color: colors.textSecondary,
            fontSize: 12,
          }}
        >
          <span>Showing {employees.length} employees</span>
          <span>FD: Full Day · HD: Half Day · A: Absent · WO: Week Off</span>
        </Box>
      </Box>
    </Box>
  );
}
