from django.urls import path

from .views import (
    BranchListView, DepartmentListView, DesignationListView,
    EmployeeDocumentDetailView, EmployeeDocumentListCreateView, EmployeeFormAccessView,
    EmployeeManagementDetailView, EmployeeManagementListCreateView, EmployeeMeView,
    EmployeeTypeListView, PayrollGroupListView,
)

urlpatterns = [
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
    path("departments/", DepartmentListView.as_view(), name="department-list"),
    path("designations/", DesignationListView.as_view(), name="designation-list"),
    path("employee-types/", EmployeeTypeListView.as_view(), name="employee-type-list"),
    path("payroll-groups/", PayrollGroupListView.as_view(), name="payroll-group-list"),
]