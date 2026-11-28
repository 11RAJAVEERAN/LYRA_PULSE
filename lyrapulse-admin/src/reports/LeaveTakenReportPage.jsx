import { useState } from "react";
import {
  CalendarDays,
  ArrowUpDown,
  SlidersHorizontal,
  Search,
  Download,
  FileText,
} from "lucide-react";

import { colors, palette } from "../theme/colors";
import { typography } from "../theme/typography";
import { ReportTableStyles } from "./ReportTableStyles";

const styles = `
.leave-report-page {
  width: 100%;
  min-height: 100%;
  padding: 0;
  background: transparent;
  font-family: ${typography.fontFamily};
  color: ${colors.textPrimary};
}

.leave-report-page * {
  box-sizing: border-box;
}

.leave-report-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 14px;
}

.leave-report-title {
  margin: 0;
  padding: 0;
  font-size: 24px;
  font-weight: 700;
  letter-spacing: -0.015em;
  line-height: 1.25;
  color: ${colors.primary || "#1a237e"};
}

.leave-report-header-actions {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.leave-report-export-btn {
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

.leave-report-export-btn:hover {
  opacity: 0.94;
  box-shadow: ${palette?.lyra?.actionShadow || "0 4px 10px rgba(37, 99, 235, 0.28)"};
}

.leave-report-export-btn:active {
  transform: translateY(1px);
}

.leave-report-filter-card {
  width: 100%;
  margin-bottom: 16px;
  background: ${colors.surface};
  border: 1px solid ${colors.border};
  border-radius: 12px;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
}

.leave-report-table-card {
  width: 100%;
  min-height: 500px;
  background: ${colors.surface};
  border: 1px solid ${colors.border};
  border-radius: 12px;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
  overflow: hidden;
}

.leave-report-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 12px;
  padding: 16px 20px;
}

.leave-report-filters {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 10px;
}

.leave-report-date {
  height: 40px;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 12px;
  border: 1px solid ${colors.border};
  border-radius: 8px;
  background: ${colors.surface};
}

.leave-report-date:focus-within {
  border-color: ${colors.primaryBlue};
  box-shadow: 0 0 0 3px ${colors.focusSubtle};
}

.leave-report-date svg {
  color: ${colors.textSecondary};
  flex-shrink: 0;
}

.leave-report-date input {
  width: 122px;
  border: none;
  outline: none;
  color: ${colors.textPrimary};
  font-family: ${typography.fontFamily};
  font-size: 13px;
  background: transparent;
}

.leave-date-arrow {
  color: ${colors.disabled || colors.textSecondary};
}

.leave-report-btn {
  height: 40px;
  padding: 0 16px;
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

.leave-primary-btn {
  min-width: 110px;
  border: none;
  color: ${colors.surface};
  background: ${palette?.lyra?.primaryGradient || `linear-gradient(90deg, ${colors.primary}, ${colors.secondary})`};
}

.leave-primary-btn:hover {
  opacity: 0.94;
  box-shadow: ${palette?.lyra?.actionShadow || `0 5px 14px ${colors.selection}`};
}

.leave-report-table-wrapper {
  width: 100%;
  overflow-x: auto;
}

.leave-report-table {
  width: 100%;
  min-width: 720px;
  border-collapse: separate;
  border-spacing: 0;
  table-layout: fixed;
  text-align: left;
  font-size: 13px;
}

.leave-report-table thead {
  background: ${colors.infoBackground};
}

.leave-report-table th {
  height: 54px;
  padding: 10px 16px;
  color: ${colors.primary};
  font-size: 13px;
  font-weight: 700;
  border-bottom: 1px solid ${colors.border};
  vertical-align: middle;
  white-space: nowrap;
}

.leave-report-table th:nth-child(1) {
  width: 38%;
  border-right: 1px solid ${colors.border};
}

.leave-report-table th:nth-child(2) {
  width: 38%;
  border-right: 1px solid ${colors.border};
}

.leave-report-table th:nth-child(3) {
  width: 24%;
}

.leave-table-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  white-space: nowrap;
}

.leave-table-heading-actions {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

.leave-table-heading svg {
  color: ${colors.textSecondary};
  cursor: pointer;
  flex-shrink: 0;
}

.leave-table-filter-icon {
  padding-left: 8px;
  border-left: 1px solid ${colors.border};
}

.leave-empty-cell {
  padding: 0 !important;
}

.leave-empty-state {
  min-height: 390px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 24px;
}

.leave-empty-icon {
  width: 68px;
  height: 68px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: ${colors.infoBackground};
  color: ${colors.primaryBlue};
  border-radius: 50%;
  margin-bottom: 12px;
}

.leave-empty-state h3 {
  margin: 0;
  color: ${colors.textPrimary};
  font-size: 18px;
  font-weight: 600;
}

.leave-empty-state p {
  margin: 6px 0 0;
  color: ${colors.textSecondary};
  font-size: 13px;
}

@media (max-width: 768px) {
  .leave-report-header {
    align-items: stretch;
    flex-direction: column;
    margin-bottom: 12px;
  }

  .leave-report-title {
    font-size: 20px;
  }

  .leave-report-header-actions {
    width: 100%;
  }

  .leave-report-export-btn {
    flex: 1;
    padding: 0 12px;
    font-size: 12px;
  }

  .leave-report-filter-card {
    margin-bottom: 12px;
  }

  .leave-report-toolbar {
    align-items: stretch;
    flex-direction: column;
    padding: 12px 16px;
  }

  .leave-report-filters {
    width: 100%;
    align-items: stretch;
    flex-direction: column;
  }

  .leave-report-date {
    width: 100%;
    justify-content: space-between;
  }

  .leave-report-date input {
    width: 42%;
  }

  .leave-primary-btn {
    width: 100%;
  }
}

@media print {
  body * {
    visibility: hidden;
  }

  .leave-report-header,
  .leave-report-header .leave-report-title,
  .leave-report-table-card,
  .leave-report-table-card * {
    visibility: visible;
  }

  .leave-report-header-actions,
  .leave-report-filter-card {
    display: none !important;
  }

  .leave-report-table-card {
    position: static;
    width: 100%;
    border: 0;
    box-shadow: none;
  }
}
`;

