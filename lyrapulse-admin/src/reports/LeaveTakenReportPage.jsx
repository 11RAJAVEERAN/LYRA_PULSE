import { useState } from "react";
import {
  CalendarDays,
  ArrowUpDown,
  SlidersHorizontal,
  Search,
  FileSpreadsheet,
  FileText,
} from "lucide-react";

import { colors } from "../theme/colors";
import { typography } from "../theme/typography";

const styles = `
.leave-report-page {
  width: 100%;
  min-height: 100%;
  padding: 18px;
  background: ${colors.background};
  font-family: ${typography.fontFamily};
  color: ${colors.textPrimary};
}

.leave-report-card {
  width: 100%;
  min-height: 610px;
  background: ${colors.surface};
  border: 1px solid ${colors.border};
  border-radius: 12px;
  overflow: hidden;
}

.leave-report-title {
  padding: 20px 24px;
  font-size: 21px;
  font-weight: 650;
  color: ${colors.textPrimary};
}

.leave-report-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
  padding: 20px 24px;
}

.leave-report-filters,
.leave-report-export {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
}

.leave-report-date {
  height: 44px;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 12px;
  border: 1px solid ${colors.border};
  border-radius: 8px;
  background: ${colors.surface};
}

.leave-report-date svg {
  color: ${colors.textSecondary};
  flex-shrink: 0;
}

.leave-report-date input {
  width: 116px;
  border: none;
  outline: none;
  color: ${colors.textPrimary};
  font-family: ${typography.fontFamily};
  font-size: 14px;
  background: transparent;
}

.leave-date-arrow {
  color: ${colors.textSecondary};
}

.leave-report-btn {
  min-height: 44px;
  padding: 0 20px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border-radius: 8px;
  font-family: ${typography.fontFamily};
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: 0.2s;
}

.leave-primary-btn {
  min-width: 116px;
  border: none;
  color: ${colors.surface};
  background: linear-gradient(90deg, ${colors.primary}, ${colors.secondary});
}

.leave-primary-btn:hover {
  opacity: 0.9;
  box-shadow: 0 5px 14px ${colors.selection};
}

.leave-outline-btn {
  border: 1px solid ${colors.border};
  color: ${colors.textPrimary};
  background: ${colors.surface};
}

.leave-outline-btn:hover {
  background: ${colors.hover};
  border-color: ${colors.primaryBlue};
}

.leave-report-table-wrapper {
  width: 100%;
  overflow-x: auto;
  border-top: 1px solid ${colors.border};
}

.leave-report-table {
  width: 100%;
  border-collapse: collapse;
  table-layout: fixed;
  text-align: left;
}

.leave-report-table thead {
  background: ${colors.infoBackground};
}

.leave-report-table th {
  height: 62px;
  padding: 12px 18px;
  color: ${colors.primary};
  font-size: 14px;
  font-weight: 600;
  border-bottom: 1px solid ${colors.border};
}

.leave-report-table th:nth-child(1) {
  width: 38%;
}

.leave-report-table th:nth-child(2) {
  width: 38%;
}

.leave-report-table th:nth-child(3) {
  width: 24%;
  border-left: 1px solid ${colors.border};
}

.leave-table-heading {
  display: flex;
  align-items: center;
  gap: 12px;
}

.leave-table-heading svg {
  color: ${colors.textSecondary};
  cursor: pointer;
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
}

.leave-empty-icon {
  width: 74px;
  height: 74px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: ${colors.infoBackground};
  color: ${colors.primaryBlue};
  border-radius: 50%;
  margin-bottom: 10px;
}

.leave-empty-state h3 {
  margin: 0;
  color: ${colors.textPrimary};
  font-size: 20px;
  font-weight: 600;
}

.leave-empty-state p {
  margin: 7px 0 0;
  color: ${colors.textSecondary};
  font-size: 13px;
}

@media (max-width: 768px) {
  .leave-report-page {
    padding: 10px;
  }

  .leave-report-toolbar {
    align-items: flex-start;
    flex-direction: column;
    padding: 16px;
  }

  .leave-report-filters,
  .leave-report-export {
    width: 100%;
  }

  .leave-report-date {
    max-width: 100%;
  }

  .leave-report-date input {
    width: 105px;
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

      <div className="leave-report-page">
        <div className="leave-report-card">
          <div className="leave-report-title">Leave Taken Report</div>

          <div className="leave-report-toolbar">
            <div className="leave-report-filters">
              <div className="leave-report-date">
                <CalendarDays size={18} />

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
                className="leave-report-btn leave-primary-btn"
                onClick={handleSearch}
              >
                Search
              </button>
            </div>

            <div className="leave-report-export">
              <button
                className="leave-report-btn leave-outline-btn"
                onClick={handleExcelExport}
              >
                <FileSpreadsheet size={17} />
                Export Excel
              </button>

              <button
                className="leave-report-btn leave-outline-btn"
                onClick={handlePDFExport}
              >
                <FileText size={17} />
                Export PDF
              </button>
            </div>
          </div>

          <div className="leave-report-table-wrapper">
            <table className="leave-report-table">
              <thead>
                <tr>
                  <th>
                    <div className="leave-table-heading">
                      Employee
                      <ArrowUpDown size={18} />
                      <SlidersHorizontal size={18} />
                    </div>
                  </th>

                  <th>
                    <div className="leave-table-heading">
                      Roles
                      <ArrowUpDown size={18} />
                      <SlidersHorizontal size={18} />
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
                        <Search size={27} />
                      </div>

                      <h3>No Data Found</h3>

                      <p>No leave records found for the selected date range.</p>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </>
  );
}
