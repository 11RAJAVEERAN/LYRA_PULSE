from django.urls import path
from .views import LogoutView, MeView, ResendOTPView, SendOTPView, TokenRefreshEnvelopeView, VerifyOTPView

urlpatterns = [
    path("send-otp/", SendOTPView.as_view(), name="send-otp"),
    path("resend-otp/", ResendOTPView.as_view(), name="resend-otp"),
    path("verify-otp/", VerifyOTPView.as_view(), name="verify-otp"),
    path("token/refresh/", TokenRefreshEnvelopeView.as_view(), name="token-refresh"),
    path("logout/", LogoutView.as_view(), name="logout"),
    path("me/", MeView.as_view(), name="me"),
]