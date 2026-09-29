from django.conf import settings
from django.contrib.auth import get_user_model
from rest_framework import serializers, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView
from drf_spectacular.utils import extend_schema, OpenApiResponse, inline_serializer

from apps.common.responses import success_response

from .models import OTPVerification
from .serializers import AdminLoginSerializer, PhoneSerializer, VerifyOTPSerializer
from .services.otp_service import create_otp, verify_otp

User = get_user_model()


def _success_schema(name, data_fields):
    return inline_serializer(name=name, fields={
        "success": serializers.BooleanField(),
        "message": serializers.CharField(),
        "data": inline_serializer(name=f"{name}Data", fields=data_fields),
    })


def _error_schema(name):
    return inline_serializer(name=name, fields={"detail": serializers.CharField()})


def _user_schema_fields():
    return {
        "id": serializers.IntegerField(), "phone_number": serializers.CharField(),
        "email": serializers.EmailField(allow_blank=True),
        "first_name": serializers.CharField(allow_blank=True),
        "last_name": serializers.CharField(allow_blank=True),
        "name": serializers.CharField(), "role": serializers.CharField(),
    }


def _employee_schema_fields():
    return {
        "id": serializers.IntegerField(), "employee_code": serializers.CharField(),
        "name": serializers.CharField(), "phone_number": serializers.CharField(),
        "email": serializers.EmailField(allow_blank=True), "branch": serializers.JSONField(allow_null=True),
        "department": serializers.JSONField(allow_null=True), "designation": serializers.JSONField(allow_null=True),
        "joining_date": serializers.DateField(allow_null=True), "is_active": serializers.BooleanField(),
    }


def user_payload(user):
    return {"id": user.id, "phone_number": user.phone_number, "email": user.email,
            "first_name": user.first_name, "last_name": user.last_name,
            "name": user.full_name, "role": user.role}


def employee_payload(user):
    employee = getattr(user, "employee", None)
    if not employee:
        return None
    return {
        "id": employee.id, "employee_code": employee.employee_code,
        "name": user.full_name, "phone_number": user.phone_number,
        "email": user.email,
        "branch": {"id": employee.branch_id, "name": employee.branch.name} if employee.branch else None,
        "department": {"id": employee.department_id, "name": employee.department.name} if employee.department else None,
        "designation": {"id": employee.designation_id, "name": employee.designation.name} if employee.designation else None,
        "joining_date": employee.joining_date, "is_active": employee.is_active,
    }


class AdminLoginView(APIView):
    permission_classes = [AllowAny]

    @extend_schema(request=AdminLoginSerializer, responses={
        200: _success_schema("AdminLoginResponse", {
            "access": serializers.CharField(), "refresh": serializers.CharField(),
            "user": inline_serializer(name="AdminLoginUser", fields=_user_schema_fields()),
        }),
        400: _error_schema("AdminLoginError"),
    })
    def post(self, request):
        serializer = AdminLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"].strip()
        matches = User.objects.filter(email__iexact=email)
        if matches.count() != 1:
            return Response({"detail": "Invalid email or password."}, status=status.HTTP_400_BAD_REQUEST)
        user = matches.first()
        if (not user.is_active or user.role not in {User.Role.SUPERADMIN, User.Role.HR}
                or not user.check_password(serializer.validated_data["password"])):
            return Response({"detail": "Invalid email or password."}, status=status.HTTP_400_BAD_REQUEST)
        refresh = RefreshToken.for_user(user)
        return success_response({"access": str(refresh.access_token), "refresh": str(refresh),
                                 "user": user_payload(user)}, "Login successful")


class SendOTPView(APIView):
    permission_classes = [AllowAny]

    @extend_schema(request=PhoneSerializer, responses={
        200: OpenApiResponse(description="OTP accepted; in DEBUG the mock code is also returned."),
        400: _error_schema("SendOtpValidationError"),
        429: OpenApiResponse(description="Resend cooldown"),
    })
    def post(self, request):
        return self._send_otp(request, include_development_otp=True)

    def _send_otp(self, request, include_development_otp=False):
        serializer = PhoneSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]
        user = User.objects.filter(phone_number=phone_number, role=User.Role.EMPLOYEE, is_active=True).select_related("employee").first()
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
    @extend_schema(request=PhoneSerializer, responses={
        200: OpenApiResponse(description="OTP resent."),
        400: _error_schema("ResendOtpValidationError"),
        429: OpenApiResponse(description="Resend cooldown"),
    })
    def post(self, request):
        return self._send_otp(request, include_development_otp=True)


class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    @extend_schema(request=VerifyOTPSerializer, responses={
        200: _success_schema("EmployeeVerifyOtpResponse", {
            "access": serializers.CharField(), "refresh": serializers.CharField(),
            "user": inline_serializer(name="EmployeeVerifyOtpUser", fields=_user_schema_fields()),
            "employee": inline_serializer(name="EmployeeVerifyOtpProfile", fields=_employee_schema_fields()),
        }),
        400: _error_schema("VerifyOtpError"),
        403: _error_schema("VerifyOtpForbidden"),
    })
    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]
        user = User.objects.filter(phone_number=phone_number, role=User.Role.EMPLOYEE, is_active=True).select_related("employee", "employee__branch", "employee__department", "employee__designation").first()
        if not user or not hasattr(user, "employee") or not user.employee.is_active:
            return Response({"detail": "Employee account is inactive or unavailable."}, status=status.HTTP_403_FORBIDDEN)
        try:
            verify_otp(phone_number, serializer.validated_data["otp"])
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        refresh = RefreshToken.for_user(user)
        return success_response({"access": str(refresh.access_token), "refresh": str(refresh),
                                 "user": user_payload(user), "employee": employee_payload(user)}, "Login successful")


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(responses={200: _success_schema("CurrentUserResponse", {
        "user": inline_serializer(name="CurrentUser", fields=_user_schema_fields()),
        "employee": serializers.JSONField(allow_null=True),
    }), 401: OpenApiResponse(description="Authentication credentials are missing or invalid.")})
    def get(self, request):
        employee = employee_payload(request.user) if request.user.role == User.Role.EMPLOYEE and hasattr(request.user, "employee") else None
        return success_response({"user": user_payload(request.user), "employee": employee})


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(request=inline_serializer(name="LogoutRequest", fields={"refresh": serializers.CharField()}), responses={
        200: OpenApiResponse(description="Refresh token blacklisted."),
        400: _error_schema("LogoutError"),
        401: OpenApiResponse(description="Authentication credentials are missing or invalid."),
    })
    def post(self, request):
        serializer = serializers.Serializer(data=request.data)
        serializer.fields["refresh"] = serializers.CharField()
        serializer.is_valid(raise_exception=True)
        RefreshToken(serializer.validated_data["refresh"]).blacklist()
        return success_response({}, "Logged out successfully")


class TokenRefreshEnvelopeView(TokenRefreshView):
    @extend_schema(request=inline_serializer(name="TokenRefreshRequest", fields={"refresh": serializers.CharField()}), responses={
        200: OpenApiResponse(description="New access token returned in the common success envelope."),
        401: OpenApiResponse(description="Refresh token is invalid or expired."),
    })
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code < 400:
            return success_response(response.data, "Token refreshed successfully", response.status_code)
        return response
