from django.conf import settings
from django.contrib.auth import get_user_model
from rest_framework import serializers, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView

from apps.common.responses import success_response

from .models import OTPVerification
from .serializers import PhoneSerializer, VerifyOTPSerializer
from .services.otp_service import create_otp, verify_otp

User = get_user_model()


def employee_payload(user):
    employee = getattr(user, "employee", None)
    data = {"id": user.id, "phone_number": user.phone_number, "name": user.full_name, "role": user.role}
    if employee:
        data["employee"] = {
            "id": employee.id,
            "employee_code": employee.employee_code,
            "branch": {"id": employee.branch_id, "name": employee.branch.name} if employee.branch else None,
            "department": {"id": employee.department_id, "name": employee.department.name} if employee.department else None,
            "designation": {"id": employee.designation_id, "name": employee.designation.name} if employee.designation else None,
        }
    return data


class SendOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        return self._send_otp(request, include_development_otp=True)

    def _send_otp(self, request, include_development_otp=False):
        serializer = PhoneSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]
        user = User.objects.filter(phone_number=phone_number, role=User.Role.EMPLOYEE, is_active=True).first()
        if not user or not hasattr(user, "employee") or not user.employee.is_active:
            return success_response({"phone_number": phone_number}, "If the account exists, an OTP was sent")
        try:
            otp_record = create_otp(phone_number)
        except ValueError as exc:
            return success_response({"phone_number": phone_number, "resend_after": settings.OTP_RESEND_COOLDOWN_SECONDS}, str(exc), status.HTTP_429_TOO_MANY_REQUESTS)
        if include_development_otp:
            response_data = {"success": True, "message": "OTP sent successfully"}
            if settings.DEBUG:
                response_data["otp"] = otp_record._plain_otp
            return Response(response_data, status=status.HTTP_200_OK)
        return success_response({"phone_number": phone_number, "expires_in": settings.OTP_EXPIRY_SECONDS, "resend_after": settings.OTP_RESEND_COOLDOWN_SECONDS}, "OTP sent successfully", status.HTTP_200_OK)


class ResendOTPView(SendOTPView):
    def post(self, request):
        return self._send_otp(request)


class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]
        try:
            verify_otp(phone_number, serializer.validated_data["otp"])
        except ValueError as exc:
            return success_response({}, str(exc), status.HTTP_400_BAD_REQUEST)
        user = User.objects.filter(phone_number=phone_number, is_active=True).first()
        if not user or not hasattr(user, "employee") or not user.employee.is_active:
            return success_response({}, "Employee account is inactive", status.HTTP_403_FORBIDDEN)
        refresh = RefreshToken.for_user(user)
        return success_response({"access": str(refresh.access_token), "refresh": str(refresh), "user": employee_payload(user)}, "Login successful")


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return success_response(employee_payload(request.user))


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = serializers.Serializer(data=request.data)
        serializer.fields["refresh"] = serializers.CharField()
        serializer.is_valid(raise_exception=True)
        RefreshToken(serializer.validated_data["refresh"]).blacklist()
        return success_response({}, "Logged out successfully")


class TokenRefreshEnvelopeView(TokenRefreshView):
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code < 400:
            return success_response(response.data, "Token refreshed successfully", response.status_code)
        return response