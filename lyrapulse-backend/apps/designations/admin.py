from django.contrib import admin

from .models import Designation


@admin.register(Designation)
class DesignationAdmin(admin.ModelAdmin):
    list_display = ("name", "department", "is_active")
    search_fields = ("name", "department__name")
    list_filter = ("is_active",)