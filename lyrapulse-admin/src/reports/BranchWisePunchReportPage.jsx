import { useState } from "react";

import {
  CalendarDays,
  ArrowUpDown,
  SlidersHorizontal,
  FileSpreadsheet,
  ChevronDown,
  Search,
} from "lucide-react";

import { colors } from "../theme/colors";
import { typography } from "../theme/typography";
import { ReportTableStyles } from './ReportTableStyles'

const styles = `
.branch-punch-page {
  width: 100%;
  min-height: 100%;
  padding: 18px;
  background: ${colors.background};
  color: ${colors.textPrimary};
  font-family: ${typography.fontFamily};
}

.branch-punch-card {
  width: 100%;
  background: ${colors.surface};
  border: 1px solid ${colors.border};
  border-radius: 12px;
  overflow: hidden;
}

.branch-punch-title {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 20px 24px;
  font-size: 21px;
  font-weight: 650;
  color: ${colors.textPrimary};
}

.branch-beta {
  padding: 5px 12px;
  border-radius: 20px;
  background: ${colors.infoBackground};
  color: ${colors.primaryBlue};
  font-size: 12px;
  font-weight: 600;
}

.branch-punch-toolbar {
  display: flex;
  flex-direction: column;
  gap: 18px;
  padding: 18px 24px 20px;
}

.branch-punch-filters {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 18px;
}

.branch-punch-date {
  height: 44px;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 12px;
  border: 1px solid ${colors.border};
  border-radius: 8px;
  background: ${colors.surface};
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
  font-size: 14px;
}

.branch-punch-date span {
  color: ${colors.textSecondary};
}

.branch-punch-select {
  height: 44px;
  min-width: 250px;
  padding: 0 14px;
  border: 1px solid ${colors.border};
  border-radius: 8px;
  outline: none;
  color: ${colors.textPrimary};
  background: ${colors.surface};
  font-family: ${typography.fontFamily};
  font-size: 14px;
  cursor: pointer;
}

.branch-punch-select:focus {
  border-color: ${colors.primaryBlue};
  box-shadow: 0 0 0 3px ${colors.focusSubtle};
}

.branch-punch-btn {
  min-height: 44px;
  padding: 0 18px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border-radius: 8px;
  font-family: ${typography.fontFamily};
  font-size: 14px;
  font-weight: 600;
  white-space: nowrap;
  cursor: pointer;
  transition: 0.2s;
}

.branch-punch-primary {
  min-width: 116px;
  border: none;
  color: ${colors.surface};
  background: linear-gradient(90deg, ${colors.primary}, ${colors.secondary});
}

.branch-punch-primary:hover {
  opacity: 0.9;
  box-shadow: 0 5px 14px ${colors.selection};
}

.branch-punch-outline {
  border: 1px solid ${colors.border};
  color: ${colors.textPrimary};
  background: ${colors.surface};
}

.branch-punch-outline:hover {
  background: ${colors.hover};
  border-color: ${colors.primaryBlue};
}

.branch-punch-actions {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  flex-wrap: wrap;
  gap: 14px;
}

.branch-punch-dropdown {
  position: relative;
}

.branch-punch-dropdown-menu {
  position: absolute;
  top: 49px;
  right: 0;
  z-index: 20;
  min-width: 190px;
  padding: 5px;
  border: 1px solid ${colors.border};
  border-radius: 8px;
  background: ${colors.surface};
  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.12);
}

.branch-punch-dropdown-menu button {
  display: block;
  width: 100%;
  padding: 11px 12px;
  border: none;
  border-radius: 5px;
  background: transparent;
  color: ${colors.textPrimary};
  font-family: ${typography.fontFamily};
  text-align: left;
  cursor: pointer;
}

.branch-punch-dropdown-menu button:hover {
  background: ${colors.hover};
}

.branch-punch-search {
  width: 100%;
  display: flex;
  justify-content: flex-end;
  padding: 0 24px 14px;
}

.branch-punch-search-box {
  width: 270px;
  height: 39px;
  display: flex;
  align-items: center;
  gap: 9px;
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
  border: none;
  outline: none;
  color: ${colors.textPrimary};
  background: transparent;
  font-family: ${typography.fontFamily};
  font-size: 13px;
}

.branch-punch-table-wrapper {
  width: 100%;
  overflow-x: auto;
  border-top: 1px solid ${colors.border};
}

.branch-punch-table {
  width: 100%;
  min-width: 1150px;
  border-collapse: collapse;
  text-align: left;
}

.branch-punch-table thead {
  background: ${colors.infoBackground};
}

.branch-punch-table th {
  height: 68px;
  padding: 12px 17px;
  border-bottom: 1px solid ${colors.border};
  color: ${colors.primary};
  font-size: 14px;
  font-weight: 600;
  white-space: nowrap;
}

.branch-punch-table td {
  height: 76px;
  padding: 13px 17px;
  border-bottom: 1px solid ${colors.border};
  color: ${colors.textPrimary};
  font-size: 14px;
}

.branch-punch-table tbody tr:hover {
  background: ${colors.surfaceMuted};
}

.branch-punch-table th:first-child,
.branch-punch-table td:first-child {
  min-width: 220px;
}

.branch-punch-table th:nth-child(2),
.branch-punch-table td:nth-child(2) {
  min-width: 185px;
}

.branch-punch-table th:nth-child(3),
.branch-punch-table td:nth-child(3) {
  min-width: 140px;
}

.branch-punch-table th:nth-child(4),
.branch-punch-table td:nth-child(4) {
  min-width: 165px;
  border-left: 1px solid ${colors.border};
}

.branch-punch-table .branch-date-column {
  min-width: 155px;
  text-align: center;
}

.branch-punch-table .branch-date-column div {
  line-height: 1.5;
}

.branch-table-heading {
  display: flex;
  align-items: center;
  gap: 11px;
}

.branch-table-heading svg {
  color: ${colors.textSecondary};
  cursor: pointer;
  flex-shrink: 0;
}

.branch-employee-name {
  font-weight: 600;
  color: ${colors.textPrimary};
}

.branch-employee-code,
.branch-department {
  display: block;
  margin-top: 4px;
  color: ${colors.textSecondary};
  font-size: 13px;
}

.branch-working-hours {
  font-weight: 650;
  text-align: center;
  color: ${colors.primary};
}

.branch-no-data {
  padding: 65px 20px !important;
  text-align: center;
  color: ${colors.textSecondary} !important;
}

.branch-punch-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 14px 20px;
  color: ${colors.textSecondary};
  font-size: 13px;
}

@media (max-width: 1000px) {
  .branch-punch-actions {
    justify-content: flex-start;
  }
}

@media (max-width: 768px) {
  .branch-punch-page {
    padding: 10px;
  }

  .branch-punch-toolbar {
    padding: 16px;
  }

  .branch-punch-filters {
    align-items: stretch;
    flex-direction: column;
  }

  .branch-punch-date {
    max-width: 100%;
  }

  .branch-punch-select,
  .branch-punch-primary {
    width: 100%;
  }

  .branch-punch-actions {
    justify-content: flex-start;
  }

  .branch-punch-search {
    padding: 0 16px 14px;
  }

  .branch-punch-search-box {
    width: 100%;
  }
}
`;

