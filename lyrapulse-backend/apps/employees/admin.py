from django.contrib import admin

from .models import Employee, EmployeeDocument, EmployeeType, PayrollGroup


@admin.register(Employee)
class EmployeeAdmin(admin.ModelAdmin):
    list_display = ("employee_code", "user", "branch", "department", "is_active")
    search_fields = ("employee_code", "user__phone_number", "user__first_name", "user__last_name")
    list_filter = ("is_active", "branch", "department")
    ordering = ("employee_code",)


@admin.register(EmployeeType)
class EmployeeTypeAdmin(admin.ModelAdmin):
    list_display = ("name", "is_active")
    list_filter = ("is_active",)
    search_fields = ("name",)


@admin.register(PayrollGroup)
class PayrollGroupAdmin(admin.ModelAdmin):
    list_display = ("name", "is_active")
    list_filter = ("is_active",)
    search_fields = ("name",)


@admin.register(EmployeeDocument)
class EmployeeDocumentAdmin(admin.ModelAdmin):
    list_display = ("employee", "doc_type", "side", "original_name", "size", "uploaded_at")
    list_filter = ("doc_type",)
    readonly_fields = ("file", "original_name", "content_type", "size", "uploaded_at")