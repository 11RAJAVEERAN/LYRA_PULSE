import { useMemo, useState } from "react";
import { ArrowDownUp, ChevronDown, Filter, Search } from "lucide-react";
import { colors, palette } from "../theme/colors";
import { typography } from "../theme/typography";

const initialRows = [
  {
    id: 1,
    name: "angel",
    employeeId: "119",
    role: "Operation Executive",
    department: "FO",
    branch: "Chennai",
    punches: {},
  },
  {
    id: 2,
    name: "madhavan",
    employeeId: "118",
    role: "Operation Executive",
    department: "FO",
    branch: "Chennai",
    punches: {},
  },
  {
    id: 3,
    name: "SARAVANAN",
    employeeId: "1615",
    role: "Floor Supervisor",
    department: "F&B Production",
    branch: "Chennai",
    punches: {
      "2026-10-01": "08:02 AM",
      "2026-10-02": "08:11 AM",
      "2026-10-05": "08:05 AM",
    },
  },
  {
    id: 4,
    name: "MOHAN TOMATA",
    employeeId: "1614",
    role: "Commis I",
    department: "F&B Production",
    branch: "Hyderabad",
    punches: {
      "2026-10-01": "08:10 AM",
      "2026-10-03": "08:04 AM",
    },
  },
];

const formatDate = (date) => {
  const [year, month, day] = date.split("-");
  return `${day}-${month}-${year}`;
};

const getDay = (date) =>
  new Date(`${date}T12:00:00`).toLocaleDateString("en-US", {
    weekday: "long",
  });

const getDates = (start, end) => {
  if (!start || !end || start > end) return [];

  const result = [];
  const date = new Date(`${start}T12:00:00`);
  const last = new Date(`${end}T12:00:00`);

  while (date <= last && result.length < 93) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");

    result.push(`${year}-${month}-${day}`);
    date.setDate(date.getDate() + 1);
  }

  return result;
};

function exportCSV(rows, dates) {
  const headers = [
    "Employee",
    "Employee ID",
    "Role",
    "Department",
    ...dates.map((date) => `${formatDate(date)} ${getDay(date)}`),
  ];

  const escapeCSV = (value) => `"${String(value ?? "-").replace(/"/g, '""')}"`;

  const csv = [
    headers,
    ...rows.map((row) => [
      row.name,
      row.employeeId,
      row.role,
      row.department,
      ...dates.map((date) => row.punches[date] || "-"),
    ]),
  ]
    .map((line) => line.map(escapeCSV).join(","))
    .join("\r\n");

  const blob = new Blob(["\uFEFF" + csv], {
    type: "text/csv;charset=utf-8;",
  });

  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");

  link.href = url;
  link.download = "daily-punch-report.csv";

  document.body.appendChild(link);
  link.click();
  link.remove();

  URL.revokeObjectURL(url);
}

