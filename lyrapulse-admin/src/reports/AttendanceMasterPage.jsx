import { useState } from "react";
import {
  CalendarDays,
  ChevronDown,
  ChevronUp,
  ChevronsUpDown,
} from "lucide-react";
import { colors, palette } from "../theme/colors";
import { typography } from "../theme/typography";

const attendanceData = [
  {
    id: "1615",
    employee: "SARAVANAN",
    role: "Floor Supervisor",
    department: "F&B Production",
    date: "2026-10-01",
    day: "Thursday",
    firstPunch: "-",
    lastPunch: "-",
    workingHours: "8h",
    breakHours: "-",
    status: "FD",
  },
  {
    id: "1614",
    employee: "MOHAN TOMATA",
    role: "Commis I",
    department: "F&B Production",
    date: "2026-10-01",
    day: "Thursday",
    firstPunch: "-",
    lastPunch: "-",
    workingHours: "8h",
    breakHours: "-",
    status: "FD",
  },
  {
    id: "1613",
    employee: "LOKESH KUMAR",
    role: "Commis II",
    department: "F&B Production",
    date: "2026-10-01",
    day: "Thursday",
    firstPunch: "-",
    lastPunch: "-",
    workingHours: "8h",
    breakHours: "-",
    status: "FD",
  },
  {
    id: "1612",
    employee: "KAVIPRIYA M",
    role: "Store Asst",
    department: "F&B Production",
    date: "2026-10-01",
    day: "Thursday",
    firstPunch: "08:08 AM",
    lastPunch: "05:44 PM",
    workingHours: "9h 35m",
    breakHours: "-",
    status: "FD",
  },
  {
    id: "1611",
    employee: "SEETHA M",
    role: "Store Asst",
    department: "F&B Production",
    date: "2026-10-01",
    day: "Thursday",
    firstPunch: "07:58 AM",
    lastPunch: "05:45 PM",
    workingHours: "9h 46m",
    breakHours: "-",
    status: "FD",
  },
];

