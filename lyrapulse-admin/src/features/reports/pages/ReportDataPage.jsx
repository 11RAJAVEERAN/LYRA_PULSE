import { useEffect, useMemo, useState } from 'react'
import { CalendarDays, ChevronDown as SortDown, ChevronUp, ChevronsUpDown, Download, FileText, Search } from 'lucide-react'
import { colors, palette } from '../../../theme/colors'
import { typography } from '../../../theme/typography'
import { ReportTableStyles } from '../components/ReportTableStyles'
import { downloadReport, reportsApi } from '../api/reportsApi'

const REPORT_COLUMNS = {
  'daily-punch': [
    { key: 'name', label: 'Employee', sort: 'employee_name' },
    { key: 'employee_code', label: 'Employee ID' },
    { key: 'role', label: 'Roles', sort: 'designation' },
    { key: 'department', label: 'Department' },
    { key: 'branch', label: 'Branch' },
  ],
  'shift-wise': [
    { key: 'name', label: 'Employee', sort: 'employee_name' },
    { key: 'employee_code', label: 'Employee ID' },
    { key: 'role', label: 'Roles', sort: 'designation' },
    { key: 'department', label: 'Department' },
    { key: 'date', label: 'Date' }, { key: 'day', label: 'Day' },
    { key: 'shift', label: 'Shift' }, { key: 'from', label: 'From' },
    { key: 'to', label: 'To' }, { key: 'break_from', label: 'Break From' },
    { key: 'break_to', label: 'Break To' }, { key: 'first_punch', label: 'First Punch' },
  ],
  'working-hours': [
    { key: 'name', label: 'Employee', sort: 'employee_name' },
    { key: 'employee_code', label: 'Employee ID' },
    { key: 'role', label: 'Roles', sort: 'designation' },
    { key: 'department', label: 'Department' },
    { key: 'total_working_display', label: 'Total Working Hours' },
    { key: 'total_break_display', label: 'Total Break Hours' },
  ],
  muster: [
    { key: 'name', label: 'Employee', sort: 'employee_name' },
    { key: 'employee_code', label: 'Employee ID' },
    { key: 'role', label: 'Roles', sort: 'designation' },
    { key: 'department', label: 'Department' },
    { key: 'full_days', label: 'Full Days' }, { key: 'half_days', label: 'Half Days' },
    { key: 'absent_days', label: 'Absent Days' }, { key: 'week_off_days', label: 'Week Off' },
    { key: 'leave_days', label: 'Leaves' }, { key: 'holiday_days', label: 'Holidays' },
  ],
  'branch-wise-punch': [
    { key: 'name', label: 'Employee', sort: 'employee_name' },
    { key: 'employee_code', label: 'Employee Code' },
    { key: 'role', label: 'Roles', sort: 'designation' },
    { key: 'department', label: 'Department' }, { key: 'branch', label: 'Branch' },
  ],
  'leave-taken': [
    { key: 'name', label: 'Employee', sort: 'employee_name' },
    { key: 'employee_code', label: 'Employee ID' },
    { key: 'role', label: 'Roles' }, { key: 'leave_type', label: 'Leave Type' },
    { key: 'start_date', label: 'From Date' }, { key: 'end_date', label: 'To Date' },
    { key: 'days', label: 'Days' }, { key: 'status', label: 'Status' },
  ],
}

const todayIso = () => {
  const today = new Date()
  return `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`
}
const earlierIso = (days) => {
  const date = new Date()
  date.setDate(date.getDate() - days)
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
}
const showDate = (value) => value ? String(value).split('-').reverse().join('-') : '-'
const showValue = (value) => value === null || value === undefined || value === '' ? '-' : value