export default function DailyPunchReportPage() {
  const [fromDate, setFromDate] = useState("2026-10-01");
  const [toDate, setToDate] = useState("2026-10-26");
  const [branch, setBranch] = useState("");
  const [searchTerm, setSearchTerm] = useState("");

  const [applied, setApplied] = useState({
    fromDate: "2026-10-01",
    toDate: "2026-10-26",
    branch: "",
    searchTerm: "",
  });

  const [sort, setSort] = useState({ key: "", direction: "asc" });

  const dates = useMemo(
    () => getDates(applied.fromDate, applied.toDate),
    [applied.fromDate, applied.toDate],
  );

  const rows = useMemo(() => {
    let result = initialRows.filter((row) => {
      const branchMatch = !applied.branch || row.branch === applied.branch;
      const q = applied.searchTerm.toLowerCase();

      const searchMatch =
        !q ||
        row.name.toLowerCase().includes(q) ||
        row.employeeId.includes(q) ||
        row.role.toLowerCase().includes(q) ||
        row.department.toLowerCase().includes(q);

      return branchMatch && searchMatch;
    });

    if (sort.key) {
      result = [...result].sort((a, b) => {
        const comparison = String(a[sort.key]).localeCompare(
          String(b[sort.key]),
          undefined,
          { numeric: true },
        );

        return sort.direction === "asc" ? comparison : -comparison;
      });
    }

    return result;
  }, [applied, sort]);

  const search = () => {
    if (!fromDate || !toDate || fromDate > toDate) {
      window.alert("Please select a valid date range.");
      return;
    }

    setApplied({ fromDate, toDate, branch, searchTerm });
  };

  const sortBy = (key) => {
    setSort((current) => ({
      key,
      direction:
        current.key === key && current.direction === "asc" ? "desc" : "asc",
    }));
  };

  const filterBy = () => {
    const value = window.prompt("Enter employee name, ID or role:", searchTerm);

    if (value !== null) {
      setSearchTerm(value);
      setApplied((current) => ({ ...current, searchTerm: value }));
    }
  };

  return (
    <div className="daily-punch-page">
      <style>{`
        .daily-punch-page {
          width: 100%;
          min-width: 0;
          padding: 8px;
          box-sizing: border-box;
          color: ${colors.textPrimary};
          font-family: ${typography.fontFamily};
          font-size: ${typography.body2.fontSize};
          line-height: ${typography.body2.lineHeight};
        }

        .daily-punch-page * {
          box-sizing: border-box;
        }

        .daily-punch-card {
          width: 100%;
          overflow: hidden;
          background: ${colors.surface};
          border: 1px solid ${colors.border};
          border-radius: 16px;
          box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
        }

        .daily-punch-title {
          margin: 0;
          padding: 23px 29px;
          color: ${colors.textPrimary};
          font-family: inherit;
          font-size: ${typography.h5.fontSize};
          line-height: ${typography.h5.lineHeight};
          letter-spacing: ${typography.h5.letterSpacing};
          font-weight: ${typography.h5.fontWeight};
        }

        .daily-punch-toolbar {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: 12px 24px;
          padding: 23px 29px 24px;
        }

        .daily-punch-date-range {
          display: flex;
          align-items: center;
          gap: 12px;
          height: 48px;
          padding: 0 12px;
          border: 1px solid ${colors.border};
          border-radius: 8px;
          background: ${colors.surface};
        }

        .daily-punch-date-range:focus-within {
          border-color: ${colors.primaryBlue};
          box-shadow: 0 0 0 3px ${colors.focusSubtle};
        }

        .daily-punch-date-range input {
          width: 132px;
          min-width: 0;
          border: 0;
          outline: 0;
          background: transparent;
          color: ${colors.textPrimary};
          font-family: inherit;
          font-size: ${typography.body2.fontSize};
        }

        .daily-punch-date-arrow {
          color: ${colors.disabled};
          font-size: 20px;
        }

        .daily-punch-branch {
          position: relative;
          display: flex;
          align-items: center;
          width: 307px;
          height: 48px;
          border: 1px solid ${colors.border};
          border-radius: 8px;
          background: ${colors.surface};
        }

        .daily-punch-branch:focus-within {
          border-color: ${colors.primaryBlue};
          box-shadow: 0 0 0 3px ${colors.focusSubtle};
        }

        .daily-punch-branch select {
          width: 100%;
          height: 100%;
          padding: 0 42px 0 13px;
          appearance: none;
          border: 0;
          outline: 0;
          background: transparent;
          color: ${colors.textSecondary};
          font-family: inherit;
          font-size: ${typography.body2.fontSize};
          cursor: pointer;
        }

        .daily-punch-branch svg {
          position: absolute;
          right: 13px;
          color: ${colors.textSecondary};
          pointer-events: none;
        }

        .daily-punch-search {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 7px;
          height: 40px;
          min-width: 110px;
          padding: 0 16px;
          border: 0;
          border-radius: 8px;
          background: ${palette.lyra.primaryGradient};
          color: ${colors.surface};
          font-family: inherit;
          font-size: ${typography.button.fontSize};
          font-weight: ${typography.button.fontWeight};
          line-height: ${typography.button.lineHeight};
          cursor: pointer;
          transition: box-shadow 140ms ease;
        }

        .daily-punch-search:hover {
          background: ${palette.lyra.primaryGradient};
          box-shadow: ${palette.lyra.actionShadow};
        }

        .daily-punch-search:focus-visible,
        .daily-punch-export button:focus-visible,
        .daily-punch-th-content button:focus-visible {
          outline: 3px solid ${colors.focusRing};
          outline-offset: 2px;
        }

        .daily-punch-export {
          display: flex;
          align-items: center;
          gap: 16px;
          margin-left: auto;
        }

        .daily-punch-export button {
          min-width: 143px;
          min-height: 40px;
          padding: 0 16px;
          border: 1px solid ${colors.border};
          border-radius: 8px;
          background: ${colors.surface};
          color: ${colors.textPrimary};
          font-family: inherit;
          font-size: ${typography.button.fontSize};
          font-weight: ${typography.button.fontWeight};
          line-height: ${typography.button.lineHeight};
          white-space: nowrap;
          cursor: pointer;
          transition: background-color 140ms ease, border-color 140ms ease;
        }

        .daily-punch-export button:hover {
          background: ${colors.hover};
          border-color: ${colors.borderStrong};
        }

        .daily-punch-table-scroll {
          width: 100%;
          max-height: calc(100vh - 265px);
          min-height: 300px;
          overflow: auto;
          scrollbar-width: thin;
          scrollbar-color: ${colors.borderStrong} ${colors.surfaceMuted};
          border-top: 1px solid ${colors.border};
        }

        .daily-punch-table {
          width: max-content;
          min-width: 100%;
          border-collapse: separate;
          border-spacing: 0;
          table-layout: fixed;
          font-family: inherit;
          font-size: ${typography.body2.fontSize};
          line-height: ${typography.body2.lineHeight};
        }

        .daily-punch-table th,
        .daily-punch-table td {
          padding: 22px 20px;
          border-bottom: 1px solid ${colors.border};
          text-align: left;
          vertical-align: middle;
        }

        .daily-punch-table thead th {
          position: sticky;
          top: 0;
          z-index: 3;
          height: 92px;
          padding: 14px 20px;
          background: ${colors.surfaceMuted};
          color: ${colors.textSecondary};
          font-family: inherit;
          font-size: ${typography.caption.fontSize};
          font-weight: ${typography.overline.fontWeight};
          letter-spacing: 0.04em;
          text-transform: uppercase;
        }

        .daily-punch-table tbody td {
          height: 150px;
          background: ${colors.surface};
        }

        .daily-punch-table tbody tr:hover td {
          background: ${colors.hover};
        }

        .daily-punch-table .fixed-name {
          position: sticky;
          left: 0;
          z-index: 2;
          width: 260px;
          min-width: 260px;
          border-right: 1px solid ${colors.border};
        }

        .daily-punch-table .fixed-role {
          position: sticky;
          left: 260px;
          z-index: 2;
          width: 280px;
          min-width: 280px;
          border-right: 1px solid ${colors.border};
        }

        .daily-punch-table thead .fixed-name,
        .daily-punch-table thead .fixed-role {
          z-index: 5;
          background: ${colors.surfaceMuted};
        }

        .daily-punch-table tbody .fixed-name,
        .daily-punch-table tbody .fixed-role {
          background: ${colors.surface};
        }

        .daily-punch-table tbody tr:hover .fixed-name,
        .daily-punch-table tbody tr:hover .fixed-role {
          background: ${colors.hover};
        }

        .daily-punch-th-content {
          display: flex;
          align-items: center;
          gap: 9px;
          white-space: nowrap;
        }

        .daily-punch-th-content button {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          padding: 0;
          border: 0;
          background: transparent;
          color: ${colors.textSecondary};
          cursor: pointer;
        }

        .daily-punch-th-content button:hover {
          color: ${colors.primaryBlue};
        }

        .daily-punch-date-column,
        .daily-punch-value {
          width: 168px;
          min-width: 168px;
        }

        .daily-punch-date-heading {
          display: flex;
          flex-direction: column;
          gap: 4px;
          white-space: nowrap;
        }

        .daily-punch-date-heading span {
          font-family: inherit;
          font-size: ${typography.subtitle2.fontSize};
          font-weight: ${typography.subtitle2.fontWeight};
        }

        .daily-punch-date-heading small {
          color: ${colors.textSecondary};
          font-family: inherit;
          font-size: ${typography.caption.fontSize};
        }

        .daily-punch-primary,
        .daily-punch-secondary {
          display: block;
          line-height: ${typography.body2.lineHeight};
        }

        .daily-punch-primary {
          color: ${colors.textPrimary};
          font-size: ${typography.subtitle2.fontSize};
          font-weight: ${typography.subtitle2.fontWeight};
        }

        .daily-punch-secondary {
          color: ${colors.textSecondary};
          font-size: ${typography.caption.fontSize};
        }

        .daily-punch-value {
          text-align: center !important;
          color: ${colors.textPrimary};
        }

        .daily-punch-empty {
          height: 160px !important;
          text-align: center !important;
          color: ${colors.textSecondary};
        }

        .daily-punch-footer {
          padding: 12px 24px;
          border-top: 1px solid ${colors.border};
          color: ${colors.textSecondary};
          font-size: ${typography.caption.fontSize};
          line-height: ${typography.caption.lineHeight};
        }

        @media (max-width: 1100px) {
          .daily-punch-toolbar {
            gap: 12px;
            padding: 18px;
          }

          .daily-punch-export {
            width: 100%;
            margin-left: 0;
          }
        }

        @media (max-width: 650px) {
          .daily-punch-page {
            padding: 4px;
          }

          .daily-punch-title {
            padding: 18px;
            font-size: ${typography.h6.fontSize};
            line-height: ${typography.h6.lineHeight};
          }

          .daily-punch-toolbar {
            padding: 12px;
          }

          .daily-punch-date-range {
            width: 100%;
            justify-content: space-between;
            gap: 5px;
          }

          .daily-punch-date-range input {
            width: 42%;
            font-size: ${typography.caption.fontSize};
          }

          .daily-punch-branch,
          .daily-punch-search {
            width: 100%;
          }

          .daily-punch-export {
            gap: 10px;
          }

          .daily-punch-export button {
            flex: 1;
            min-width: 0;
            padding: 0 7px;
            font-size: ${typography.caption.fontSize};
          }

          .daily-punch-table-scroll {
            max-height: calc(100vh - 360px);
          }
        }

        @media print {
          .daily-punch-toolbar,
          .daily-punch-footer {
            display: none !important;
          }

          .daily-punch-page,
          .daily-punch-card {
            padding: 0;
            border: 0;
          }

          .daily-punch-table-scroll {
            max-height: none;
            overflow: visible;
          }

          .daily-punch-table {
            font-size: 9px;
          }

          .daily-punch-table th,
          .daily-punch-table td {
            position: static !important;
            min-width: 0;
            width: auto;
            padding: 6px 4px;
            white-space: normal;
          }

          .daily-punch-table thead th {
            background: ${colors.surfaceMuted} !important;
            print-color-adjust: exact;
          }
        }
      `}</style>

      <div className="daily-punch-card">
        <h1 className="daily-punch-title">Daily Punch Report</h1>

        <div className="daily-punch-toolbar">
          <div className="daily-punch-date-range">
            <input
              type="date"
              aria-label="From date"
              value={fromDate}
              max={toDate}
              onChange={(e) => setFromDate(e.target.value)}
            />

            <span className="daily-punch-date-arrow">→</span>

            <input
              type="date"
              aria-label="To date"
              value={toDate}
              min={fromDate}
              onChange={(e) => setToDate(e.target.value)}
            />
          </div>

          <label className="daily-punch-branch">
            <select
              aria-label="Choose branch"
              value={branch}
              onChange={(e) => setBranch(e.target.value)}
            >
              <option value="">Choose Branch</option>
              <option value="Chennai">Chennai</option>
              <option value="Hyderabad">Hyderabad</option>
            </select>

            <ChevronDown size={21} />
          </label>

          <button className="daily-punch-search" onClick={search}>
            <Search size={17} />
            Search
          </button>

          <div className="daily-punch-export">
            <button onClick={() => exportCSV(rows, dates)}>Export Excel</button>
            <button onClick={() => window.print()}>Export PDF</button>
          </div>
        </div>

        <div className="daily-punch-table-scroll">
          <table className="daily-punch-table">
            <thead>
              <tr>
                {[
                  { key: "name", label: "Employee", className: "fixed-name" },
                  { key: "role", label: "Roles", className: "fixed-role" },
                ].map((column) => (
                  <th key={column.key} className={column.className}>
                    <div className="daily-punch-th-content">
                      <span>{column.label}</span>

                      <button
                        aria-label={`Sort by ${column.label}`}
                        onClick={() => sortBy(column.key)}
                      >
                        <ArrowDownUp size={17} />
                      </button>

                      <button
                        aria-label={`Filter ${column.label}`}
                        onClick={filterBy}
                      >
                        <Filter size={17} />
                      </button>
                    </div>
                  </th>
                ))}

                {dates.map((date) => (
                  <th className="daily-punch-date-column" key={date}>
                    <div className="daily-punch-date-heading">
                      <span>{formatDate(date)}</span>
                      <small>{getDay(date)}</small>
                    </div>
                  </th>
                ))}
              </tr>
            </thead>

            <tbody>
              {rows.length ? (
                rows.map((row) => (
                  <tr key={row.id}>
                    <td className="fixed-name">
                      <span className="daily-punch-primary">{row.name}</span>
                      <span className="daily-punch-secondary">
                        {row.employeeId}
                      </span>
                    </td>

                    <td className="fixed-role">
                      <span className="daily-punch-primary">{row.role}</span>
                      <span className="daily-punch-secondary">
                        {row.department}
                      </span>
                    </td>

                    {dates.map((date) => (
                      <td className="daily-punch-value" key={date}>
                        {row.punches[date] || "-"}
                      </td>
                    ))}
                  </tr>
                ))
              ) : (
                <tr>
                  <td className="daily-punch-empty" colSpan={dates.length + 2}>
                    No punch records found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        <div className="daily-punch-footer">
          Showing {rows.length} employees · {dates.length} days
        </div>
      </div>
    </div>
  );
}