export default function AttendanceMasterPage() {
  const [startDate, setStartDate] = useState("2026-10-01");
  const [endDate, setEndDate] = useState("2026-10-22");
  const [department, setDepartment] = useState("");
  const [searchText, setSearchText] = useState("");

  const [filters, setFilters] = useState({
    startDate: "2026-10-01",
    endDate: "2026-10-22",
    department: "",
    search: "",
  });

  const [sort, setSort] = useState({
    key: "employee",
    direction: "asc",
  });

  const rows = attendanceData
    .filter((row) => {
      const matchesDate =
        row.date >= filters.startDate && row.date <= filters.endDate;

      const matchesDepartment =
        !filters.department || row.department === filters.department;

      const term = filters.search.toLowerCase();

      const matchesSearch =
        !term ||
        row.employee.toLowerCase().includes(term) ||
        row.id.toLowerCase().includes(term) ||
        row.role.toLowerCase().includes(term) ||
        row.department.toLowerCase().includes(term);

      return matchesDate && matchesDepartment && matchesSearch;
    })
    .sort((a, b) => {
      const first = String(a[sort.key] ?? "").toLowerCase();
      const second = String(b[sort.key] ?? "").toLowerCase();

      const result = first.localeCompare(second, undefined, {
        numeric: true,
      });

      return sort.direction === "asc" ? result : -result;
    });

  const handleSearch = () => {
    if (startDate > endDate) {
      window.alert("Start date cannot be after end date.");
      return;
    }

    setFilters({
      startDate,
      endDate,
      department,
      search: searchText.trim(),
    });
  };

  const handleSort = (key) => {
    setSort((previous) => ({
      key,
      direction:
        previous.key === key && previous.direction === "asc" ? "desc" : "asc",
    }));
  };

  const exportExcel = () => {
    const headers = [
      "Employee ID",
      "Employee",
      "Role",
      "Department",
      "Date",
      "Day",
      "First Punch",
      "Last Punch",
      "Working Hours",
      "Break Hours",
      "Status",
    ];

    const csv = [
      headers,
      ...rows.map((row) => [
        row.id,
        row.employee,
        row.role,
        row.department,
        row.date,
        row.day,
        row.firstPunch,
        row.lastPunch,
        row.workingHours,
        row.breakHours,
        row.status,
      ]),
    ]
      .map((line) =>
        line.map((value) => `"${String(value).replace(/"/g, '""')}"`).join(","),
      )
      .join("\r\n");

    const blob = new Blob(["\uFEFF" + csv], {
      type: "text/csv;charset=utf-8;",
    });

    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");

    link.href = url;
    link.download = "Attendance_Master.csv";

    document.body.appendChild(link);
    link.click();
    link.remove();

    URL.revokeObjectURL(url);
  };

  const SortButton = ({ column, children }) => (
    <button
      type="button"
      className="am-sort"
      onClick={() => handleSort(column)}
    >
      <span>{children}</span>

      {sort.key === column ? (
        sort.direction === "asc" ? (
          <ChevronUp size={17} />
        ) : (
          <ChevronDown size={17} />
        )
      ) : (
        <ChevronsUpDown size={17} />
      )}
    </button>
  );

  return (
    <div className="am-page">
      <style>{`
        .am-page {
          width: 100%;
          min-width: 0;
          padding: 14px 6px;
          color: ${colors.textPrimary};
          font-family: ${typography.fontFamily};
          font-size: ${typography.body2.fontSize};
          line-height: ${typography.body2.lineHeight};
        }

        .am-page * {
          box-sizing: border-box;
        }

        .am-card {
          width: 100%;
          overflow: hidden;
          background: ${colors.surface};
          border: 1px solid ${colors.border};
          border-radius: 16px;
          box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
        }

        .am-title {
          padding: 22px 29px 26px;
          margin: 0;
          font-size: ${typography.h5.fontSize};
          font-weight: ${typography.h5.fontWeight};
          letter-spacing: ${typography.h5.letterSpacing};
          line-height: ${typography.h5.lineHeight};
          color: ${colors.textPrimary};
        }

        .am-toolbar {
          display: flex;
          align-items: center;
          justify-content: space-between;
          flex-wrap: wrap;
          gap: 18px;
          padding: 20px 29px 24px;
        }

        .am-filters,
        .am-exports {
          display: flex;
          align-items: center;
          flex-wrap: wrap;
          gap: 12px;
        }

        .am-date {
          width: 375px;
          max-width: 100%;
          height: 48px;
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 0 12px;
          border: 1px solid ${colors.border};
          border-radius: 8px;
          background: ${colors.surface};
        }

        .am-date:focus-within {
          border-color: ${colors.primaryBlue};
          box-shadow: 0 0 0 3px ${colors.focusSubtle};
        }

        .am-date svg {
          flex-shrink: 0;
          color: ${colors.textSecondary};
        }

        .am-date input {
          width: 46%;
          min-width: 0;
          border: 0;
          outline: none;
          color: ${colors.textPrimary};
          background: transparent;
          font-family: inherit;
          font-size: ${typography.body2.fontSize};
        }

        .am-arrow {
          color: ${colors.disabled};
        }

        .am-department {
          position: relative;
          width: 230px;
          height: 48px;
        }

        .am-department select {
          width: 100%;
          height: 100%;
          padding: 0 40px 0 13px;
          appearance: none;
          border: 1px solid ${colors.border};
          border-radius: 8px;
          background: ${colors.surface};
          color: ${colors.textSecondary};
          font-family: inherit;
          font-size: ${typography.body2.fontSize};
          outline: none;
        }

        .am-department select:focus {
          border-color: ${colors.primaryBlue};
          box-shadow: 0 0 0 3px ${colors.focusSubtle};
        }

        .am-department svg {
          position: absolute;
          right: 12px;
          top: 14px;
          pointer-events: none;
          color: ${colors.textSecondary};
        }

        .am-button {
          min-height: 40px;
          padding: 0 16px;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          border: 1px solid ${colors.border};
          border-radius: 8px;
          background: ${colors.surface};
          color: ${colors.textPrimary};
          font-family: inherit;
          font-size: ${typography.button.fontSize};
          font-weight: ${typography.button.fontWeight};
          line-height: ${typography.button.lineHeight};
          text-transform: none;
          white-space: nowrap;
          cursor: pointer;
          transition: background-color 140ms ease, border-color 140ms ease,
            box-shadow 140ms ease;
        }

        .am-button:focus-visible,
        .am-sort:focus-visible {
          outline: 3px solid ${colors.focusRing};
          outline-offset: 2px;
        }

        .am-search {
          min-width: 110px;
          border-color: transparent;
          background: ${palette.lyra.primaryGradient};
          color: ${colors.surface};
          font-weight: ${typography.button.fontWeight};
        }

        .am-search:hover {
          background: ${palette.lyra.primaryGradient};
          box-shadow: ${palette.lyra.actionShadow};
        }

        .am-button:hover:not(.am-search) {
          background: ${colors.hover};
          border-color: ${colors.borderStrong};
        }

        .am-search-input {
          height: 40px;
          width: 190px;
          max-width: 100%;
          padding: 0 12px;
          border: 1px solid ${colors.border};
          border-radius: 8px;
          background: ${colors.surface};
          color: ${colors.textPrimary};
          font-family: inherit;
          font-size: ${typography.body2.fontSize};
          outline: none;
        }

        .am-search-input::placeholder {
          color: ${colors.textSecondary};
        }

        .am-search-input:focus {
          border-color: ${colors.primaryBlue};
          box-shadow: 0 0 0 3px ${colors.focusSubtle};
        }

        .am-table-wrap {
          width: 100%;
          max-height: 68vh;
          overflow: auto;
          border-top: 1px solid ${colors.border};
        }

        .am-table {
          width: 100%;
          min-width: 1200px;
          border-collapse: separate;
          border-spacing: 0;
          font-family: inherit;
          font-size: ${typography.body2.fontSize};
          line-height: ${typography.body2.lineHeight};
        }

        .am-table th {
          position: sticky;
          top: 0;
          z-index: 2;
          height: 76px;
          padding: 14px 18px;
          background: ${colors.surfaceMuted};
          color: ${colors.textSecondary};
          text-align: left;
          font-family: inherit;
          font-size: ${typography.caption.fontSize};
          font-weight: ${typography.overline.fontWeight};
          letter-spacing: 0.04em;
          text-transform: uppercase;
          white-space: nowrap;
          line-height: ${typography.caption.lineHeight};
          border-bottom: 1px solid ${colors.border};
        }

        .am-table td {
          height: 76px;
          padding: 15px 18px;
          color: ${colors.textPrimary};
          white-space: nowrap;
          background: ${colors.surface};
          border-bottom: 1px solid ${colors.border};
          font-family: inherit;
          font-size: ${typography.body2.fontSize};
          line-height: ${typography.body2.lineHeight};
        }

        .am-table tbody tr:hover td {
          background: ${colors.hover};
        }

        .am-table .am-employee {
          min-width: 220px;
          border-right: 1px solid ${colors.border};
        }

        .am-table .am-role {
          min-width: 210px;
          border-right: 1px solid ${colors.border};
        }

        .am-sort {
          width: 100%;
          padding: 0;
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 10px;
          border: 0;
          background: transparent;
          color: inherit;
          font: inherit;
          text-align: left;
          cursor: pointer;
        }

        .am-sort svg {
          flex-shrink: 0;
          color: ${colors.textSecondary};
        }

        .am-employee-name {
          font-size: ${typography.subtitle2.fontSize};
          font-weight: ${typography.subtitle2.fontWeight};
          line-height: ${typography.subtitle2.lineHeight};
          color: ${colors.textPrimary};
        }

        .am-subtext {
          margin-top: 4px;
          color: ${colors.textSecondary};
          font-size: ${typography.caption.fontSize};
          line-height: ${typography.caption.lineHeight};
        }

        .am-status {
          display: inline-flex;
          align-items: center;
          gap: 11px;
          text-decoration: underline;
          text-underline-offset: 2px;
        }

        .am-status-dot {
          width: 12px;
          height: 12px;
          border: 3px solid ${colors.primaryBlue};
          border-radius: 50%;
        }

        .am-empty {
          height: 100px !important;
          text-align: center;
          color: ${colors.textSecondary} !important;
        }

        .am-footer {
          padding: 14px 22px;
          color: ${colors.textSecondary};
          font-size: ${typography.caption.fontSize};
          line-height: ${typography.caption.lineHeight};
        }

        @media (max-width: 1100px) {
          .am-toolbar {
            align-items: flex-start;
            flex-direction: column;
          }

          .am-filters,
          .am-exports {
            gap: 10px;
          }
        }

        @media (max-width: 600px) {
          .am-title {
            padding: 18px 16px;
            font-size: ${typography.h6.fontSize};
            line-height: ${typography.h6.lineHeight};
          }

          .am-toolbar {
            padding: 14px 16px 18px;
          }

          .am-filters {
            width: 100%;
            flex-direction: column;
            align-items: stretch;
          }

          .am-date,
          .am-department {
            width: 100%;
          }

          .am-date {
            gap: 5px;
            padding: 0 8px;
          }

          .am-date input {
            font-size: ${typography.caption.fontSize};
          }

          .am-search {
            width: 100%;
          }

          .am-exports {
            width: 100%;
          }

          .am-button {
            flex: 1;
            padding: 0 12px;
          }

          .am-table {
            min-width: 1100px;
          }
        }

        @media print {
          body * {
            visibility: hidden;
          }

          .am-card,
          .am-card * {
            visibility: visible;
          }

          .am-card {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            border: 0;
          }

          .am-toolbar {
            display: none;
          }

          .am-table-wrap {
            max-height: none;
            overflow: visible;
          }

          .am-table {
            min-width: 0;
            font-size: 9px;
          }

          .am-table th {
            position: static;
            height: auto;
            padding: 6px 4px;
            print-color-adjust: exact;
          }

          .am-table td {
            height: auto;
            padding: 7px 4px;
          }

          .am-table .am-employee,
          .am-table .am-role {
            min-width: 0;
          }

          @page {
            size: landscape;
            margin: 10mm;
          }
        }
      `}</style>

      <section className="am-card">
        <h1 className="am-title">Attendance Master</h1>

        <div className="am-toolbar">
          <div className="am-filters">
            <div className="am-date">
              <CalendarDays size={18} />

              <input
                type="date"
                aria-label="Start date"
                value={startDate}
                max={endDate}
                onChange={(event) => setStartDate(event.target.value)}
              />

              <span className="am-arrow">→</span>

              <input
                type="date"
                aria-label="End date"
                value={endDate}
                min={startDate}
                onChange={(event) => setEndDate(event.target.value)}
              />
            </div>

            <div className="am-department">
              <select
                aria-label="Choose Department"
                value={department}
                onChange={(event) => setDepartment(event.target.value)}
              >
                <option value="">Choose Department</option>
                <option value="F&B Production">F&amp;B Production</option>
              </select>

              <ChevronDown size={19} />
            </div>

            <input
              type="text"
              className="am-search-input"
              placeholder="Search employee..."
              aria-label="Search employee"
              value={searchText}
              onChange={(event) => setSearchText(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter") handleSearch();
              }}
            />

            <button
              type="button"
              className="am-button am-search"
              onClick={handleSearch}
            >
              Search
            </button>
          </div>

          <div className="am-exports">
            <button type="button" className="am-button" onClick={exportExcel}>
              Export Excel
            </button>

            <button
              type="button"
              className="am-button"
              onClick={() => window.print()}
            >
              Export PDF
            </button>
          </div>
        </div>

        <div className="am-table-wrap">
          <table className="am-table">
            <thead>
              <tr>
                <th className="am-employee">
                  <SortButton column="employee">Employee</SortButton>
                </th>

                <th className="am-role">
                  <SortButton column="role">Roles</SortButton>
                </th>

                <th>
                  <SortButton column="date">Date</SortButton>
                </th>

                <th>Day</th>
                <th>First Punch</th>
                <th>Last Punch</th>

                <th>
                  Total
                  <br />
                  Working Hours
                </th>

                <th>
                  Total
                  <br />
                  Break Hours
                </th>

                <th>
                  <SortButton column="status">Status</SortButton>
                </th>
              </tr>
            </thead>

            <tbody>
              {rows.length > 0 ? (
                rows.map((row) => (
                  <tr key={`${row.id}-${row.date}`}>
                    <td className="am-employee">
                      <div className="am-employee-name">{row.employee}</div>
                      <div className="am-subtext">{row.id}</div>
                    </td>

                    <td className="am-role">
                      <div className="am-employee-name">{row.role}</div>
                      <div className="am-subtext">{row.department}</div>
                    </td>

                    <td>{row.date.split("-").reverse().join("-")}</td>

                    <td>{row.day}</td>
                    <td>{row.firstPunch}</td>
                    <td>{row.lastPunch}</td>
                    <td>{row.workingHours}</td>
                    <td>{row.breakHours}</td>

                    <td>
                      <span className="am-status">
                        {row.status}
                        {row.firstPunch === "-" && (
                          <span className="am-status-dot" />
                        )}
                      </span>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={9} className="am-empty">
                    No attendance records found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        <div className="am-footer">
          Showing {rows.length} attendance records
        </div>
      </section>
    </div>
  );
}
