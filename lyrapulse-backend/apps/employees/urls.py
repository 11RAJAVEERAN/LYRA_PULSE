from django.urls import path

from apps.fingerprints.views import (
    EmployeeFingerprintEnrollmentStartView,
    EmployeeFingerprintEnrollmentStatusView,
)

from .views import EmployeeMeView, EmployeeRegistrationView

urlpatterns = [
    path("mobile/me/", EmployeeMeView.as_view(), name="mobile-me"),
    path("employees/", EmployeeRegistrationView.as_view(), name="employee-create"),
    path(
        "employees/<int:employee_id>/fingerprints/enroll/",
        EmployeeFingerprintEnrollmentStartView.as_view(),
        name="employee-fingerprint-enrollment-start",
    ),
    path(
        "employees/<int:employee_id>/fingerprints/enrollments/<uuid:enrollment_id>/",
        EmployeeFingerprintEnrollmentStatusView.as_view(),
        name="employee-fingerprint-enrollment-status",
    ),
]