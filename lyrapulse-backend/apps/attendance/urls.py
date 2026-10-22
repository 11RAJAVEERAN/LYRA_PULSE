from django.urls import path

from .admin_views import (
    AdminAttendanceDetailView, AdminAttendanceExportView, AdminAttendanceListView, AdminAttendanceSummaryView,
)
from .views import CheckInView, CheckOutView, TodayAttendanceView, VerifyLocationView
from .device_views import AdminManualAttendanceView, FingerprintAttendanceEventView

urlpatterns = [
    # ==========================================
    # MOBILE EMPLOYEE ATTENDANCE APIs (unchanged)
    # ==========================================
    path("verify-location/", VerifyLocationView.as_view(), name="attendance-verify-location"),
    path("check-in/", CheckInView.as_view(), name="attendance-check-in"),
    path("check-out/", CheckOutView.as_view(), name="attendance-check-out"),
    path("today/", TodayAttendanceView.as_view(), name="attendance-today"),
    path("fingerprint/events/", FingerprintAttendanceEventView.as_view(), name="attendance-fingerprint-event"),

    # ==========================================
    # ADMIN WEB ATTENDANCE APIs (read-only)
    # ==========================================
    path("admin/", AdminAttendanceListView.as_view(), name="attendance-admin-list"),
    path("admin/summary/", AdminAttendanceSummaryView.as_view(), name="attendance-admin-summary"),
    path("admin/export/", AdminAttendanceExportView.as_view(), name="attendance-admin-export"),
    path("admin/manual/", AdminManualAttendanceView.as_view(), name="attendance-admin-manual"),
    path("admin/<int:employee_id>/", AdminAttendanceDetailView.as_view(), name="attendance-admin-detail"),
]
