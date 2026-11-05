from django.contrib import admin

from .models import Branch


@admin.register(Branch)
class BranchAdmin(admin.ModelAdmin):
    list_display = ("name", "code", "organization", "location_configured", "attendance_radius_meters", "is_active")
    list_select_related = ("organization",)
    search_fields = ("name", "code", "organization__name")
    list_filter = ("organization", "is_active")
    fieldsets = (
        ("Branch Information", {"fields": ("organization", "name", "code", "address", "is_active")}),
        ("Attendance Location", {
            "description": "Where employees must be to check in or check out. Leave latitude/longitude empty until configured; "
                           "attendance is rejected for a branch without a location.",
            "fields": ("latitude", "longitude", "attendance_radius_meters", "location_configured"),
        }),
    )
    readonly_fields = ("location_configured",)

    @admin.display(description="Location configured", boolean=True)
    def location_configured(self, obj):
        return bool(obj and obj.has_attendance_location)
