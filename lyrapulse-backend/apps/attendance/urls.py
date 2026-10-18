from django.urls import path

from .views import CheckInView, CheckOutView, TodayAttendanceView, VerifyLocationView

urlpatterns = [
    path("verify-location/", VerifyLocationView.as_view(), name="attendance-verify-location"),
    path("check-in/", CheckInView.as_view(), name="attendance-check-in"),
    path("check-out/", CheckOutView.as_view(), name="attendance-check-out"),
    path("today/", TodayAttendanceView.as_view(), name="attendance-today"),
]
