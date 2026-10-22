from django.contrib import admin

from .models import EmployeeFingerprint, FingerprintEnrollment


@admin.register(EmployeeFingerprint)
class EmployeeFingerprintAdmin(admin.ModelAdmin):
    list_display = ("employee", "device", "finger", "fingerprint_slot", "is_active")
    list_filter = ("is_active", "device", "finger")
    search_fields = ("employee__employee_code", "device__device_id")


@admin.register(FingerprintEnrollment)
class FingerprintEnrollmentAdmin(admin.ModelAdmin):
    list_display = ("id", "employee", "device", "finger", "status", "failure_summary", "expires_at")
    list_filter = ("status", "device", "finger")
    search_fields = ("employee__employee_code", "device__device_id")
    readonly_fields = ("created_at", "updated_at", "started_at", "completed_at", "failure_reason")

    @admin.display(description="Failure details")
    def failure_summary(self, obj):
        if obj.failure_reason == "DUPLICATE_FINGERPRINT":
            return "Duplicate fingerprint: this template is already stored; choose a different finger."
        if obj.failure_reason:
            return obj.failure_reason.replace("_", " ").title()
        return ""
