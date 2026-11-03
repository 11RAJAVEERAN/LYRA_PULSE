import { useMemo, useState } from "react";
import { Box, Button, MenuItem, TextField, Typography } from "@mui/material";
import { colors } from "../theme/colors";

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
    borderRadius: "8px",
    backgroundColor: colors.surface,
    fontSize: "14px",
  },
  "& .MuiInputLabel-root": { fontSize: "14px" },
};

const buttonSx = {
  minHeight: 40,
  px: 2,
  borderRadius: "8px",
  fontWeight: 600,
  textTransform: "none",
  whiteSpace: "nowrap",
};

const tableSx = {
  width: "max-content",
  minWidth: "100%",
  borderCollapse: "separate",
  borderSpacing: 0,
  fontFamily: 'Inter, "Segoe UI", sans-serif',
  fontSize: "14px",
  "& th, & td": {
    px: 2,
    py: 1.75,
    height: 68,
    textAlign: "left",
    whiteSpace: "nowrap",
    borderBottom: `1px solid ${colors.border}`,
  },
  "& th": {
    position: "sticky",
    top: 0,
    zIndex: 3,
    backgroundColor: "#EFF6FF",
    color: colors.primary,
    fontWeight: 600,
    lineHeight: 1.5,
  },
  "& th span": {
    display: "block",
    color: colors.textSecondary,
    fontSize: "12px",
    fontWeight: 400,
  },
  "& tbody tr:hover td": {
    backgroundColor: colors.surfaceMuted,
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
    minWidth: 190,
    width: 190,
    zIndex: 2,
    borderRight: `1px solid ${colors.borderStrong}`,
    boxShadow: "3px 0 5px rgba(15,23,42,0.025)",
  };

  return (
    <Box
      sx={{
        width: "100%",
        minWidth: 0,
        p: { xs: 1.5, md: 3 },
        bgcolor: colors.surface,
        color: colors.textPrimary,
        border: `1px solid ${colors.border}`,
        borderRadius: "12px",
        fontFamily: 'Inter, "Segoe UI", sans-serif',
      }}
    >
      <Typography variant="h5" sx={{ fontWeight: 650, mb: 0.5 }}>
        Muster Report
      </Typography>
      <Typography variant="body2" sx={{ color: colors.textSecondary, mb: 3 }}>
        Employee attendance summary and daily status
      </Typography>

      <Box
        sx={{
          display: "flex",
          flexDirection: "column",
          gap: 2,
          mb: 2.5,
        }}
      >
        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            flexWrap: "wrap",
            gap: 1.5,
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
          <Button
            variant="contained"
            onClick={applyFilters}
            sx={{
              ...buttonSx,
              minWidth: 110,
              background: `linear-gradient(90deg, ${colors.primary}, ${colors.secondary})`,
            }}
          >
            Search
          </Button>
        </Box>

        <Box
          sx={{
            display: "flex",
            justifyContent: "flex-end",
            flexWrap: "wrap",
            gap: 1.5,
          }}
        >
          <TextField
            size="small"
            placeholder="Search employee..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && applyFilters()}
            sx={{ ...inputSx, minWidth: 190 }}
          />
          <Button variant="outlined" onClick={handleExport} sx={buttonSx}>
            Export Excel
          </Button>
          <Button
            variant="outlined"
            onClick={() => window.print()}
            sx={buttonSx}
          >
            Muster Report
          </Button>
        </Box>
      </Box>

      <Box
        sx={{
          width: "100%",
          overflow: "auto",
          maxHeight: "calc(100vh - 330px)",
          minHeight: 300,
          border: `1px solid ${colors.border}`,
          borderRadius: "8px",
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
                <td style={{ ...stickyEmployee, background: colors.surface }}>
                  <Box sx={{ fontWeight: 600 }}>{employee.name}</Box>
                  <Box sx={{ color: colors.textSecondary, fontSize: 13 }}>
                    {employee.id}
                  </Box>
                </td>
                <td style={{ ...stickyRole, background: colors.surface }}>
                  <Box sx={{ fontWeight: 500 }}>{employee.role}</Box>
                  <Box sx={{ color: colors.textSecondary, fontSize: 13 }}>
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
                <td colSpan={8 + dates.length} style={{ textAlign: "center" }}>
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
          pt: 2,
          color: colors.textSecondary,
          fontSize: 13,
        }}
      >
        <span>Showing {employees.length} employees</span>
        <span>FD: Full Day · HD: Half Day · A: Absent · WO: Week Off</span>
      </Box>
    </Box>
  );
}
