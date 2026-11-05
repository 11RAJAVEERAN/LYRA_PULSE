from django.contrib import admin
from django.utils.html import format_html

from .models import Attendance


@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    """Attendance is evidence created by the mobile API, so every field is read-only and rows cannot be added here."""

    list_display = (
        "employee", "branch", "attendance_date", "check_in_at", "check_in_location_verified",
        "check_out_at", "check_out_location_verified",
    )
    list_select_related = ("employee__user", "branch")
    list_filter = ("attendance_date", "branch", "check_in_location_verified", "check_out_location_verified")
    search_fields = (
        "employee__employee_code", "employee__user__phone_number",
        "employee__user__first_name", "employee__user__last_name",
    )
    date_hierarchy = "attendance_date"
    ordering = ("-attendance_date", "-check_in_at")

    fieldsets = (
        ("Attendance", {"fields": ("employee", "branch", "attendance_date")}),
        ("Check-in information", {"fields": (
            "check_in_at", ("check_in_latitude", "check_in_longitude"), "check_in_accuracy",
            "check_in_distance_meters", "check_in_location_verified", "check_in_photo_preview",
        )}),
        ("Check-out information", {"fields": (
            "check_out_at", ("check_out_latitude", "check_out_longitude"), "check_out_accuracy",
            "check_out_distance_meters", "check_out_location_verified", "check_out_photo_preview",
        )}),
        ("System information", {"fields": ("created_at", "updated_at")}),
    )
    readonly_fields = (
        "employee", "branch", "attendance_date",
        "check_in_at", "check_in_latitude", "check_in_longitude", "check_in_accuracy",
        "check_in_distance_meters", "check_in_location_verified", "check_in_photo_preview",
        "check_out_at", "check_out_latitude", "check_out_longitude", "check_out_accuracy",
        "check_out_distance_meters", "check_out_location_verified", "check_out_photo_preview",
        "created_at", "updated_at",
    )

    def has_add_permission(self, request):
        return False

    @staticmethod
    def _preview(photo, placeholder):
        if not photo:
            return placeholder
        try:
            url = photo.url
        except ValueError:
            return placeholder
        return format_html(
            '<a href="{0}" target="_blank" rel="noopener"><img src="{0}" alt="Attendance photo" '
            'style="max-height:120px;max-width:160px;border-radius:4px;border:1px solid #ccc;"></a>', url,
        )

    @admin.display(description="Check-in photo")
    def check_in_photo_preview(self, obj):
        return self._preview(obj.check_in_photo if obj else None, "No check-in photo")

    @admin.display(description="Check-out photo")
    def check_out_photo_preview(self, obj):
        return self._preview(obj.check_out_photo if obj else None, "No check-out photo")
