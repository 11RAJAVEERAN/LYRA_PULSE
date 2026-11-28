import { useMemo, useState } from "react";
import {
  ArrowDownUp,
  ChevronDown,
  Download,
  FileText,
  Filter,
  Search,
} from "lucide-react";
import { colors, palette } from "../theme/colors";
import { typography } from "../theme/typography";
import { ReportTableStyles } from "./ReportTableStyles";

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
      <ReportTableStyles />
      <style>{`
        .daily-punch-page {
          width: 100%;
          min-width: 0;
          padding: 0;
          color: ${colors.textPrimary};
          font-family: ${typography.fontFamily};
          font-size: ${typography.body2.fontSize};
          line-height: ${typography.body2.lineHeight};
        }

        .daily-punch-page * {
          box-sizing: border-box;
        }

        .daily-punch-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          flex-wrap: wrap;
          gap: 12px;
          margin-bottom: 14px;
        }

        .daily-punch-title {
          margin: 0;
          padding: 0;
          color: ${colors.primary || "#1a237e"};
          font-family: inherit;
          font-size: 24px;
          font-weight: 700;
          letter-spacing: -0.015em;
          line-height: 1.25;
        }

        .daily-punch-header-actions {
          display: flex;
          align-items: center;
          flex-wrap: wrap;
          gap: 10px;
        }

        .daily-punch-export-btn {
          height: 40px;
          padding: 0 16px;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          border: 1px solid transparent;
          border-radius: 8px;
          background: ${palette?.lyra?.primaryGradient || colors.primaryBlue || "#2563eb"};
          color: ${colors.surface || "#ffffff"};
          font-family: inherit;
          font-size: ${typography.button.fontSize};
          font-weight: ${typography.button.fontWeight};
          line-height: ${typography.button.lineHeight};
          white-space: nowrap;
          cursor: pointer;
          box-shadow: ${palette?.lyra?.actionShadow || "0 2px 6px rgba(37, 99, 235, 0.22)"};
          transition: opacity 140ms ease, transform 140ms ease, box-shadow 140ms ease;
        }

        .daily-punch-export-btn:hover {
          opacity: 0.94;
          box-shadow: ${palette?.lyra?.actionShadow || "0 4px 10px rgba(37, 99, 235, 0.28)"};
        }

        .daily-punch-export-btn:active {
          transform: translateY(1px);
        }

        .daily-punch-filter-card {
          width: 100%;
          margin-bottom: 16px;
          background: ${colors.surface};
          border: 1px solid ${colors.border};
          border-radius: 12px;
          box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
        }

        .daily-punch-table-card {
          width: 100%;
          overflow: hidden;
          background: ${colors.surface};
          border: 1px solid ${colors.border};
          border-radius: 12px;
          box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
        }

        .daily-punch-toolbar {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: 10px 12px;
          padding: 16px 20px;
        }

        .daily-punch-date-range {
          display: flex;
          align-items: center;
          gap: 10px;
          width: 300px;
          max-width: 100%;
          height: 40px;
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
          width: 46%;
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
          font-size: 16px;
          flex-shrink: 0;
        }

        .daily-punch-branch {
          position: relative;
          display: flex;
          align-items: center;
          width: 220px;
          height: 40px;
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
          padding: 0 36px 0 13px;
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
          right: 12px;
          color: ${colors.textSecondary};
          pointer-events: none;
        }

        .daily-punch-search {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: 7px;
          height: 40px;
          min-width: 105px;
          padding: 0 16px;
          border: 0;
          border-radius: 8px;
          background: ${palette.lyra.primaryGradient};
          color: ${colors.surface};
          font-family: inherit;
          font-size: ${typography.button.fontSize};
          font-weight: ${typography.button.fontWeight};
          line-height: ${typography.button.lineHeight};
          white-space: nowrap;
          cursor: pointer;
          transition: box-shadow 140ms ease;
        }

        .daily-punch-search:hover {
          background: ${palette.lyra.primaryGradient};
          box-shadow: ${palette.lyra.actionShadow};
        }

        .daily-punch-export-btn:focus-visible,
        .daily-punch-search:focus-visible,
        .daily-punch-th-content button:focus-visible {
          outline: 3px solid ${colors.focusRing};
          outline-offset: 2px;
        }

        .daily-punch-table-scroll {
          width: 100%;
          max-height: calc(100vh - 280px);
          min-height: 300px;
          overflow: auto;
          scrollbar-width: thin;
          scrollbar-color: ${colors.borderStrong} ${colors.surfaceMuted};
        }

        .daily-punch-table {
          width: max-content;
          min-width: 100%;
          border-collapse: separate;
          border-spacing: 0;
          table-layout: auto;
          font-family: inherit;
          font-size: 13px;
          line-height: 1.4;
        }

        .daily-punch-table th,
        .daily-punch-table td {
          padding: 12px 14px;
          border-bottom: 1px solid ${colors.border};
          text-align: left;
          vertical-align: middle;
        }

        .daily-punch-table thead th {
          position: sticky;
          top: 0;
          z-index: 3;
          height: 62px;
          padding: 10px 14px;
          background: ${colors.infoBackground || colors.surfaceMuted};
          color: ${colors.primary || colors.textSecondary};
          font-family: inherit;
          font-size: 13px;
          font-weight: 700;
          letter-spacing: 0;
          text-transform: none;
          white-space: nowrap;
        }

        .daily-punch-table tbody td {
          min-height: 68px;
          background: ${colors.surface};
        }

        .daily-punch-table tbody tr:hover td {
          background: ${colors.hover};
        }

        .daily-punch-table .fixed-name {
          position: sticky;
          left: 0;
          z-index: 2;
          width: 220px;
          min-width: 220px;
          padding-right: 16px;
          border-right: 1px solid ${colors.border};
        }

        .daily-punch-table .fixed-role {
          position: sticky;
          left: 220px;
          z-index: 2;
          width: 220px;
          min-width: 220px;
          padding-right: 16px;
          border-right: 1px solid ${colors.border};
        }

        .daily-punch-table thead .fixed-name,
        .daily-punch-table thead .fixed-role {
          z-index: 5;
          background: ${colors.infoBackground || colors.surfaceMuted};
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
          justify-content: space-between;
          gap: 10px;
          white-space: nowrap;
        }

        .daily-punch-th-actions {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          flex-shrink: 0;
        }

        .daily-punch-th-actions button {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          padding: 0;
          border: 0;
          background: transparent;
          color: ${colors.textSecondary};
          cursor: pointer;
          flex-shrink: 0;
        }

        .daily-punch-th-actions button:hover {
          color: ${colors.primaryBlue};
        }

        .daily-punch-filter-btn {
          padding-left: 8px !important;
          border-left: 1px solid ${colors.border} !important;
        }

        .daily-punch-date-column,
        .daily-punch-value {
          width: 156px;
          min-width: 156px;
        }

        .daily-punch-date-heading {
          display: flex;
          flex-direction: column;
          gap: 3px;
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
          font-weight: 400;
        }

        .daily-punch-primary,
        .daily-punch-secondary {
          display: block;
          line-height: ${typography.body2.lineHeight};
          white-space: nowrap;
        }

        .daily-punch-primary {
          color: ${colors.textPrimary};
          font-size: ${typography.subtitle2.fontSize};
          font-weight: ${typography.subtitle2.fontWeight};
        }

        .daily-punch-secondary {
          margin-top: 3px;
          color: ${colors.textSecondary};
          font-size: ${typography.caption.fontSize};
        }

        .daily-punch-value {
          text-align: center !important;
          color: ${colors.textPrimary};
          white-space: nowrap;
        }

        .daily-punch-empty {
          height: 140px !important;
          text-align: center !important;
          color: ${colors.textSecondary};
        }

        .daily-punch-footer {
          padding: 12px 20px;
          border-top: 1px solid ${colors.border};
          color: ${colors.textSecondary};
          font-size: ${typography.caption.fontSize};
          line-height: ${typography.caption.lineHeight};
        }

        @media (max-width: 1100px) {
          .daily-punch-toolbar {
            gap: 10px;
            padding: 14px 16px;
          }
        }

        @media (max-width: 650px) {
          .daily-punch-header {
            align-items: stretch;
            flex-direction: column;
            margin-bottom: 12px;
          }

          .daily-punch-title {
            font-size: 20px;
            line-height: 1.25;
          }

          .daily-punch-header-actions {
            width: 100%;
          }

          .daily-punch-export-btn {
            flex: 1;
            padding: 0 12px;
            font-size: ${typography.caption.fontSize};
          }

          .daily-punch-filter-card {
            margin-bottom: 12px;
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

          .daily-punch-table-scroll {
            max-height: calc(100vh - 360px);
          }
        }

        @media print {
          body * {
            visibility: hidden;
          }

          .daily-punch-header,
          .daily-punch-header .daily-punch-title,
          .daily-punch-table-card,
          .daily-punch-table-card * {
            visibility: visible;
          }

          .daily-punch-header-actions,
          .daily-punch-filter-card,
          .daily-punch-footer {
            display: none !important;
          }

          .daily-punch-header {
            position: static;
            margin-bottom: 10px;
          }

          .daily-punch-table-card {
            position: static;
            width: 100%;
            border: 0;
            box-shadow: none;
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
            background: ${colors.infoBackground || colors.surfaceMuted} !important;
            print-color-adjust: exact;
          }
        }
      `}</style>

      <div className="daily-punch-header">
        <h1 className="daily-punch-title">Daily Punch Report</h1>

        <div className="daily-punch-header-actions">
          <button
            type="button"
            className="daily-punch-export-btn"
            onClick={() => exportCSV(rows, dates)}
          >
            <Download size={16} />
            <span>Export Excel</span>
          </button>

          <button
            type="button"
            className="daily-punch-export-btn"
            onClick={() => window.print()}
          >
            <FileText size={16} />
            <span>Export PDF</span>
          </button>
        </div>
      </div>

      <section className="daily-punch-filter-card">
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

            <ChevronDown size={19} />
          </label>

          <button type="button" className="daily-punch-search" onClick={search}>
            <Search size={16} />
            <span>Search</span>
          </button>
        </div>
      </section>

      <section className="daily-punch-table-card">
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

                      <div className="daily-punch-th-actions">
                        <button
                          type="button"
                          aria-label={`Sort by ${column.label}`}
                          onClick={() => sortBy(column.key)}
                        >
                          <ArrowDownUp size={15} />
                        </button>

                        <button
                          type="button"
                          className="daily-punch-filter-btn"
                          aria-label={`Filter ${column.label}`}
                          onClick={filterBy}
                        >
                          <Filter size={14} />
                        </button>
                      </div>
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
      </section>
    </div>
  );
}
