import { useMemo, useState } from "react";

import {
  CalendarDays,
  ArrowUpDown,
  SlidersHorizontal,
  Download,
  FileText,
  Search,
  AlertTriangle,
} from "lucide-react";

import { colors, palette } from "../theme/colors";
import { typography } from "../theme/typography";
import { ReportTableStyles } from "./ReportTableStyles";

const styles = `
.branch-punch-page {
  width: 100%;
  min-height: 100%;
  padding: 0;
  background: transparent;
  color: ${colors.textPrimary};
  font-family: ${typography.fontFamily};
}

.branch-punch-page * {
  box-sizing: border-box;
}

.branch-punch-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 14px;
}

.branch-punch-title {
  margin: 0;
  padding: 0;
  font-size: 24px;
  font-weight: 700;
  letter-spacing: -0.015em;
  line-height: 1.25;
  color: ${colors.primary || "#1a237e"};
}

.branch-punch-header-actions {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.branch-punch-export-btn {
  height: 40px;
  padding: 0 16px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border: 1px solid transparent;
  border-radius: 8px;
  background: ${palette?.lyra?.primaryGradient || colors.primaryBlue || `linear-gradient(90deg, ${colors.primary}, ${colors.secondary})`};
  color: ${colors.surface};
  font-family: ${typography.fontFamily};
  font-size: 13px;
  font-weight: 600;
  white-space: nowrap;
  cursor: pointer;
  box-shadow: ${palette?.lyra?.actionShadow || "0 2px 6px rgba(37, 99, 235, 0.22)"};
  transition: opacity 0.15s ease, transform 0.15s ease, box-shadow 0.15s ease;
}

.branch-punch-export-btn:hover {
  opacity: 0.94;
  box-shadow: ${palette?.lyra?.actionShadow || "0 4px 10px rgba(37, 99, 235, 0.28)"};
}

.branch-punch-export-btn:active {
  transform: translateY(1px);
}

.branch-punch-filter-card {
  width: 100%;
  margin-bottom: 16px;
  background: ${colors.surface};
  border: 1px solid ${colors.border};
  border-radius: 12px;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
}

.branch-punch-table-card {
  width: 100%;
  overflow: hidden;
  background: ${colors.surface};
  border: 1px solid ${colors.border};
  border-radius: 12px;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
}

.branch-punch-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 16px 20px;
  overflow-x: auto;
  scrollbar-width: thin;
}

.branch-punch-filters {
  display: flex;
  align-items: center;
  flex-wrap: nowrap;
  gap: 10px;
  width: 100%;
}

.branch-punch-date {
  height: 40px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 11px;
  border: 1px solid ${colors.border};
  border-radius: 8px;
  background: ${colors.surface};
}

.branch-punch-date:focus-within {
  border-color: ${colors.primaryBlue};
  box-shadow: 0 0 0 3px ${colors.focusSubtle};
}

.branch-punch-date svg {
  color: ${colors.textSecondary};
  flex-shrink: 0;
}

.branch-punch-date input {
  width: 116px;
  border: none;
  outline: none;
  background: transparent;
  color: ${colors.textPrimary};
  font-family: ${typography.fontFamily};
  font-size: 13px;
}

.branch-punch-date span {
  color: ${colors.disabled || colors.textSecondary};
  flex-shrink: 0;
}

.branch-punch-select {
  height: 40px;
  min-width: 195px;
  flex-shrink: 0;
  padding: 0 12px;
  border: 1px solid ${colors.border};
  border-radius: 8px;
  outline: none;
  color: ${colors.textPrimary};
  background: ${colors.surface};
  font-family: ${typography.fontFamily};
  font-size: 13px;
  cursor: pointer;
}

.branch-punch-select:focus {
  border-color: ${colors.primaryBlue};
  box-shadow: 0 0 0 3px ${colors.focusSubtle};
}

.branch-punch-btn {
  height: 40px;
  padding: 0 16px;
  flex-shrink: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border-radius: 8px;
  font-family: ${typography.fontFamily};
  font-size: 13px;
  font-weight: 600;
  white-space: nowrap;
  cursor: pointer;
  transition: 0.15s ease;
}

.branch-punch-primary {
  min-width: 105px;
  border: none;
  color: ${colors.surface};
  background: ${palette?.lyra?.primaryGradient || `linear-gradient(90deg, ${colors.primary}, ${colors.secondary})`};
}

.branch-punch-primary:hover {
  opacity: 0.94;
  box-shadow: ${palette?.lyra?.actionShadow || `0 5px 14px ${colors.selection}`};
}

.branch-punch-search-box {
  min-width: 190px;
  flex: 1 1 190px;
  max-width: 260px;
  height: 40px;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 12px;
  border: 1px solid ${colors.border};
  border-radius: 8px;
  background: ${colors.surface};
  color: ${colors.textSecondary};
}

.branch-punch-search-box:focus-within {
  border-color: ${colors.primaryBlue};
  box-shadow: 0 0 0 3px ${colors.focusSubtle};
}

.branch-punch-search-box input {
  width: 100%;
  min-width: 0;
  border: none;
  outline: none;
  color: ${colors.textPrimary};
  background: transparent;
  font-family: ${typography.fontFamily};
  font-size: 13px;
}

.branch-punch-table-wrapper {
  width: 100%;
  max-height: calc(100vh - 280px);
  min-height: 300px;
  overflow: auto;
  scrollbar-width: thin;
}

.branch-punch-table {
  width: max-content;
  min-width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  text-align: left;
  font-size: 13px;
}

.branch-punch-table thead th {
  position: sticky;
  top: 0;
  z-index: 3;
  height: 58px;
  padding: 10px 14px;
  border-bottom: 1px solid ${colors.border};
  background: ${colors.infoBackground || colors.surfaceMuted};
  color: ${colors.primary};
  font-size: 13px;
  font-weight: 700;
  white-space: nowrap;
  vertical-align: middle;
}

.branch-punch-table td {
  min-height: 62px;
  padding: 12px 14px;
  border-bottom: 1px solid ${colors.border};
  background: ${colors.surface};
  color: ${colors.textPrimary};
  font-size: 13px;
  vertical-align: middle;
  white-space: nowrap;
}

.branch-punch-table tbody tr:hover td {
  background: ${colors.hover};
}

.branch-punch-table th:first-child,
.branch-punch-table td:first-child {
  position: sticky;
  left: 0;
  min-width: 220px;
  padding-right: 18px;
  border-right: 1px solid ${colors.border};
}

.branch-punch-table thead th:first-child {
  z-index: 5;
  background: ${colors.infoBackground || colors.surfaceMuted};
}

.branch-punch-table tbody td:first-child {
  z-index: 2;
  background: ${colors.surface};
}

.branch-punch-table tbody tr:hover td:first-child {
  background: ${colors.hover};
}

.branch-punch-table th:nth-child(2),
.branch-punch-table td:nth-child(2) {
  min-width: 205px;
  padding-right: 18px;
  border-right: 1px solid ${colors.border};
}

.branch-punch-table th:nth-child(3),
.branch-punch-table td:nth-child(3) {
  min-width: 145px;
  border-right: 1px solid ${colors.border};
}

.branch-punch-table .branch-date-column {
  min-width: 145px;
  text-align: left;
}

.branch-punch-table .branch-date-column div {
  line-height: 1.35;
}

.branch-punch-table .branch-date-column small {
  display: block;
  margin-top: 2px;
  color: ${colors.textSecondary};
  font-size: 12px;
  font-weight: 400;
}

.branch-table-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  white-space: nowrap;
}

.branch-table-heading-actions {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

.branch-table-heading svg {
  color: ${colors.textSecondary};
  cursor: pointer;
  flex-shrink: 0;
}

.branch-table-filter-icon {
  padding-left: 8px;
  border-left: 1px solid ${colors.border};
}

.branch-employee-name {
  font-weight: 600;
  color: ${colors.textPrimary};
}

.branch-employee-code,
.branch-department {
  display: block;
  margin-top: 3px;
  color: ${colors.textSecondary};
  font-size: 12px;
}

.branch-working-hours {
  font-weight: 600;
  color: ${colors.textPrimary};
}

.branch-working-hours-alert {
  background: #fffbeb !important;
  color: #b45309 !important;
  font-weight: 600;
}

.branch-working-hours-inner {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.branch-no-data {
  padding: 55px 20px !important;
  text-align: center !important;
  color: ${colors.textSecondary} !important;
}

.branch-punch-footer {
  display: flex;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 10px;
  padding: 12px 20px;
  border-top: 1px solid ${colors.border};
  color: ${colors.textSecondary};
  font-size: 12px;
}

@media (max-width: 768px) {
  .branch-punch-header {
    align-items: stretch;
    flex-direction: column;
    margin-bottom: 12px;
  }

  .branch-punch-title {
    font-size: 20px;
  }

  .branch-punch-header-actions {
    width: 100%;
  }

  .branch-punch-export-btn {
    flex: 1;
    padding: 0 12px;
    font-size: 12px;
  }

  .branch-punch-filter-card {
    margin-bottom: 12px;
  }

  .branch-punch-toolbar {
    padding: 12px 16px;
  }

  .branch-punch-filters {
    width: 100%;
    flex-wrap: wrap;
    align-items: stretch;
    flex-direction: column;
  }

  .branch-punch-date {
    width: 100%;
    justify-content: space-between;
  }

  .branch-punch-select,
  .branch-punch-search-box,
  .branch-punch-primary {
    width: 100%;
    max-width: 100%;
  }
}

@media print {
  body * {
    visibility: hidden;
  }

  .branch-punch-header,
  .branch-punch-header .branch-punch-title,
  .branch-punch-table-card,
  .branch-punch-table-card * {
    visibility: visible;
  }

  .branch-punch-header-actions,
  .branch-punch-filter-card {
    display: none !important;
  }

  .branch-punch-table-card {
    position: static;
    width: 100%;
    border: 0;
    box-shadow: none;
  }

  .branch-punch-table-wrapper {
    max-height: none;
    overflow: visible;
  }
}
`;

