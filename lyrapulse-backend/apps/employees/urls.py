from django.urls import path

from .views import EmployeeManagementDetailView, EmployeeManagementListCreateView, EmployeeMeView

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
]
