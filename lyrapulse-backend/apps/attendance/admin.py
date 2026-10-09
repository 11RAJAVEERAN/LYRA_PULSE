from django.contrib import admin

from .models import Attendance


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ("employee", "branch", "device", "attendance_date", "check_in_at", "check_out_at")
    list_filter = ("branch", "device", "attendance_date")
    search_fields = ("employee__employee_code", "employee__name")