const employees = [
  {
    name: "GUNASEKARAN P",
    code: "1506",
    role: "Steward",
    department: "F&B Service",
    branch: "Hotel Devi",
  },
  {
    name: "KUMAR R",
    code: "1507",
    role: "Commis I",
    department: "F&B Production",
    branch: "Hotel Devi",
  },
  {
    name: "MANIRAJA D",
    code: "1508",
    role: "Floor Supervisor",
    department: "F&B Service",
    branch: "Hotel Devi",
  },
  {
    name: "SASI KUMAR D",
    code: "1509",
    role: "Cashier",
    department: "F&B Service",
    branch: "Hotel Devi",
  },
  {
    name: "SELVARAJ N",
    code: "1511",
    role: "Butchery",
    department: "F&B Production",
    branch: "Hotel Devi",
  },
];

const buildDatesInRange = (from, to) => {
  if (!from || !to || from > to) return [];

  const dates = [];
  const current = new Date(`${from}T12:00:00`);
  const end = new Date(`${to}T12:00:00`);

  while (current <= end && dates.length < 93) {
    const year = current.getFullYear();
    const month = String(current.getMonth() + 1).padStart(2, "0");
    const day = String(current.getDate()).padStart(2, "0");

    dates.push({
      iso: `${year}-${month}-${day}`,
      date: `${day}-${month}-${year}`,
      day: current.toLocaleDateString("en-US", { weekday: "long" }),
    });

    current.setDate(current.getDate() + 1);
  }

  return dates;
};

