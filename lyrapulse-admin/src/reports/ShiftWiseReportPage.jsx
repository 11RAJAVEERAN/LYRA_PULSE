import { useMemo, useState } from "react";
import { ArrowDownUp, ChevronDown, Filter, Search } from "lucide-react";

const initialRows = [
  {
    id: 1,
    name: "ARTHI C",
    employeeId: "1599",
    role: "FOA",
    department: "FO",
    date: "2026-10-01",
    shift: "08 to 06",
    from: "08:00 AM",
    to: "06:00 PM",
    breakFrom: "-",
    breakTo: "-",
    firstPunch: "-",
    branch: "Chennai",
  },
  {
    id: 2,
    name: "SARAVANAN",
    employeeId: "1615",
    role: "Floor Supervisor",
    department: "F&B Production",
    date: "2026-10-01",
    shift: "08 to 06",
    from: "08:00 AM",
    to: "06:00 PM",
    breakFrom: "-",
    breakTo: "-",
    firstPunch: "-",
    branch: "Chennai",
  },
  {
    id: 3,
    name: "THILAK BAHADUR",
    employeeId: "1609",
    role: "Commis I",
    department: "F&B Production",
    date: "2026-10-01",
    shift: "08 to 06",
    from: "08:00 AM",
    to: "06:00 PM",
    breakFrom: "-",
    breakTo: "-",
    firstPunch: "10:12 AM",
    branch: "Chennai",
  },
  {
    id: 4,
    name: "MOHAN TOMATA",
    employeeId: "1614",
    role: "Commis I",
    department: "F&B Production",
    date: "2026-10-01",
    shift: "08 to 06",
    from: "08:00 AM",
    to: "06:00 PM",
    breakFrom: "-",
    breakTo: "-",
    firstPunch: "-",
    branch: "Chennai",
  },
  {
    id: 5,
    name: "SEETHA M",
    employeeId: "1620",
    role: "Store Asst",
    department: "Stores",
    date: "2026-10-01",
    shift: "08 to 06",
    from: "08:00 AM",
    to: "06:00 PM",
    breakFrom: "-",
    breakTo: "-",
    firstPunch: "07:58 AM",
    branch: "Hyderabad",
  },
];

const formatDate = (date) => {
  if (!date) return "";
  const [year, month, day] = date.split("-");
  return `${day}-${month}-${year}`;
};

const getDay = (date) =>
  new Date(`${date}T12:00:00`).toLocaleDateString("en-US", {
    weekday: "long",
  });

function exportCSV(rows) {
  const headers = [
    "Employee",
    "Employee ID",
    "Role",
    "Department",
    "Date",
    "Day",
    "Shift",
    "From",
    "To",
    "Break From",
    "Break To",
    "First Punch",
    "Branch",
  ];

  const escapeCSV = (value) =>
    `"${String(value ?? "-").replace(/"/g, '""')}"`;

  const content = [
    headers,
    ...rows.map((row) => [
      row.name,
      row.employeeId,
      row.role,
      row.department,
      formatDate(row.date),
      getDay(row.date),
      row.shift,
      row.from,
      row.to,
      row.breakFrom,
      row.breakTo,
      row.firstPunch,
      row.branch,
    ]),
  ]
    .map((line) => line.map(escapeCSV).join(","))
    .join("\r\n");

  const blob = new Blob(["\uFEFF" + content], {
    type: "text/csv;charset=utf-8;",
  });

  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = "shift-wise-report.csv";
  link.click();
  URL.revokeObjectURL(url);
}

