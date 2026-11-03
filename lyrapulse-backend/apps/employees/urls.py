from django.urls import path
from .attendance_permission_views import AttendancePermissionBulkView, AttendancePermissionDetailView, AttendancePermissionListView
from apps.fingerprints.views import EmployeeFingerprintEnrollmentStartView, EmployeeFingerprintEnrollmentStatusView

from .views import (
    BranchListView,
    EmployeeDocumentDetailView, EmployeeDocumentListCreateView, EmployeeFormAccessView,
    EmployeeManagementDetailView, EmployeeManagementListCreateView, EmployeeMeView,
    EmployeeTypeListView, PayrollGroupListView,
)

urlpatterns = [
    # Backward-compatible path aliases used by earlier mobile/admin clients.
    path("employees/<int:employee_id>/fingerprints/enroll/", EmployeeFingerprintEnrollmentStartView.as_view(), name="legacy-fingerprint-enrollment-start"),
    path("employees/<int:employee_id>/fingerprints/enrollments/<uuid:enrollment_id>/", EmployeeFingerprintEnrollmentStatusView.as_view(), name="legacy-fingerprint-enrollment-status"),
    path("attendance-permissions/", AttendancePermissionListView.as_view(), name="attendance-permission-list"),
    path("attendance-permissions/bulk/", AttendancePermissionBulkView.as_view(), name="attendance-permission-bulk"),
    path("attendance-permissions/<int:pk>/", AttendancePermissionDetailView.as_view(), name="attendance-permission-detail"),
    # ==========================================
    # MOBILE EMPLOYEE APIs
    # ==========================================
    path("mobile/me/", EmployeeMeView.as_view(), name="mobile-me"),

    # ==========================================
    # ADMIN EMPLOYEE MANAGEMENT APIs
    # ==========================================
    path("employees/", EmployeeManagementListCreateView.as_view(), name="employee-list-create"),
    path("employees/<int:pk>/", EmployeeManagementDetailView.as_view(), name="employee-detail"),
    path("employees/form-access/", EmployeeFormAccessView.as_view(), name="employee-form-access"),
    path("employees/<int:pk>/documents/", EmployeeDocumentListCreateView.as_view(), name="employee-documents"),
    path("employees/<int:pk>/documents/<int:doc_id>/", EmployeeDocumentDetailView.as_view(), name="employee-document-detail"),
    path("employees/<int:pk>/documents/<int:doc_id>/download/", EmployeeDocumentDetailView.as_view(), name="employee-document-download"),

    # ==========================================
    # READ-ONLY DROPDOWN DATA (Admin Web)
    # ==========================================
    path("branches/", BranchListView.as_view(), name="branch-list"),
    path("employee-types/", EmployeeTypeListView.as_view(), name="employee-type-list"),
    path("payroll-groups/", PayrollGroupListView.as_view(), name="payroll-group-list"),
]


