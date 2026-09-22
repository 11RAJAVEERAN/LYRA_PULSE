from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import OTPVerification, User


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    model = User
    list_display = ("phone_number", "full_name", "role", "is_active", "is_staff")
    search_fields = ("phone_number", "first_name", "last_name", "email")
    list_filter = ("role", "is_active", "is_staff")
    ordering = ("phone_number",)
    fieldsets = ((None, {"fields": ("phone_number", "password")}), ("Personal info", {"fields": ("first_name", "last_name", "email", "role")}), ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),)
    add_fieldsets = ((None, {"classes": ("wide",), "fields": ("phone_number", "role", "is_staff", "is_superuser")} ),)


@admin.register(OTPVerification)
class OTPVerificationAdmin(admin.ModelAdmin):
    list_display = ("phone_number", "purpose", "attempts", "expires_at", "is_verified")
    search_fields = ("phone_number",)
    list_filter = ("purpose", "is_verified")
    ordering = ("-created_at",)