export default function LeaveTakenReportPage() {
  const [fromDate, setFromDate] = useState("2026-10-01");
  const [toDate, setToDate] = useState("2026-10-29");
  const [searched, setSearched] = useState(false);

  const handleSearch = () => {
    setSearched(true);
  };

  const handleExcelExport = () => {
    const csv = [["Employee", "Roles", "LWP"]]
      .map((row) => row.join(","))
      .join("\n");

    const blob = new Blob([csv], {
      type: "text/csv;charset=utf-8;",
    });

    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");

    link.href = url;
    link.download = "Leave_Taken_Report.csv";
    link.click();

    URL.revokeObjectURL(url);
  };

  const handlePDFExport = () => {
    window.print();
  };

  return (
    <>
      <style>{styles}</style>
      <ReportTableStyles />

      <div className="leave-report-page">
        <div className="leave-report-header">
          <h1 className="leave-report-title">Leave Taken Report</h1>

          <div className="leave-report-header-actions">
            <button
              type="button"
              className="leave-report-export-btn"
              onClick={handleExcelExport}
            >
              <Download size={16} />
              <span>Export Excel</span>
            </button>

            <button
              type="button"
              className="leave-report-export-btn"
              onClick={handlePDFExport}
            >
              <FileText size={16} />
              <span>Export PDF</span>
            </button>
          </div>
        </div>

        <section className="leave-report-filter-card">
          <div className="leave-report-toolbar">
            <div className="leave-report-filters">
              <div className="leave-report-date">
                <CalendarDays size={17} />

                <input
                  type="date"
                  value={fromDate}
                  onChange={(e) => setFromDate(e.target.value)}
                />

                <span className="leave-date-arrow">→</span>

                <input
                  type="date"
                  value={toDate}
                  onChange={(e) => setToDate(e.target.value)}
                />
              </div>

              <button
                type="button"
                className="leave-report-btn leave-primary-btn"
                onClick={handleSearch}
              >
                Search
              </button>
            </div>
          </div>
        </section>

        <section className="leave-report-table-card">
          <div className="leave-report-table-wrapper">
            <table className="leave-report-table">
              <thead>
                <tr>
                  <th>
                    <div className="leave-table-heading">
                      <span>Employee</span>
                      <div className="leave-table-heading-actions">
                        <ArrowUpDown size={15} />
                        <span className="leave-table-filter-icon">
                          <SlidersHorizontal size={14} />
                        </span>
                      </div>
                    </div>
                  </th>

                  <th>
                    <div className="leave-table-heading">
                      <span>Roles</span>
                      <div className="leave-table-heading-actions">
                        <ArrowUpDown size={15} />
                        <span className="leave-table-filter-icon">
                          <SlidersHorizontal size={14} />
                        </span>
                      </div>
                    </div>
                  </th>

                  <th>LWP</th>
                </tr>
              </thead>

              <tbody>
                <tr>
                  <td colSpan={3} className="leave-empty-cell">
                    <div className="leave-empty-state">
                      <div className="leave-empty-icon">
                        <Search size={26} />
                      </div>

                      <h3>No Data Found</h3>

                      <p>
                        {searched
                          ? `No leave records found for ${fromDate} to ${toDate}.`
                          : "No leave records found for the selected date range."}
                      </p>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </>
  );
}
