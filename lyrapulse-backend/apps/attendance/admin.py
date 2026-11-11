import mimetypes

from django.contrib import admin
from django.http import FileResponse, Http404
from django.urls import path, reverse
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

    def get_urls(self):
        return [
            path(
                "photo/<int:attendance_id>/<str:kind>/",
                self.admin_site.admin_view(self.photo_view),
                name="attendance_photo",
            ),
        ] + super().get_urls()

    def photo_view(self, request, attendance_id, kind):
        attendance = self.get_object(request, attendance_id)
        if kind not in {"check-in", "check-out"} or attendance is None or not self.has_view_permission(request, attendance):
            raise Http404
        photo = attendance.check_in_photo if kind == "check-in" else attendance.check_out_photo
        if not photo:
            raise Http404
        try:
            photo.open("rb")
        except FileNotFoundError as error:
            raise Http404 from error
        response = FileResponse(photo, content_type=mimetypes.guess_type(photo.name)[0] or "application/octet-stream")
        response["Cache-Control"] = "private, no-store"
        response["X-Content-Type-Options"] = "nosniff"
        response["Content-Disposition"] = 'inline; filename="attendance-photo"'
        return response

    def has_add_permission(self, request):
        return False

    @staticmethod
    def _preview(obj, kind, placeholder):
        photo = obj.check_in_photo if kind == "check-in" else obj.check_out_photo
        if not photo:
            return placeholder
        url = reverse("admin:attendance_photo", args=(obj.pk, kind))
        return format_html(
            '<a href="{0}" target="_blank" rel="noopener"><img src="{0}" alt="Attendance photo" '
            'style="max-height:120px;max-width:160px;border-radius:4px;border:1px solid #ccc;"></a>', url,
        )

    @admin.display(description="Check-in photo")
    def check_in_photo_preview(self, obj):
        return self._preview(obj, "check-in", "No check-in photo") if obj else "No check-in photo"

    @admin.display(description="Check-out photo")
    def check_out_photo_preview(self, obj):
        return self._preview(obj, "check-out", "No check-out photo") if obj else "No check-out photo"
