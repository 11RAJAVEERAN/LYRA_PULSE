from django.contrib import admin

from .models import Branch


@admin.register(Branch)
class BranchAdmin(admin.ModelAdmin):
    list_display = ("name", "code", "organization", "attendance_radius_meters", "is_active")
    list_select_related = ("organization",)
    search_fields = ("name", "code", "organization__name")
    list_filter = ("organization", "is_active")