const employees = [
  {
    name: "ANBALAGAN S",
    code: "1501",
    role: "Operation Executive",
    department: "Operation",
    branch: "Hotel Devi",
    total: "216h 49m",
    days: ["9h 29m", "9h 47m", "10h 28m"],
  },
  {
    name: "GANESAN S",
    code: "1502",
    role: "Driver",
    department: "FO",
    branch: "Hotel Devi",
    total: "320h 5m",
    days: ["16h 11m", "11h 58m", "13h 0m"],
  },
  {
    name: "AARUMUGAM T",
    code: "1503",
    role: "Operation Executive",
    department: "Operation",
    branch: "Hotel Devi",
    total: "258h 13m",
    days: ["10h 17m", "11h 46m", "11h 39m"],
  },
  {
    name: "SELVAM V",
    code: "1504",
    role: "General Technician",
    department: "Maintenance",
    branch: "Hotel Devi",
    total: "312h 42m",
    days: ["13h 12m", "10h 36m", "11h 7m"],
  },
  {
    name: "SURESH K",
    code: "1505",
    role: "Supervisor",
    department: "Production",
    branch: "Chennai",
    total: "285h 20m",
    days: ["9h 15m", "10h 30m", "8h 45m"],
  },
];

const reportDates = [
  { date: "01-10-2026", day: "Thursday" },
  { date: "02-10-2026", day: "Friday" },
  { date: "03-10-2026", day: "Saturday" },
];

