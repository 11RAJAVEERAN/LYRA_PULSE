import { colors } from '../theme/colors'
import { typography } from '../theme/typography'

// Keep the reference report tables consistent with the existing Employees table.
export function ReportTableStyles() {
  return (
    <style>{`
      .am-page .am-table,
      .daily-punch-page .daily-punch-table,
      .shift-wise-page .shift-wise-table,
      .branch-punch-page .branch-punch-table,
      .leave-report-page .leave-report-table {
        font-family: ${typography.fontFamily};
        font-size: ${typography.body2.fontSize};
        color: ${colors.textPrimary};
      }
      .am-page .am-table th,
      .daily-punch-page .daily-punch-table th,
      .shift-wise-page .shift-wise-table th,
      .branch-punch-page .branch-punch-table th,
      .leave-report-page .leave-report-table th {
        min-height: 40px;
        padding: 8px 12px;
        background-color: ${colors.infoBackground};
        color: ${colors.primary};
        border-bottom: 1px solid ${colors.border};
        font-family: ${typography.fontFamily};
        font-size: 0.8125rem;
        font-weight: 600;
        letter-spacing: 0;
        text-align: left;
        vertical-align: middle;
      }
      .am-page .am-table td,
      .daily-punch-page .daily-punch-table td,
      .shift-wise-page .shift-wise-table td,
      .branch-punch-page .branch-punch-table td,
      .leave-report-page .leave-report-table td {
        padding: 10px 12px;
        color: ${colors.textPrimary};
        border-bottom: 1px solid ${colors.border};
        font-family: ${typography.fontFamily};
        font-size: ${typography.body2.fontSize};
        font-weight: 450;
        line-height: ${typography.body2.lineHeight};
        vertical-align: middle;
      }
      .am-page .am-table tbody tr,
      .daily-punch-page .daily-punch-table tbody tr,
      .shift-wise-page .shift-wise-table tbody tr,
      .branch-punch-page .branch-punch-table tbody tr,
      .leave-report-page .leave-report-table tbody tr {
        height: 64px;
      }
      .am-page .am-table tbody tr:hover td,
      .daily-punch-page .daily-punch-table tbody tr:hover td,
      .shift-wise-page .shift-wise-table tbody tr:hover td,
      .branch-punch-page .branch-punch-table tbody tr:hover td,
      .leave-report-page .leave-report-table tbody tr:hover td {
        background-color: ${colors.hover};
      }
      @media (max-width: 600px) {
        .am-page .am-table th, .am-page .am-table td,
        .daily-punch-page .daily-punch-table th, .daily-punch-page .daily-punch-table td,
        .shift-wise-page .shift-wise-table th, .shift-wise-page .shift-wise-table td,
        .branch-punch-page .branch-punch-table th, .branch-punch-page .branch-punch-table td,
        .leave-report-page .leave-report-table th, .leave-report-page .leave-report-table td {
          padding-left: 10px;
          padding-right: 10px;
        }
      }
    `}</style>
  )
}
