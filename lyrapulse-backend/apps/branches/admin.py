from django.contrib import admin

from .models import Branch


@admin.register(Branch)
class BranchAdmin(admin.ModelAdmin):
    list_display = ("name", "code", "attendance_radius_meters", "is_active")
    search_fields = ("name", "code")
    list_filter = ("is_active",)