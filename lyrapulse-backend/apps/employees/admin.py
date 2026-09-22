from django.contrib import admin

from .models import Employee


@admin.register(Employee)
class EmployeeAdmin(admin.ModelAdmin):
    list_display = ("employee_code", "user", "branch", "department", "is_active")
    search_fields = ("employee_code", "user__phone_number", "user__first_name", "user__last_name")
    list_filter = ("is_active", "branch", "department")
    ordering = ("employee_code",)