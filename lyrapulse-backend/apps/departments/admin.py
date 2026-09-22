from django.contrib import admin

from .models import Department


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ("name", "branch", "is_active")
    search_fields = ("name", "branch__name")
    list_filter = ("is_active", "branch")