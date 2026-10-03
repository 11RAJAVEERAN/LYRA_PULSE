from django.urls import path

from .views import (
    BranchListView, DepartmentListView, DesignationListView,
    EmployeeManagementDetailView, EmployeeManagementListCreateView, EmployeeMeView,
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

    # ==========================================
    # READ-ONLY DROPDOWN DATA (Admin Web)
    # ==========================================
    path("branches/", BranchListView.as_view(), name="branch-list"),
    path("departments/", DepartmentListView.as_view(), name="department-list"),
    path("designations/", DesignationListView.as_view(), name="designation-list"),
]