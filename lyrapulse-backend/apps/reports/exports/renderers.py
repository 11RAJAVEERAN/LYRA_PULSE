from io import BytesIO
from xml.sax.saxutils import escape

from django.http import HttpResponse
from openpyxl import Workbook
from openpyxl.cell import WriteOnlyCell
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter

from apps.branches.models import Branch

from ..services.reports import REPORT_TITLES


def _safe(value):
    value = "" if value is None else str(value)
    return "'" + value if value[:1] in ("=", "+", "-", "@", "\t", "\r") else value


def table_data(report, data):
    dates = data["dates"]
    date_headers = [f"{day:%d-%m-%Y} ({day:%A})" for day in dates]
    if report == "attendance-master":
        headers = ["Employee", "Employee ID", "Role", "Department", "Date", "Day", "First Punch", "Last Punch", "Total Working Hours", "Total Break Hours", "Status"]
        rows = [[row["employee"]["name"], row["employee"]["employee_code"],
                 row["designation"]["name"] if row.get("designation") else "",
                 row["department"]["name"] if row.get("department") else "",
                 row["attendance_date"], row["day"], row.get("first_punch_at") or "-",
                 row.get("last_punch_at") or "-", row.get("working_hours_display") or "-",
                 row.get("break_hours_display") or "-", row.get("classification_display") or "-"]
                for row in data["results"]]
    elif report == "shift-wise":
        headers = ["Employee", "Employee ID", "Role", "Department", "Date", "Day", "Shift", "From", "To", "Break From", "Break To", "First Punch"]
        rows = [[row["name"], row["employee_code"], row.get("role") or "", row.get("department") or "",
                 row["date"], row["day"], row["shift"], row["from"], row["to"], row["break_from"], row["break_to"], row["first_punch"]]
                for row in data["results"]]
    elif report == "muster":
        headers = ["Employee", "Employee ID", "Role", "Department", "Full Days", "Half Days", "Absent Days", "Week Off", "Leaves", "Holidays", *date_headers]
        rows = [[row["name"], row["employee_code"], row.get("role") or "", row.get("department") or "",
                 row["full_days"], row["half_days"], row["absent_days"], row["week_off_days"],
                 row.get("leave_days") if row.get("leave_days") is not None else "Unavailable",
                 row.get("holiday_days") if row.get("holiday_days") is not None else "Unavailable", *row["values"]]
                for row in data["results"]]
    elif report == "leave-taken":
        headers = ["Employee", "Employee ID", "Role", "Leave Type", "From Date", "To Date", "Days", "Status"]
        rows = []
    else:
        first = data["results"][0] if data["results"] else {}
        prefix = ["Employee", "Employee ID", "Role", "Department"]
        if report == "branch-wise-punch":
            prefix.append("Branch")
        if report == "working-hours":
            prefix += ["Total Working Hours", "Total Break Hours"]
        headers = prefix + date_headers
        rows = []
        for row in data["results"]:
            line = [row["name"], row["employee_code"], row.get("role") or "", row.get("department") or ""]
            if report == "branch-wise-punch":
                line.append(row.get("branch") or "")
            if report == "working-hours":
                line.extend([row.get("total_working_display") or "-", row.get("total_break_display") or "-"])
            line.extend(row.get("values", []))
            rows.append(line)
    return headers, rows


def export_report(report, data, query):
    headers, rows = table_data(report, data)
    start, end = query["start_date"], query["end_date"]
    branch_name = Branch.objects.filter(pk=query.get("branch")).values_list("name", flat=True).first() if query.get("branch") else "All branches"
    filename = f"{report}-{start.isoformat()}-to-{end.isoformat()}"
    if query["export_format"] == "xlsx":
        workbook = Workbook(write_only=True)
        sheet = workbook.create_sheet(REPORT_TITLES[report][:31])
        header = []
        for index, value in enumerate(headers, start=1):
            cell = WriteOnlyCell(sheet, value=_safe(value))
            cell.font = Font(bold=True, color="FFFFFF")
            cell.fill = PatternFill("solid", fgColor="1976D2")
            cell.alignment = Alignment(horizontal="center", vertical="center")
            sheet.column_dimensions[get_column_letter(index)].width = min(34, max(14, len(str(value)) + 2))
            header.append(cell)
        sheet.append(header)
        for row in rows:
            sheet.append([_safe(value) if isinstance(value, str) else value for value in row])
        stream = BytesIO()
        workbook.save(stream)
        response = HttpResponse(stream.getvalue(), content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        response["Content-Disposition"] = f'attachment; filename="{filename}.xlsx"'
        return response

    from reportlab.lib import colors
    from reportlab.lib.enums import TA_CENTER
    from reportlab.lib.pagesizes import landscape, letter
    from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
    from reportlab.lib.units import mm
    from reportlab.platypus import LongTable, Paragraph, SimpleDocTemplate, TableStyle

    stream = BytesIO()
    doc = SimpleDocTemplate(stream, pagesize=landscape(letter), leftMargin=8 * mm, rightMargin=8 * mm,
                            topMargin=12 * mm, bottomMargin=14 * mm)
    styles = getSampleStyleSheet()
    title = ParagraphStyle("ReportTitle", parent=styles["Title"], alignment=TA_CENTER, fontSize=14)
    meta = ParagraphStyle("ReportMeta", parent=styles["Normal"], fontSize=8)
    cell_style = ParagraphStyle("ReportCell", parent=styles["Normal"], fontSize=6, leading=7)
    story = [Paragraph(escape(REPORT_TITLES[report]), title), Paragraph(
        f"Date range: {start:%d %b %Y} to {end:%d %b %Y} &nbsp;&nbsp; Branch: {escape(branch_name or 'All branches')}", meta)]
    if data.get("source_available") is False:
        story.append(Paragraph(escape(data.get("message", "No records available.")), meta))
    matrix = [headers]
    matrix.extend([[Paragraph(escape(_safe(value)), cell_style) for value in row] for row in rows])
    widths = [max(13 * mm, min(38 * mm, 250 * mm / max(len(headers), 1)))] * len(headers)
    table = LongTable(matrix, repeatRows=1, colWidths=widths)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#eaf4fc")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#153b5b")),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 6), ("GRID", (0, 0), (-1, -1), .25, colors.HexColor("#cbd5e1")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f8fafc")]),
    ]))

    def page_number(canvas, document):
        canvas.saveState()
        canvas.setFont("Helvetica", 8)
        canvas.drawRightString(landscape(letter)[0] - 8 * mm, 7 * mm, f"Page {document.page}")
        canvas.restoreState()

    story.append(table)
    doc.build(story, onFirstPage=page_number, onLaterPages=page_number)
    response = HttpResponse(stream.getvalue(), content_type="application/pdf")
    response["Content-Disposition"] = f'attachment; filename="{filename}.pdf"'
    return response
