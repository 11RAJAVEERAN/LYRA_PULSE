import { useEffect, useState } from "react";
import {
  CalendarDays,
  ChevronDown,
  ChevronUp,
  ChevronsUpDown,
  Download,
  FileText,
  Filter,
} from "lucide-react";
import { colors, palette } from "../../../theme/colors";
import { typography } from "../../../theme/typography";
import { ReportTableStyles } from "../components/ReportTableStyles";
import { downloadReport, reportsApi } from "../api/reportsApi";

export default function AttendanceMasterPage() {
  const today = new Date();
  const toIso = (date) => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
  const endDefault = toIso(today);
  const startDefaultDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 27);
  const startDefault = toIso(startDefaultDate);
  const [startDate, setStartDate] = useState(startDefault);
  const [endDate, setEndDate] = useState(endDefault);
  const [branch, setBranch] = useState("");
  const [searchText, setSearchText] = useState("");
  const [filters, setFilters] = useState({ startDate: startDefault, endDate: endDefault, branch: "", search: "" });
  const [branches, setBranches] = useState([]);
  const [branchError, setBranchError] = useState("");
  const [rows, setRows] = useState([]);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [count, setCount] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [exporting, setExporting] = useState("");
  const [sort, setSort] = useState({ key: "date", direction: "desc", ordering: "-attendance_date" });

  useEffect(() => {
    const controller = new AbortController();
    reportsApi.branches(controller.signal)
      .then((data) => setBranches(Array.isArray(data) ? data : []))
      .catch((requestError) => {
        if (requestError.name !== "CanceledError") setBranchError("Branches could not be loaded. Please retry the page.");
      });
    return () => controller.abort();
  }, []);

  useEffect(() => {
    const controller = new AbortController();
    const params = {
      start_date: filters.startDate,
      end_date: filters.endDate,
      page,
      page_size: pageSize,
      ordering: sort.ordering,
    };
    if (filters.branch) params.branch = filters.branch;
    if (filters.search) params.search = filters.search;
    setLoading(true);
    setError("");
    reportsApi.list("attendance-master", params, controller.signal)
      .then((response) => {
        setRows(response?.results ?? []);
        setCount(response?.count ?? 0);
        setTotalPages(response?.total_pages ?? 1);
      })
      .catch((requestError) => {
        if (requestError.name !== "CanceledError") {
          setError(requestError.response?.data?.message || requestError.response?.data?.detail || "Attendance records could not be loaded. Please try again.");
          setRows([]);
          setCount(0);
        }
      })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, [filters, page, pageSize, sort.ordering]);

  const handleSearch = () => {
    const rangeDays = startDate && endDate ? (Date.parse(`${endDate}T00:00:00`) - Date.parse(`${startDate}T00:00:00`)) / 86400000 + 1 : 0;
    if (!startDate || !endDate || startDate > endDate || endDate > endDefault || rangeDays > 92) {
      setError("Choose a valid date range within the last 92 days and ending today or earlier.");
      return;
    }
    setFilters({ startDate, endDate, branch, search: searchText.trim() });
    setPage(1);
  };

  const orderingFor = { employee: "employee_name", role: "designation", date: "attendance_date", status: "classification" };
  const handleSort = (key) => {
    const field = orderingFor[key];
    if (!field) return;
    const descending = sort.key === key ? sort.direction === "asc" : key === "date";
    setSort({ key, direction: descending ? "desc" : "asc", ordering: `${descending ? "-" : ""}${field}` });
    setPage(1);
  };

  const formatPunch = (value) => value ? new Date(value).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" }) : "-";
  const displayRows = rows.map((item) => ({
    id: item.employee?.employee_code ?? item.employee?.id,
    employee: item.employee?.name ?? "-",
    role: item.designation?.name ?? "-",
    department: item.department?.name ?? "-",
    date: item.attendance_date,
    day: item.day ?? "-",
    firstPunch: formatPunch(item.first_punch_at),
    lastPunch: formatPunch(item.last_punch_at),
    workingHours: item.working_hours_display ?? "-",
    breakHours: item.break_hours_display ?? "-",
    status: item.classification_display ?? item.classification ?? "-",
  }));

  const exportReport = async (format) => {
    setExporting(format);
    setError("");
    const params = {
      start_date: filters.startDate,
      end_date: filters.endDate,
      ordering: sort.ordering,
      export_format: format,
    };
    if (filters.branch) params.branch = filters.branch;
    if (filters.search) params.search = filters.search;
    try {
      const downloaded = await reportsApi.export("attendance-master", params);
      downloadReport(downloaded, `attendance-master.${format}`);
    } catch (requestError) {
      setError(requestError.response?.status ? "The export could not be generated. Please try again." : "Unable to connect to the attendance service.");
    } finally {
      setExporting("");
    }
  };

  const SortButton = ({ column, children }) => (
    <button type="button" className="am-sort" onClick={() => handleSort(column)}>
      <span className="am-sort-label">{children}</span>
      <span className="am-sort-tools">
        {sort.key === column ? (sort.direction === "asc" ? <ChevronUp size={15} /> : <ChevronDown size={15} />) : <ChevronsUpDown size={15} />}
        <span className="am-filter-icon"><Filter size={14} /></span>
      </span>
    </button>
  );
  return (
    <div className="am-page">
      <ReportTableStyles />

      <style>{`
        .am-page {
          width: 100%;
          min-width: 0;
          padding: 0;
          color: ${colors.textPrimary};
          font-family: ${typography.fontFamily};
          font-size: ${typography.body2.fontSize};
          line-height: ${typography.body2.lineHeight};
        }

        .am-page * {
          box-sizing: border-box;
        }

        .am-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          flex-wrap: wrap;
          gap: 12px;
          margin-bottom: 14px;
        }

        .am-title {
          padding: 0;
          margin: 0;
          font-size: 24px;
          font-weight: 700;
          letter-spacing: -0.015em;
          line-height: 1.25;
          color: ${colors.primary || "#1a237e"};
        }

        .am-header-actions {
          display: flex;
          align-items: center;
          flex-wrap: wrap;
          gap: 10px;
        }

        .am-export-btn {
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

        .am-export-btn:hover {
          opacity: 0.94;
          box-shadow: ${palette?.lyra?.actionShadow || "0 4px 10px rgba(37, 99, 235, 0.28)"};
        }

        .am-export-btn:active {
          transform: translateY(1px);
        }

        .am-export-btn:focus-visible,
        .am-button:focus-visible,
        .am-sort:focus-visible {
          outline: 3px solid ${colors.focusRing};
          outline-offset: 2px;
        }

        .am-filter-card {
          width: 100%;
          margin-bottom: 16px;
          background: ${colors.surface};
          border: 1px solid ${colors.border};
          border-radius: 12px;
          box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
        }

        .am-table-card {
          width: 100%;
          overflow: hidden;
          background: ${colors.surface};
          border: 1px solid ${colors.border};
          border-radius: 12px;
          box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
        }

        .am-toolbar {
          display: flex;
          align-items: center;
          justify-content: space-between;
          flex-wrap: wrap;
          gap: 12px;
          padding: 16px 20px;
        }

        .am-filters {
          display: flex;
          align-items: center;
          flex-wrap: wrap;
          gap: 8px;
        }

        .am-date {
          width: 300px;
          max-width: 100%;
          height: 40px;
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
          width: 220px;
          height: 40px;
        }

        .am-department select {
          width: 100%;
          height: 100%;
          padding: 0 36px 0 13px;
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
          top: 11px;
          pointer-events: none;
          color: ${colors.textSecondary};
        }

        .am-button {
          height: 40px;
          padding: 0 14px;
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
          transition: background-color 140ms ease,
            border-color 140ms ease,
            box-shadow 140ms ease;
        }

        .am-search {
          min-width: 105px;
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
          max-height: 70vh;
          overflow: auto;
        }

        .am-table {
          width: 100%;
          min-width: 1120px;
          table-layout: auto;
          border-collapse: separate;
          border-spacing: 0;
          font-family: inherit;
          font-size: 13px;
          line-height: 1.4;
        }

        .am-table th {
          position: sticky;
          top: 0;
          z-index: 2;
          height: 46px;
          padding: 10px 14px;
          background: ${colors.infoBackground};
          color: ${colors.primary};
          text-align: left;
          font-family: inherit;
          font-size: 13px;
          font-weight: 700;
          letter-spacing: 0;
          text-transform: none;
          white-space: nowrap;
          line-height: 1.3;
          border-bottom: 1px solid ${colors.border};
        }

        .am-table td {
          min-height: 54px;
          padding: 10px 14px;
          color: ${colors.textPrimary};
          white-space: nowrap;
          background: ${colors.surface};
          border-bottom: 1px solid ${colors.border};
          font-family: inherit;
          font-size: 13px;
          line-height: 1.4;
          vertical-align: middle;
        }

        .am-table tbody tr:hover td {
          background: ${colors.hover};
        }

        .am-table .am-employee {
          min-width: 220px;
          padding-right: 18px;
          border-right: 1px solid ${colors.border};
        }

        .am-table .am-role {
          min-width: 210px;
          padding-right: 18px;
          border-right: 1px solid ${colors.border};
        }

        .am-sort {
          width: 100%;
          min-width: 0;
          padding: 0;
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 12px;
          border: 0;
          background: transparent;
          color: inherit;
          font: inherit;
          font-weight: 700;
          text-align: left;
          cursor: pointer;
        }

        .am-sort-label {
          white-space: nowrap;
        }

        .am-sort-tools {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          flex-shrink: 0;
          color: ${colors.textSecondary};
        }

        .am-sort-tools svg {
          flex-shrink: 0;
          color: ${colors.textSecondary};
        }

        .am-filter-icon {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          padding-left: 8px;
          border-left: 1px solid ${colors.border};
          flex-shrink: 0;
        }

        .am-employee-name {
          font-size: ${typography.subtitle2.fontSize};
          font-weight: ${typography.subtitle2.fontWeight};
          line-height: ${typography.subtitle2.lineHeight};
          color: ${colors.textPrimary};
          white-space: nowrap;
        }

        .am-subtext {
          margin-top: 3px;
          color: ${colors.textSecondary};
          font-size: ${typography.caption.fontSize};
          line-height: ${typography.caption.lineHeight};
          white-space: nowrap;
        }

        .am-status {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          text-decoration: underline;
          text-underline-offset: 2px;
        }

        .am-status-dot {
          width: 9px;
          height: 9px;
          border: 2px solid ${colors.primaryBlue};
          border-radius: 50%;
          flex-shrink: 0;
        }

        .am-empty {
          height: 100px !important;
          text-align: center;
          color: ${colors.textSecondary} !important;
        }

        .am-error { margin: 0 0 12px; padding: 10px 14px; color: #9f1d1d; background: #fff1f0; border: 1px solid #f0b6b1; border-radius: 8px; }

        .am-footer {
          display: flex;
          align-items: center;
          justify-content: space-between;
          flex-wrap: wrap;
          gap: 12px;
          padding: 12px 20px;
          color: ${colors.textSecondary};
          font-size: ${typography.caption.fontSize};
          line-height: ${typography.caption.lineHeight};
          border-top: 1px solid ${colors.border};
        }

        .am-pagination { display: flex; align-items: center; gap: 8px; }
        .am-pagination button, .am-pagination select { min-height: 34px; padding: 0 10px; color: ${colors.textPrimary}; border: 1px solid ${colors.border}; border-radius: 6px; background: ${colors.surface}; font: inherit; cursor: pointer; }
        .am-pagination button[aria-current="page"] { color: white; background: ${colors.primaryBlue}; border-color: ${colors.primaryBlue}; }
        .am-pagination button:disabled { opacity: .5; cursor: default; }
        .am-pagination label { display: flex; align-items: center; gap: 6px; white-space: nowrap; }

        @media (max-width: 1100px) {
          .am-toolbar {
            align-items: flex-start;
            flex-direction: column;
          }

          .am-filters {
            gap: 10px;
          }
        }

        @media (max-width: 600px) {
          .am-header {
            align-items: stretch;
            flex-direction: column;
            margin-bottom: 12px;
          }

          .am-title {
            font-size: 20px;
            line-height: 1.25;
          }

          .am-header-actions {
            width: 100%;
          }

          .am-export-btn {
            flex: 1;
            padding: 0 12px;
          }

          .am-filter-card {
            margin-bottom: 12px;
          }

          .am-toolbar {
            padding: 12px 16px;
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
        }

        @media print {
          body * {
            visibility: hidden;
          }

          .am-header,
          .am-header .am-title,
          .am-table-card,
          .am-table-card * {
            visibility: visible;
          }

          .am-header-actions {
            display: none;
          }

          .am-header {
            position: static;
            margin-bottom: 10px;
          }

          .am-filter-card {
            display: none;
          }

          .am-table-card {
            position: static;
            width: 100%;
            border: 0;
            box-shadow: none;
          }

          .am-table-wrap {
            max-height: none;
            overflow: visible;
          }

          .am-table {
            min-width: 0;
            font-size: 10px;
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

      <div className="am-header">
        <h1 className="am-title">Attendance Master</h1>

        <div className="am-header-actions">
          <button type="button" className="am-export-btn" onClick={() => exportReport("xlsx")} disabled={Boolean(exporting) || loading}>
            <Download size={16} />
            <span>{exporting === "xlsx" ? "Exporting…" : "Export Excel"}</span>
          </button>

          <button
            type="button"
            className="am-export-btn"
            onClick={() => exportReport("pdf")} disabled={Boolean(exporting) || loading}
          >
            <FileText size={16} />
            <span>{exporting === "pdf" ? "Exporting…" : "Export PDF"}</span>
          </button>
        </div>
      </div>

      <section className="am-filter-card">
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
                max={endDefault}
                min={startDate}
                onChange={(event) => setEndDate(event.target.value)}
              />
            </div>

            <div className="am-department">
              <select
                aria-label="Choose Branch"
                value={branch}
                onChange={(event) => setBranch(event.target.value)}
                disabled={Boolean(branchError)}
              >
                <option value="">Choose Branch</option>
                {branches.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
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
        </div>
      </section>

      {branchError && <div role="alert" className="am-error">{branchError}</div>}
      {error && !loading && <div role="alert" className="am-error">{error}</div>}
      <section className="am-table-card">
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
              {loading ? (
                <tr><td colSpan={9} className="am-empty">Loading attendance records…</td></tr>
              ) : displayRows.length > 0 ? (
                displayRows.map((row) => (
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
                    {error || "No attendance records found."}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        <div className="am-footer">
          <span>Showing {count === 0 ? 0 : (page - 1) * pageSize + 1}–{Math.min(page * pageSize, count)} of {count} Results</span>
          <div className="am-pagination">
            <label>Rows per page
              <select aria-label="Rows per page" value={pageSize} onChange={(event) => { setPageSize(Number(event.target.value)); setPage(1); }}>
                {[10, 25, 50, 100].map((size) => <option key={size} value={size}>{size} / Page</option>)}
              </select>
            </label>
            <button type="button" disabled={page <= 1 || loading} onClick={() => setPage((current) => current - 1)}>Previous</button>
            {Array.from(new Set([1, page - 1, page, page + 1, totalPages])).filter((number) => number >= 1 && number <= totalPages).sort((first, second) => first - second).map((number) => (
              <button type="button" key={number} aria-current={number === page ? "page" : undefined} disabled={loading} onClick={() => setPage(number)}>{number}</button>
            ))}
            <button type="button" disabled={page >= totalPages || loading} onClick={() => setPage((current) => current + 1)}>Next</button>
          </div>
        </div>
      </section>
    </div>
  );
}
