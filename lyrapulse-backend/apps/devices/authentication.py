from rest_framework.authentication import BaseAuthentication, get_authorization_header
from rest_framework.exceptions import AuthenticationFailed

from .models import Device


class DeviceTokenAuthentication(BaseAuthentication):
    keyword = b"device"

    def authenticate(self, request):
        parts = get_authorization_header(request).split()
        if not parts:
            return None
        if parts[0].lower() != self.keyword:
            return None
        if len(parts) != 2:
            raise AuthenticationFailed("Invalid device authorization header.")

        device_id = getattr(request._request.resolver_match, "kwargs", {}).get("device_id")
        if not device_id:
            device_id = request.data.get("device_id")
        if not device_id:
            raise AuthenticationFailed("Device ID is required.")

        try:
            device = Device.objects.get(device_id=device_id)
        except Device.DoesNotExist as exc:
            raise AuthenticationFailed("Invalid device credentials.") from exc
        try:
            token = parts[1].decode("ascii")
        except UnicodeDecodeError as exc:
            raise AuthenticationFailed("Invalid device credentials.") from exc
        if not device.is_active or not device.verify_token(token):
            raise AuthenticationFailed("Invalid device credentials.")

        return device, device

    def authenticate_header(self, request):
        return "Device"