const getHoursForEmployeeDate = (code, dayIndex) => {
  const seed = Number(code) + dayIndex * 7;
  if (seed % 11 === 0) return "0h 0m";
  if (seed % 6 === 0) return "7h 29m";
  const hours = 8 + (seed % 5);
  const mins = (seed * 13) % 60;
  return `${hours}h ${mins}m`;
};

const isUnderHours = (value) => {
  if (!value || value === "-") return false;
  if (value === "0h 0m") return true;
  const match = value.match(/^(\d+)h\s+(\d+)m$/);
  if (!match) return false;
  const totalMins = Number(match[1]) * 60 + Number(match[2]);
  return totalMins < 8 * 60;
};

export default function BranchWisePunchReportPage() {
  const [fromDate, setFromDate] = useState("2026-11-01");
  const [toDate, setToDate] = useState("2026-11-27");
  const [branch, setBranch] = useState("All branches selected");
  const [searchTerm, setSearchTerm] = useState("");
  const [appliedFilters, setAppliedFilters] = useState({
    fromDate: "2026-11-01",
    toDate: "2026-11-27",
    branch: "All branches selected",
    searchTerm: "",
  });

  const reportDates = useMemo(
    () => buildDatesInRange(appliedFilters.fromDate, appliedFilters.toDate),
    [appliedFilters.fromDate, appliedFilters.toDate],
  );

  const filteredEmployees = useMemo(() => {
    return employees.filter((employee) => {
      const q = appliedFilters.searchTerm.trim().toLowerCase();
      const matchesSearch =
        !q ||
        employee.name.toLowerCase().includes(q) ||
        employee.code.toLowerCase().includes(q) ||
        employee.role.toLowerCase().includes(q) ||
        employee.department.toLowerCase().includes(q);

      const matchesBranch =
        appliedFilters.branch === "All branches selected" ||
        employee.branch === appliedFilters.branch;

      return matchesSearch && matchesBranch;
    });
  }, [appliedFilters]);

  const handleSearch = () => {
    if (!fromDate || !toDate || fromDate > toDate) {
      window.alert("Please select a valid date range.");
      return;
    }

    setAppliedFilters({ fromDate, toDate, branch, searchTerm });
  };

  const handleExcelExport = () => {
    const headers = [
      "Employee",
      "Employee Code",
      "Roles",
      "Department",
      "Branch",
      ...reportDates.map((date) => `${date.date} (${date.day})`),
    ];

    const rows = filteredEmployees.map((employee) => [
      employee.name,
      employee.code,
      employee.role,
      employee.department,
      employee.branch,
      ...reportDates.map((date, index) =>
        getHoursForEmployeeDate(employee.code, index),
      ),
    ]);

    const csv = [headers, ...rows]
      .map((row) =>
        row.map((value) => `"${String(value).replace(/"/g, '""')}"`).join(","),
      )
      .join("\n");

    const blob = new Blob(["\uFEFF" + csv], {
      type: "text/csv;charset=utf-8;",
    });

    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");

    link.href = url;
    link.download = "Branch_Wise_Punch_Report.csv";
    link.click();

    URL.revokeObjectURL(url);
  };

  return (
    <>
      <style>{styles}</style>
      <ReportTableStyles />

      <div className="branch-punch-page">
        <div className="branch-punch-header">
          <h1 className="branch-punch-title">Branch Wise Punch Report</h1>

          <div className="branch-punch-header-actions">
            <button
              type="button"
              className="branch-punch-export-btn"
              onClick={handleExcelExport}
            >
              <Download size={16} />
              <span>Export Excel</span>
            </button>

            <button
              type="button"
              className="branch-punch-export-btn"
              onClick={() => window.print()}
            >
              <FileText size={16} />
              <span>Export PDF</span>
            </button>
          </div>
        </div>

        <section className="branch-punch-filter-card">
          <div className="branch-punch-toolbar">
            <div className="branch-punch-filters">
              <div className="branch-punch-date">
                <CalendarDays size={17} />

                <input
                  type="date"
                  value={fromDate}
                  onChange={(e) => setFromDate(e.target.value)}
                />

                <span>→</span>

                <input
                  type="date"
                  value={toDate}
                  onChange={(e) => setToDate(e.target.value)}
                />
              </div>

              <select
                className="branch-punch-select"
                value={branch}
                onChange={(e) => setBranch(e.target.value)}
              >
                <option>All branches selected</option>
                <option>Hotel Devi</option>
                <option>Chennai</option>
                <option>Hyderabad</option>
                <option>Head Office</option>
              </select>

              <div className="branch-punch-search-box">
                <Search size={16} />

                <input
                  type="text"
                  placeholder="Search employee name or ID..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") handleSearch();
                  }}
                />
              </div>

              <button
                type="button"
                className="branch-punch-btn branch-punch-primary"
                onClick={handleSearch}
              >
                Search
              </button>
            </div>
          </div>
        </section>

        <section className="branch-punch-table-card">
          <div className="branch-punch-table-wrapper">
            <table className="branch-punch-table">
              <thead>
                <tr>
                  <th>
                    <div className="branch-table-heading">
                      <span>Employee</span>
                      <div className="branch-table-heading-actions">
                        <ArrowUpDown size={15} />
                        <span className="branch-table-filter-icon">
                          <SlidersHorizontal size={14} />
                        </span>
                      </div>
                    </div>
                  </th>

                  <th>
                    <div className="branch-table-heading">
                      <span>Roles</span>
                      <div className="branch-table-heading-actions">
                        <ArrowUpDown size={15} />
                        <span className="branch-table-filter-icon">
                          <SlidersHorizontal size={14} />
                        </span>
                      </div>
                    </div>
                  </th>

                  <th>
                    <div className="branch-table-heading">
                      <span>Branch</span>
                      <div className="branch-table-heading-actions">
                        <ArrowUpDown size={15} />
                        <span className="branch-table-filter-icon">
                          <SlidersHorizontal size={14} />
                        </span>
                      </div>
                    </div>
                  </th>

                  {reportDates.map((date) => (
                    <th key={date.iso} className="branch-date-column">
                      <div>
                        {date.date}
                        <small>{date.day}</small>
                      </div>
                    </th>
                  ))}
                </tr>
              </thead>

              <tbody>
                {filteredEmployees.length > 0 ? (
                  filteredEmployees.map((employee) => (
                    <tr key={employee.code}>
                      <td>
                        <div className="branch-employee-name">
                          {employee.name}
                        </div>

                        <span className="branch-employee-code">
                          {employee.code}
                        </span>
                      </td>

                      <td>
                        <div className="branch-employee-name">
                          {employee.role}
                        </div>

                        <span className="branch-department">
                          {employee.department}
                        </span>
                      </td>

                      <td>{employee.branch}</td>

                      {reportDates.map((date, index) => {
                        const val = getHoursForEmployeeDate(
                          employee.code,
                          index,
                        );
                        const alertCell = isUnderHours(val);

                        return (
                          <td
                            key={date.iso}
                            className={
                              alertCell
                                ? "branch-working-hours-alert"
                                : "branch-working-hours"
                            }
                          >
                            <span className="branch-working-hours-inner">
                              <span>{val}</span>
                              {alertCell && (
                                <AlertTriangle size={14} color="#d97706" />
                              )}
                            </span>
                          </td>
                        );
                      })}
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td
                      colSpan={3 + reportDates.length}
                      className="branch-no-data"
                    >
                      No Data Found
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          <div className="branch-punch-footer">
            <span>Showing {filteredEmployees.length} employees</span>
            <span>
              Dates: {reportDates.length} days ({fromDate} → {toDate})
            </span>
          </div>
        </section>
      </div>
    </>
  );
}
