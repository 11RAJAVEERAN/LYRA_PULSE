from django.urls import path

from apps.fingerprints.views import DeviceEnrollmentPendingView, DeviceEnrollmentResultView

urlpatterns = [
    path(
        "<str:device_id>/enrollment/pending/",
        DeviceEnrollmentPendingView.as_view(),
        name="device-enrollment-pending",
    ),
    path(
        "<str:device_id>/enrollment/<uuid:enrollment_id>/result/",
        DeviceEnrollmentResultView.as_view(),
        name="device-enrollment-result",
    ),
]
