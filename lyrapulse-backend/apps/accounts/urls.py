from django.urls import path
from .views import AdminOTPSendView, AdminOTPVerifyView, LogoutView, MeView, ResendOTPView, SendOTPView, TokenRefreshEnvelopeView, VerifyOTPView
from .admin_views import AdminUserDetailView, AdminUserListCreateView

urlpatterns = [
    # ==========================================
    # MOBILE EMPLOYEE AUTHENTICATION APIs
    # ==========================================
    path("employee/send-otp/", SendOTPView.as_view(), name="employee-send-otp"),
    path("employee/resend-otp/", ResendOTPView.as_view(), name="employee-resend-otp"),
    path("employee/verify-otp/", VerifyOTPView.as_view(), name="employee-verify-otp"),

    # Backwards-compatible aliases for the original authentication paths.
    path("send-otp/", SendOTPView.as_view(), name="send-otp"),
    path("resend-otp/", ResendOTPView.as_view(), name="resend-otp"),
    path("verify-otp/", VerifyOTPView.as_view(), name="verify-otp"),

    # ==========================================
    # ADMIN WEB AUTHENTICATION APIs
    # ==========================================
    path("admin/send-otp/", AdminOTPSendView.as_view(), name="admin-send-otp"),
    path("admin/verify-otp/", AdminOTPVerifyView.as_view(), name="admin-verify-otp"),
    path("admin/users/", AdminUserListCreateView.as_view(), name="admin-users"),
    path("admin/users/<int:pk>/", AdminUserDetailView.as_view(), name="admin-user-detail"),

    # ==========================================
    # COMMON AUTHENTICATION APIs
    # ==========================================
    path("token/refresh/", TokenRefreshEnvelopeView.as_view(), name="token-refresh"),
    path("logout/", LogoutView.as_view(), name="logout"),
    path("me/", MeView.as_view(), name="me"),
]
