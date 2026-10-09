from django.urls import path

from .views import AttendanceHistoryView, FingerprintAttendanceView

urlpatterns = [
    path("", AttendanceHistoryView.as_view(), name="attendance-history"),
    path("fingerprint/", FingerprintAttendanceView.as_view(), name="fingerprint-attendance"),
]
