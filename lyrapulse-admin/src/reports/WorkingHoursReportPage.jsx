import { useMemo, useState } from "react";
import { Box, Button, MenuItem, TextField, Typography } from "@mui/material";
import { colors } from "../theme/colors";
import { typography } from "../theme/typography";
import { ReportTableStyles } from './ReportTableStyles'

const employeesData = [
  {
    id: 1620,
    name: "SELVAKUMAR G",
    role: "CDP",
    department: "F&B Production",
    branch: "Chennai",
    work: 177 * 60 + 38,
    breakTime: 0,
  },
  {
    id: 119,
    name: "angel",
    role: "Operation Executive",
    department: "FO",
    branch: "Chennai",
    work: 2,
    breakTime: 1,
  },
  {
    id: 118,
    name: "madhavan",
    role: "Operation Executive",
    department: "FO",
    branch: "Hyderabad",
    work: 12 * 60 + 1,
    breakTime: 2 * 60 + 28,
  },
  {
    id: 117,
    name: "Rajaveeran",
    role: "Operation Executive",
    department: "Operation",
    branch: "Head Office",
    work: 67,
    breakTime: 3,
  },
  {
    id: 1616,
    name: "S SELVA",
    role: "Driver",
    department: "FO",
    branch: "Chennai",
    work: 190 * 60 + 27,
    breakTime: 4 * 60 + 35,
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

const formatMinutes = (minutes) => {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  if (!hours) return `${mins}m`;
  if (!mins) return `${hours}h`;
  return `${hours}h ${mins}m`;
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
  fontFamily: typography.fontFamily,
  fontSize: typography.body2.fontSize,
  "& th, & td": {
    px: 1.5,
    py: 1.25,
    textAlign: "left",
    whiteSpace: "nowrap",
    borderBottom: `1px solid ${colors.border}`,
  },
  "& th": {
    position: "sticky",
    top: 0,
    zIndex: 3,
    backgroundColor: colors.infoBackground,
    color: colors.primary,
    fontWeight: 600,
    lineHeight: 1.5,
    fontSize: '0.8125rem',
  },
  "& th span": {
    display: "block",
    color: colors.textSecondary,
    fontSize: "12px",
    fontWeight: 400,
  },
  "& tbody tr:hover td": {
    backgroundColor: colors.hover,
  },
  "& tbody tr": { height: 64 },
  "& tbody tr:last-child td": {
    borderBottom: 0,
  },
};

export default function WorkingHoursReportPage() {
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

  // Temporary sample values; replace with API attendance records.
  const getDailyMinutes = (employee, index) => {
    if (index % 3 === 0) return 0;
    return (employee.id + index * 37) % 540;
  };

  const handleExport = () => {
    const headers = [
      "Employee",
      "Employee ID",
      "Role",
      "Department",
      "Total Working Hours",
      "Total Break Hours",
      ...dates.map((date) => date.toLocaleDateString("en-GB")),
    ];

    const rows = employees.map((employee) => [
      employee.name,
      employee.id,
      employee.role,
      employee.department,
      formatMinutes(employee.work),
      formatMinutes(employee.breakTime),
      ...dates.map((date, index) =>
        formatMinutes(getDailyMinutes(employee, index)),
      ),
    ]);

    exportCsv("working-hours-report.csv", [headers, ...rows]);
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
        fontFamily: typography.fontFamily,
      }}
    >
      <ReportTableStyles />
      <Typography variant="h5" sx={{ fontWeight: 650, mb: 0.5 }}>
        Working Hours Report
      </Typography>
      <Typography variant="body2" sx={{ color: colors.textSecondary, mb: 3 }}>
        Employee-wise working time and break time summary
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
            Export PDF
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
              <th>Total Working Hour</th>
              <th>Total Break Hour</th>
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
                <td sx={{ fontWeight: 500 }}>{formatMinutes(employee.work)}</td>
                <td>{formatMinutes(employee.breakTime)}</td>
                {dates.map((date, index) => (
                  <td key={date.toISOString()}>
                    <Box
                      component="span"
                      sx={{
                        color: colors.primary,
                        textDecoration: "underline",
                        textUnderlineOffset: "3px",
                      }}
                    >
                      {formatMinutes(getDailyMinutes(employee, index))}
                    </Box>
                  </td>
                ))}
              </tr>
            ))}
            {employees.length === 0 && (
              <tr>
                <td colSpan={4 + dates.length} style={{ textAlign: "center" }}>
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
        <span>Working time is displayed in hours and minutes.</span>
      </Box>
    </Box>
  );
}