export default function ShiftWiseReportPage() {
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

  const rows = useMemo(() => {
    let result = initialRows.filter((row) => {
      const matchesDate =
        row.date >= applied.fromDate && row.date <= applied.toDate;

      const matchesBranch = !applied.branch || row.branch === applied.branch;

      const q = applied.searchTerm.toLowerCase();

      const matchesSearch =
        !q ||
        row.name.toLowerCase().includes(q) ||
        row.employeeId.includes(q) ||
        row.role.toLowerCase().includes(q) ||
        row.department.toLowerCase().includes(q);

      return matchesDate && matchesBranch && matchesSearch;
    });

    if (sort.key) {
      result = [...result].sort((a, b) => {
        const comparison = String(a[sort.key] ?? "").localeCompare(
          String(b[sort.key] ?? ""),
          undefined,
          { numeric: true },
        );

        return sort.direction === "asc" ? comparison : -comparison;
      });
    }

    return result;
  }, [applied, sort]);

  const handleSearch = () => {
    if (!fromDate || !toDate || fromDate > toDate) {
      window.alert("Please select a valid date range.");
      return;
    }

    setApplied({ fromDate, toDate, branch, searchTerm });
  };

  const handleSort = (key) => {
    setSort((current) => ({
      key,
      direction:
        current.key === key && current.direction === "asc" ? "desc" : "asc",
    }));
  };

  const filterEmployees = () => {
    const query = window.prompt("Search employee, ID or role:", searchTerm);

    if (query !== null) {
      setSearchTerm(query);
      setApplied((current) => ({ ...current, searchTerm: query }));
    }
  };

  const columns = [
    { key: "name", label: "Employee", sort: true, filter: true },
    { key: "role", label: "Roles", sort: true, filter: true },
    { key: "date", label: "Date", sort: true },
    { key: "day", label: "Day" },
    { key: "shift", label: "Shift", sort: true },
    { key: "from", label: "From" },
    { key: "to", label: "To" },
    { key: "breakFrom", label: "Break From" },
    { key: "breakTo", label: "Break To" },
    { key: "firstPunch", label: "First Punch" },
  ];

  return (
    <div className="shift-wise-page">
      <style>{`
        .shift-wise-page {
          --sw-primary: #172554;
          --sw-primary-dark: #0B1638;
          --sw-primary-blue: #2563EB;
          --sw-secondary: #4F46E5;
          --sw-background: #F5F7FB;
          --sw-surface: #FFFFFF;
          --sw-surface-muted: #F8FAFC;
          --sw-text-primary: #0F172A;
          --sw-text-secondary: #64748B;
          --sw-border: #E2E8F0;
          --sw-border-strong: #94A3B8;
          --sw-hover: #F1F5F9;
          --sw-focus-ring: rgba(37, 99, 235, 0.12);
          --sw-selected: rgba(37, 99, 235, 0.08);
          --sw-gradient: linear-gradient(90deg, #172554, #4F46E5);

          width: 100%;
          min-width: 0;
          padding: 8px;
          box-sizing: border-box;
          color: var(--sw-text-primary);
          font-family: Inter, "Segoe UI", sans-serif;
          font-size: 0.875rem;
          line-height: 1.55;
        }

        .shift-wise-page * {
          box-sizing: border-box;
        }

        .shift-wise-card {
          width: 100%;
          overflow: hidden;
          background: var(--sw-surface);
          border: 1px solid var(--sw-border);
          border-radius: 12px;
          box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
        }

        .shift-wise-title {
          margin: 0;
          padding: 22px 29px;
          color: var(--sw-text-primary);
          font-family: inherit;
          font-size: 1.5rem;
          font-weight: 700;
          letter-spacing: -0.02em;
          line-height: 1.3;
        }

        .shift-wise-toolbar {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: 12px 20px;
          padding: 20px 29px 24px;
        }

        .shift-wise-dates {
          display: flex;
          align-items: center;
          gap: 10px;
          height: 44px;
          padding: 0 12px;
          border: 1px solid var(--sw-border);
          border-radius: 8px;
          background: var(--sw-surface);
          transition: border-color 0.2s ease, box-shadow 0.2s ease;
        }

        .shift-wise-dates:focus-within {
          border-color: var(--sw-primary-blue);
          box-shadow: 0 0 0 3px var(--sw-focus-ring);
        }

        .shift-wise-dates input {
          width: 132px;
          min-width: 0;
          border: 0;
          outline: 0;
          color: var(--sw-text-primary);
          background: transparent;
          font-family: inherit;
          font-size: 0.8125rem;
          line-height: 1.5;
        }

        .shift-wise-dates input:focus {
          outline: none;
        }

        .shift-wise-date-arrow {
          color: var(--sw-text-secondary);
          font-size: 1.125rem;
        }

        .shift-wise-branch {
          position: relative;
          display: flex;
          align-items: center;
          width: 260px;
          max-width: 100%;
          height: 44px;
          border: 1px solid var(--sw-border);
          border-radius: 8px;
          background: var(--sw-surface);
          transition: border-color 0.2s ease, box-shadow 0.2s ease;
        }

        .shift-wise-branch:focus-within {
          border-color: var(--sw-primary-blue);
          box-shadow: 0 0 0 3px var(--sw-focus-ring);
        }

        .shift-wise-branch select {
          width: 100%;
          height: 100%;
          padding: 0 42px 0 13px;
          appearance: none;
          border: 0;
          outline: 0;
          border-radius: inherit;
          background: transparent;
          color: var(--sw-text-secondary);
          font-family: inherit;
          font-size: 0.875rem;
          cursor: pointer;
        }

        .shift-wise-branch svg {
          position: absolute;
          right: 13px;
          color: var(--sw-text-secondary);
          pointer-events: none;
        }

        .shift-wise-search {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          min-width: 112px;
          height: 44px;
          padding: 0 20px;
          border: 0;
          border-radius: 8px;
          background: var(--sw-gradient);
          color: #FFFFFF;
          font-family: inherit;
          font-size: 0.875rem;
          font-weight: 650;
          line-height: 1.4;
          cursor: pointer;
          box-shadow: 0 4px 10px rgba(37, 99, 235, 0.12);
          transition: opacity 0.2s ease, box-shadow 0.2s ease;
        }

        .shift-wise-search:hover {
          opacity: 0.94;
          box-shadow: 0 6px 14px rgba(37, 99, 235, 0.18);
        }

        .shift-wise-search:focus-visible,
        .shift-wise-export button:focus-visible,
        .shift-wise-icon-button:focus-visible {
          outline: 2px solid var(--sw-primary-blue);
          outline-offset: 3px;
        }

        .shift-wise-export {
          display: flex;
          align-items: center;
          gap: 10px;
          margin-left: auto;
        }

        .shift-wise-export button {
          min-width: 120px;
          height: 44px;
          padding: 0 16px;
          border: 1px solid var(--sw-border);
          border-radius: 8px;
          background: var(--sw-surface);
          color: var(--sw-primary);
          font-family: inherit;
          font-size: 0.875rem;
          font-weight: 600;
          line-height: 1.4;
          white-space: nowrap;
          cursor: pointer;
          transition: background 0.2s ease, border-color 0.2s ease;
        }

        .shift-wise-export button:hover {
          background: var(--sw-hover);
          border-color: var(--sw-border-strong);
        }

        .shift-wise-table-scroll {
          width: 100%;
          max-height: calc(100vh - 265px);
          min-height: 300px;
          overflow: auto;
          scrollbar-width: thin;
          scrollbar-color: var(--sw-border-strong) var(--sw-surface-muted);
        }

        .shift-wise-table {
          width: max-content;
          min-width: 100%;
          border-collapse: separate;
          border-spacing: 0;
          table-layout: fixed;
          font-family: inherit;
          font-size: 0.875rem;
          line-height: 1.55;
        }

        .shift-wise-table th,
        .shift-wise-table td {
          padding: 18px 20px;
          border-bottom: 1px solid var(--sw-border);
          text-align: left;
          vertical-align: middle;
        }

        .shift-wise-table thead th {
          position: sticky;
          top: 0;
          z-index: 3;
          height: 72px;
          padding: 16px 20px;
          background: var(--sw-surface-muted);
          color: var(--sw-text-secondary);
          font-size: 0.75rem;
          font-weight: 700;
          letter-spacing: 0.025em;
          line-height: 1.45;
          white-space: nowrap;
        }

        .shift-wise-table tbody td {
          height: 76px;
          background: var(--sw-surface);
          color: var(--sw-text-primary);
          font-size: 0.875rem;
          line-height: 1.55;
        }

        .shift-wise-table tbody tr {
          transition: background 0.15s ease;
        }

        .shift-wise-table tbody tr:hover td {
          background: var(--sw-hover);
        }

        .shift-wise-table th:first-child,
        .shift-wise-table td:first-child {
          position: sticky;
          left: 0;
          z-index: 2;
          width: 260px;
          min-width: 260px;
          border-right: 1px solid var(--sw-border);
        }

        .shift-wise-table thead th:first-child {
          z-index: 5;
          background: var(--sw-surface-muted);
        }

        .shift-wise-table tbody td:first-child {
          background: var(--sw-surface);
        }

        .shift-wise-table tbody tr:hover td:first-child {
          background: var(--sw-hover);
        }

        .shift-wise-table th:nth-child(2),
        .shift-wise-table td:nth-child(2) {
          width: 240px;
          min-width: 240px;
        }

        .shift-wise-table th:nth-child(3),
        .shift-wise-table td:nth-child(3) {
          width: 145px;
          min-width: 145px;
        }

        .shift-wise-table th:nth-child(4),
        .shift-wise-table td:nth-child(4) {
          width: 120px;
          min-width: 120px;
        }

        .shift-wise-table th:nth-child(5),
        .shift-wise-table td:nth-child(5) {
          width: 145px;
          min-width: 145px;
        }

        .shift-wise-heading {
          display: flex;
          align-items: center;
          gap: 9px;
          white-space: nowrap;
        }

        .shift-wise-icon-button {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
          padding: 3px;
          border: 0;
          border-radius: 5px;
          background: transparent;
          color: var(--sw-text-secondary);
          cursor: pointer;
          transition: color 0.2s ease, background 0.2s ease;
        }

        .shift-wise-icon-button:hover {
          color: var(--sw-primary-blue);
          background: var(--sw-selected);
        }

        .shift-wise-filter {
          margin-left: 2px;
          padding-left: 10px;
          border-left: 1px solid var(--sw-border);
          border-radius: 0;
        }

        .shift-wise-primary,
        .shift-wise-secondary {
          display: block;
          line-height: 1.5;
        }

        .shift-wise-primary {
          color: var(--sw-text-primary);
          font-weight: 600;
        }

        .shift-wise-secondary {
          margin-top: 3px;
          color: var(--sw-text-secondary);
          font-size: 0.75rem;
          line-height: 1.45;
        }

        .shift-wise-time {
          min-width: 105px;
          white-space: normal !important;
          line-height: 1.6;
        }

        .shift-wise-empty {
          height: 160px !important;
          text-align: center !important;
          color: var(--sw-text-secondary) !important;
          font-size: 0.875rem;
        }

        .shift-wise-footer {
          padding: 13px 24px;
          border-top: 1px solid var(--sw-border);
          background: var(--sw-surface);
          color: var(--sw-text-secondary);
          font-size: 0.75rem;
          line-height: 1.45;
        }

        @media (max-width: 1100px) {
          .shift-wise-toolbar {
            gap: 12px;
            padding: 18px;
          }

          .shift-wise-export {
            width: 100%;
            margin-left: 0;
          }
        }

        @media (max-width: 650px) {
          .shift-wise-page {
            padding: 4px;
          }

          .shift-wise-title {
            padding: 18px;
            font-size: 1.25rem;
          }

          .shift-wise-toolbar {
            padding: 12px;
          }

          .shift-wise-dates {
            width: 100%;
            justify-content: space-between;
            gap: 5px;
          }

          .shift-wise-dates input {
            width: 42%;
            font-size: 0.75rem;
          }

          .shift-wise-branch,
          .shift-wise-search {
            width: 100%;
          }

          .shift-wise-export {
            gap: 10px;
          }

          .shift-wise-export button {
            flex: 1;
            min-width: 0;
            padding: 0 7px;
            font-size: 0.8125rem;
          }

          .shift-wise-table-scroll {
            max-height: calc(100vh - 360px);
          }

          .shift-wise-table th,
          .shift-wise-table td {
            padding: 14px 12px;
          }
        }

        @media print {
          .shift-wise-toolbar,
          .shift-wise-footer {
            display: none !important;
          }

          .shift-wise-page,
          .shift-wise-card {
            padding: 0;
            border: 0;
            box-shadow: none;
          }

          .shift-wise-table-scroll {
            max-height: none;
            overflow: visible;
          }

          .shift-wise-table {
            font-size: 9px;
          }

          .shift-wise-table th,
          .shift-wise-table td {
            position: static !important;
            min-width: 0;
            width: auto;
            padding: 6px 4px;
            white-space: normal;
          }

          .shift-wise-table thead th {
            background: var(--sw-surface-muted) !important;
            print-color-adjust: exact;
          }
        }
      `}</style>

      <div className="shift-wise-card">
        <h1 className="shift-wise-title">Shift Wise Report</h1>

        <div className="shift-wise-toolbar">
          <div className="shift-wise-dates">
            <input
              type="date"
              aria-label="From date"
              value={fromDate}
              max={toDate}
              onChange={(e) => setFromDate(e.target.value)}
            />

            <span className="shift-wise-date-arrow">→</span>

            <input
              type="date"
              aria-label="To date"
              value={toDate}
              min={fromDate}
              onChange={(e) => setToDate(e.target.value)}
            />
          </div>

          <label className="shift-wise-branch">
            <select
              aria-label="Choose branch"
              value={branch}
              onChange={(e) => setBranch(e.target.value)}
            >
              <option value="">Choose Branch</option>
              <option value="Chennai">Chennai</option>
              <option value="Hyderabad">Hyderabad</option>
            </select>

            <ChevronDown size={20} />
          </label>

          <button className="shift-wise-search" onClick={handleSearch}>
            <Search size={17} />
            Search
          </button>

          <div className="shift-wise-export">
            <button onClick={() => exportCSV(rows)}>Export Excel</button>
            <button onClick={() => window.print()}>Export PDF</button>
          </div>
        </div>

        <div className="shift-wise-table-scroll">
          <table className="shift-wise-table">
            <thead>
              <tr>
                {columns.map((column) => (
                  <th key={column.key}>
                    <div className="shift-wise-heading">
                      <span>{column.label}</span>

                      {column.sort && (
                        <button
                          className="shift-wise-icon-button"
                          aria-label={`Sort by ${column.label}`}
                          onClick={() => handleSort(column.key)}
                        >
                          <ArrowDownUp size={16} />
                        </button>
                      )}

                      {column.filter && (
                        <button
                          className="shift-wise-icon-button shift-wise-filter"
                          aria-label={`Filter ${column.label}`}
                          onClick={filterEmployees}
                        >
                          <Filter size={16} />
                        </button>
                      )}
                    </div>
                  </th>
                ))}
              </tr>
            </thead>

            <tbody>
              {rows.length ? (
                rows.map((row) => (
                  <tr key={row.id}>
                    <td>
                      <span className="shift-wise-primary">{row.name}</span>
                      <span className="shift-wise-secondary">
                        {row.employeeId}
                      </span>
                    </td>

                    <td>
                      <span className="shift-wise-primary">{row.role}</span>
                      <span className="shift-wise-secondary">
                        {row.department}
                      </span>
                    </td>

                    <td>{formatDate(row.date)}</td>
                    <td>{getDay(row.date)}</td>
                    <td>{row.shift}</td>
                    <td className="shift-wise-time">{row.from}</td>
                    <td className="shift-wise-time">{row.to}</td>
                    <td>{row.breakFrom}</td>
                    <td>{row.breakTo}</td>
                    <td>{row.firstPunch}</td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td className="shift-wise-empty" colSpan={columns.length}>
                    No shift records found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        <div className="shift-wise-footer">
          Showing {rows.length} records
        </div>
      </div>
    </div>
  );
}