export default function BranchWisePunchReportPage() {
  const [fromDate, setFromDate] = useState("2026-10-01");
  const [toDate, setToDate] = useState("2026-10-29");
  const [branch, setBranch] = useState("All branches selected");
  const [searchTerm, setSearchTerm] = useState("");
  const [showAttendance, setShowAttendance] = useState(false);
  const [attendanceType, setAttendanceType] = useState("Attendance Report");

  const filteredEmployees = employees.filter((employee) => {
    const matchesSearch =
      employee.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      employee.code.includes(searchTerm);

    const matchesBranch =
      branch === "All branches selected" || employee.branch === branch;

    return matchesSearch && matchesBranch;
  });

  const handleExcelExport = () => {
    const headers = [
      "Employee",
      "Employee Code",
      "Roles",
      "Department",
      "Branch",
      "Total Working Hours",
      ...reportDates.map((date) => date.date),
    ];

    const rows = filteredEmployees.map((employee) => [
      employee.name,
      employee.code,
      employee.role,
      employee.department,
      employee.branch,
      employee.total,
      ...employee.days,
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
        <div className="branch-punch-card">
          <div className="branch-punch-title">
            Branch Wise Punch Report
            <span className="branch-beta">Beta</span>
          </div>

          <div className="branch-punch-toolbar">
            <div className="branch-punch-filters">
              <div className="branch-punch-date">
                <CalendarDays size={18} />

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

              <button className="branch-punch-btn branch-punch-primary">
                Search
              </button>
            </div>

            <div className="branch-punch-actions">
              <button
                className="branch-punch-btn branch-punch-outline"
                onClick={handleExcelExport}
              >
                <FileSpreadsheet size={17} />
                Export Excel
              </button>

              <button
                className="branch-punch-btn branch-punch-outline"
                onClick={handleExcelExport}
              >
                Branch Wise Punch Report
              </button>

              <div className="branch-punch-dropdown">
                <button
                  className="branch-punch-btn branch-punch-outline"
                  onClick={() => setShowAttendance(!showAttendance)}
                >
                  {attendanceType}
                  <ChevronDown size={17} />
                </button>

                {showAttendance && (
                  <div className="branch-punch-dropdown-menu">
                    {["Attendance Report", "Punch Report"].map((item) => (
                      <button
                        key={item}
                        onClick={() => {
                          setAttendanceType(item);
                          setShowAttendance(false);
                        }}
                      >
                        {item}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>

          <div className="branch-punch-search">
            <div className="branch-punch-search-box">
              <Search size={17} />

              <input
                type="text"
                placeholder="Search employee name or ID..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>

          <div className="branch-punch-table-wrapper">
            <table className="branch-punch-table">
              <thead>
                <tr>
                  <th>
                    <div className="branch-table-heading">
                      Employee
                      <ArrowUpDown size={17} />
                      <SlidersHorizontal size={17} />
                    </div>
                  </th>

                  <th>
                    <div className="branch-table-heading">
                      Roles
                      <ArrowUpDown size={17} />
                      <SlidersHorizontal size={17} />
                    </div>
                  </th>

                  <th>
                    <div className="branch-table-heading">
                      Branch
                      <ArrowUpDown size={17} />
                      <SlidersHorizontal size={17} />
                    </div>
                  </th>

                  <th>
                    <div className="branch-table-heading">
                      Total
                      <br />
                      Working Hours
                      <ArrowUpDown size={17} />
                    </div>
                  </th>

                  {reportDates.map((date) => (
                    <th key={date.date} className="branch-date-column">
                      <div>
                        {date.date}
                        <br />
                        {date.day}
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
                        {employee.role}

                        <span className="branch-department">
                          {employee.department}
                        </span>
                      </td>

                      <td>{employee.branch}</td>

                      <td>{employee.total}</td>

                      {employee.days.map((day, index) => (
                        <td key={index} className="branch-working-hours">
                          {day}
                        </td>
                      ))}
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td
                      colSpan={4 + reportDates.length}
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
          </div>
        </div>
      </div>
    </>
  );
}
