from rest_framework.permissions import BasePermission

from .models import Device


class IsAuthenticatedDevice(BasePermission):
    def has_permission(self, request, view):
        return isinstance(request.auth, Device) and request.auth.is_active
