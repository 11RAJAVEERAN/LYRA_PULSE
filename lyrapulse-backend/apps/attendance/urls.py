from django.urls import path

from .admin_views import (
    AdminAttendanceDetailView, AdminAttendanceExportView, AdminAttendanceListView, AdminAttendanceSummaryView,
)
from .views import (
    AttendancePhotoView, CheckInView, CheckOutView, EmployeeAttendanceHistoryView,
    TodayAttendanceView, VerifyLocationView,
)
from .device_views import AdminManualAttendanceView, FingerprintAttendanceEventView
from .bulk_adjustment_api import (
    AttendanceAdjustmentBulkUpdateView, AttendanceAdjustmentCodesView, AttendanceAdjustmentExportView,
    AttendanceAdjustmentGridView,
)

urlpatterns = [
    # ==========================================
    # MOBILE EMPLOYEE ATTENDANCE APIs (unchanged)
    # ==========================================
    path("verify-location/", VerifyLocationView.as_view(), name="attendance-verify-location"),
    path("check-in/", CheckInView.as_view(), name="attendance-check-in"),
    path("check-out/", CheckOutView.as_view(), name="attendance-check-out"),
    path("today/", TodayAttendanceView.as_view(), name="attendance-today"),
    path("history/", EmployeeAttendanceHistoryView.as_view(), name="attendance-history"),
    path("<int:attendance_id>/photos/<str:kind>/", AttendancePhotoView.as_view(), name="attendance-photo"),
    path("fingerprint/events/", FingerprintAttendanceEventView.as_view(), name="attendance-fingerprint-event"),

    # ==========================================
    # ADMIN WEB ATTENDANCE APIs (read-only)
    # ==========================================
    path("admin/", AdminAttendanceListView.as_view(), name="attendance-admin-list"),
    path("admin/summary/", AdminAttendanceSummaryView.as_view(), name="attendance-admin-summary"),
    path("admin/export/", AdminAttendanceExportView.as_view(), name="attendance-admin-export"),
    path("admin/bulk-adjustments/", AttendanceAdjustmentGridView.as_view(), name="attendance-bulk-adjustments-grid"),
    path("admin/bulk-adjustments/codes/", AttendanceAdjustmentCodesView.as_view(), name="attendance-bulk-adjustments-codes"),
    path("admin/bulk-adjustments/save/", AttendanceAdjustmentBulkUpdateView.as_view(), name="attendance-bulk-adjustments-save"),
    path("admin/bulk-adjustments/export/", AttendanceAdjustmentExportView.as_view(), name="attendance-bulk-adjustments-export"),
    path("admin/manual/", AdminManualAttendanceView.as_view(), name="attendance-admin-manual"),
    path("admin/<int:employee_id>/", AdminAttendanceDetailView.as_view(), name="attendance-admin-detail"),
]