export default function ReportDataPage({ report, title }) {
  const [fromDate, setFromDate] = useState(earlierIso(27))
  const [toDate, setToDate] = useState(todayIso())
  const [branch, setBranch] = useState('')
  const [search, setSearch] = useState('')
  const [filters, setFilters] = useState({ start_date: earlierIso(27), end_date: todayIso(), branch: '', search: '' })
  const [branches, setBranches] = useState([])
  const [dates, setDates] = useState([])
  const [rows, setRows] = useState([])
  const [count, setCount] = useState(0)
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [totalPages, setTotalPages] = useState(1)
  const [sort, setSort] = useState({ field: 'employee_name', descending: false })
  const [loading, setLoading] = useState(true)
  const [branchError, setBranchError] = useState('')
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [exporting, setExporting] = useState('')

  useEffect(() => {
    const controller = new AbortController()
    reportsApi.branches(controller.signal)
      .then((data) => setBranches(Array.isArray(data) ? data : []))
      .catch((requestError) => {
        if (requestError.name !== 'CanceledError') setBranchError('Branch options could not be loaded.')
      })
    return () => controller.abort()
  }, [])

  useEffect(() => {
    const controller = new AbortController()
    const params = { ...filters, page, page_size: pageSize, ordering: `${sort.descending ? '-' : ''}${sort.field}` }
    if (!params.branch) delete params.branch
    if (!params.search) delete params.search
    setLoading(true)
    setError('')
    reportsApi.list(report, params, controller.signal)
      .then((data) => {
        setRows(data.results ?? [])
        setDates(data.dates ?? [])
        setCount(data.count ?? 0)
        setTotalPages(data.total_pages ?? 1)
        setNotice(data.source_available === false ? data.message : data.leave_holiday_source_available === false ? 'Leave and holiday totals are unavailable because this project has no persisted leave or holiday records.' : '')
      })
      .catch((requestError) => {
        if (requestError.name !== 'CanceledError') {
          setRows([])
          setCount(0)
          setError(requestError.response?.data?.message || requestError.response?.data?.detail || 'Could not load this report. Please try again.')
        }
      })
      .finally(() => { if (!controller.signal.aborted) setLoading(false) })
    return () => controller.abort()
  }, [filters, page, pageSize, report, sort])

  const columns = useMemo(() => {
    const base = REPORT_COLUMNS[report] ?? []
    const datesColumn = dates.map((date, index) => ({
      key: `day-${index}`,
      label: `${showDate(date)} (${new Date(`${date}T12:00:00`).toLocaleDateString('en-US', { weekday: 'short' })})`,
      value: (row) => row.values?.[index],
    }))
    if (report === 'daily-punch' || report === 'branch-wise-punch') return [...base, ...datesColumn]
    if (report === 'working-hours') return [...base, ...datesColumn]
    if (report === 'muster') return [...base, ...datesColumn]
    return base
  }, [dates, report])

  const applyFilters = () => {
    const days = (Date.parse(`${toDate}T00:00:00`) - Date.parse(`${fromDate}T00:00:00`)) / 86400000 + 1
    if (!fromDate || !toDate || fromDate > toDate || toDate > todayIso() || days > 92) {
      setError('Select a valid date range of up to 92 days ending today or earlier.')
      return
    }
    setFilters({ start_date: fromDate, end_date: toDate, branch, search: search.trim() })
    setPage(1)
  }

  const toggleSort = (field) => {
    setSort((current) => ({ field, descending: current.field === field ? !current.descending : false }))
    setPage(1)
  }

  const exportReport = async (format) => {
    setExporting(format)
    setError('')
    const params = { ...filters, export_format: format, ordering: `${sort.descending ? '-' : ''}${sort.field}` }
    if (!params.branch) delete params.branch
    if (!params.search) delete params.search
    try {
      const downloaded = await reportsApi.export(report, params)
      downloadReport(downloaded, `${report}.${format}`)
    } catch (requestError) {
      setError(requestError.response?.status ? 'The export could not be generated.' : 'Could not connect to the report service.')
    } finally {
      setExporting('')
    }
  }

  const renderCell = (row, column) => {
    const value = column.value ? column.value(row) : row[column.key]
    if (report === 'attendance-master' && column.key === 'date') return showDate(value)
    if (report === 'shift-wise' && column.key === 'date') return showDate(value)
    if ((column.key === 'leave_days' || column.key === 'holiday_days') && value === null) return 'Unavailable'
    return showValue(value)
  }

  return (
    <div className="report-data-page">
      <ReportTableStyles />
      <style>{`
        .report-data-page { width:100%; min-width:0; color:${colors.textPrimary}; font-family:${typography.fontFamily}; font-size:${typography.body2.fontSize}; }
        .report-data-page * { box-sizing:border-box; }
        .rd-header { display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px; margin-bottom:14px; }
        .rd-title { margin:0; color:${colors.primary}; font-size:24px; font-weight:700; line-height:1.25; }
        .rd-actions { display:flex; gap:8px; }
        .rd-export,.rd-search { height:40px; padding:0 14px; display:inline-flex; align-items:center; gap:8px; border:1px solid ${colors.border}; border-radius:8px; background:${palette?.lyra?.primaryGradient || colors.primaryBlue}; color:${colors.surface}; font:inherit; font-weight:600; cursor:pointer; }
        .rd-export:disabled { opacity:.55; cursor:default; }
        .rd-card { width:100%; margin-bottom:14px; background:${colors.surface}; border:1px solid ${colors.border}; border-radius:10px; }
        .rd-filters { display:flex; align-items:center; flex-wrap:wrap; gap:9px; padding:16px; }
        .rd-date { height:40px; display:flex; align-items:center; gap:8px; padding:0 10px; border:1px solid ${colors.border}; border-radius:7px; }
        .rd-date input { width:135px; border:0; outline:0; color:${colors.textPrimary}; background:transparent; font:inherit; }
        .rd-select,.rd-input { height:40px; min-width:190px; padding:0 12px; border:1px solid ${colors.border}; border-radius:7px; background:${colors.surface}; color:${colors.textPrimary}; font:inherit; }
        .rd-table-card { width:100%; overflow:hidden; border:1px solid ${colors.border}; border-radius:10px; background:${colors.surface}; }
        .rd-scroll { max-height:70vh; overflow:auto; }
        .rd-table { width:max-content; min-width:100%; border-collapse:separate; border-spacing:0; font-size:13px; }
        .rd-table th { position:sticky; top:0; z-index:2; padding:12px 14px; white-space:nowrap; background:${colors.infoBackground}; color:${colors.primary}; border-bottom:1px solid ${colors.border}; text-align:left; }
        .rd-table td { padding:12px 14px; white-space:nowrap; background:${colors.surface}; border-bottom:1px solid ${colors.border}; }
        .rd-sort { display:flex; align-items:center; justify-content:space-between; gap:10px; width:100%; padding:0; border:0; background:transparent; color:inherit; font:inherit; font-weight:inherit; cursor:pointer; }
        .rd-message { margin:0 0 12px; padding:10px 14px; border-radius:8px; background:${colors.infoBackground}; color:${colors.textSecondary}; }
        .rd-error { color:#982020; background:#fff1f0; }
        .rd-empty { min-width:300px; height:100px; text-align:center; color:${colors.textSecondary}; }
        .rd-footer { display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:12px; padding:12px 16px; border-top:1px solid ${colors.border}; color:${colors.textSecondary}; }
        .rd-pagination { display:flex; align-items:center; flex-wrap:wrap; gap:7px; }
        .rd-pagination button,.rd-pagination select { min-height:34px; padding:0 10px; border:1px solid ${colors.border}; border-radius:6px; background:${colors.surface}; color:${colors.textPrimary}; font:inherit; cursor:pointer; }
        .rd-pagination button[aria-current=page] { color:white; background:${colors.primaryBlue}; }
        .rd-pagination button:disabled { opacity:.5; cursor:default; }
        @media(max-width:700px) { .rd-header { align-items:flex-start; flex-direction:column; } .rd-filters { align-items:stretch; flex-direction:column; } .rd-date { justify-content:space-between; } .rd-date input { width:42%; } .rd-select,.rd-input,.rd-search { width:100%; } }
      `}</style>

      <header className="rd-header">
        <h1 className="rd-title">{title}</h1>
        <div className="rd-actions">
          <button className="rd-export" type="button" disabled={loading || Boolean(exporting)} onClick={() => exportReport('xlsx')}><Download size={16} />{exporting === 'xlsx' ? 'Exporting…' : 'Export Excel'}</button>
          <button className="rd-export" type="button" disabled={loading || Boolean(exporting)} onClick={() => exportReport('pdf')}><FileText size={16} />{exporting === 'pdf' ? 'Exporting…' : 'Export PDF'}</button>
        </div>
      </header>

      <section className="rd-card">
        <div className="rd-filters">
          <div className="rd-date"><CalendarDays size={17} /><input type="date" aria-label="From date" value={fromDate} max={toDate} onChange={(event) => setFromDate(event.target.value)} /><span>→</span><input type="date" aria-label="To date" value={toDate} min={fromDate} max={todayIso()} onChange={(event) => setToDate(event.target.value)} /></div>
          <select className="rd-select" aria-label="Choose Branch" value={branch} onChange={(event) => setBranch(event.target.value)} disabled={Boolean(branchError)}>
            <option value="">Choose Branch</option>{branches.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
          </select>
          <input className="rd-input" aria-label="Search employee" placeholder="Search employee…" value={search} onChange={(event) => setSearch(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter') applyFilters() }} />
          <button className="rd-search" type="button" onClick={applyFilters}><Search size={16} />Search</button>
        </div>
      </section>

      {branchError && <div className="rd-message rd-error" role="alert">{branchError}</div>}
      {notice && <div className="rd-message" role="status">{notice}</div>}
      {error && !loading && <div className="rd-message rd-error" role="alert">{error}</div>}
      <section className="rd-table-card">
        <div className="rd-scroll">
          <table className="rd-table">
            <thead><tr>{columns.map((column) => <th key={column.key}>{column.sort ? <button className="rd-sort" type="button" onClick={() => toggleSort(column.sort)}>{column.label}{sort.field === column.sort ? sort.descending ? <SortDown size={15} /> : <ChevronUp size={15} /> : <ChevronsUpDown size={15} />}</button> : column.label}</th>)}</tr></thead>
            <tbody>
              {loading ? <tr><td colSpan={columns.length} className="rd-empty">Loading report…</td></tr> : rows.length ? rows.map((row, rowIndex) => <tr key={`${row.employee_code ?? row.id ?? row.date}-${row.date ?? rowIndex}`}>{columns.map((column) => <td key={column.key}>{renderCell(row, column)}</td>)}</tr>) : <tr><td colSpan={columns.length} className="rd-empty">{report === 'leave-taken' ? 'No leave records found.' : 'No records found for this filter.'}</td></tr>}
            </tbody>
          </table>
        </div>
        <footer className="rd-footer">
          <span>Showing {count === 0 ? 0 : (page - 1) * pageSize + 1}–{Math.min(page * pageSize, count)} of {count} Results</span>
          <div className="rd-pagination">
            <label>Rows per page <select value={pageSize} aria-label="Rows per page" onChange={(event) => { setPageSize(Number(event.target.value)); setPage(1) }}>{[10, 25, 50, 100].map((size) => <option key={size} value={size}>{size}</option>)}</select></label>
            <button type="button" disabled={page <= 1 || loading} onClick={() => setPage((current) => current - 1)}>Previous</button>
            {Array.from(new Set([1, page - 1, page, page + 1, totalPages])).filter((number) => number >= 1 && number <= totalPages).sort((a, b) => a - b).map((number) => <button type="button" key={number} aria-current={page === number ? 'page' : undefined} disabled={loading} onClick={() => setPage(number)}>{number}</button>)}
            <button type="button" disabled={page >= totalPages || loading} onClick={() => setPage((current) => current + 1)}>Next</button>
          </div>
        </footer>
      </section>
    </div>
  )
}
