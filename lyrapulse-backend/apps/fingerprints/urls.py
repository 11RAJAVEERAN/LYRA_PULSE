from django.urls import path

from .views import EmployeeFingerprintEnrollmentStartView, EmployeeFingerprintEnrollmentStatusView

urlpatterns = [
    path("employees/<int:employee_id>/enrollments/", EmployeeFingerprintEnrollmentStartView.as_view(), name="fingerprint-enrollment-start"),
    path("employees/<int:employee_id>/enrollments/<uuid:enrollment_id>/", EmployeeFingerprintEnrollmentStatusView.as_view(), name="fingerprint-enrollment-status"),
]
