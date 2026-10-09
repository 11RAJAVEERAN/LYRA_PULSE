from rest_framework import status
from rest_framework.exceptions import PermissionDenied
from rest_framework.generics import GenericAPIView
from rest_framework.permissions import IsAuthenticated

from apps.accounts.permissions import IsHROrAdmin
from apps.common.responses import success_response
from apps.devices.authentication import DeviceTokenAuthentication
from apps.devices.permissions import IsAuthenticatedDevice

from .serializers import AttendanceHistoryQuerySerializer, FingerprintAttendanceSerializer
from .services import get_employee_attendance_history, record_fingerprint_attendance


class FingerprintAttendanceView(GenericAPIView):
    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsAuthenticatedDevice]
    serializer_class = FingerprintAttendanceSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        if serializer.validated_data["device_id"] != request.auth.device_id:
            raise PermissionDenied("The device ID does not match the authenticated device.")

        data, message = record_fingerprint_attendance(
            request.auth,
            serializer.validated_data["fingerprint_slot"],
        )
        return success_response(data, message, status.HTTP_200_OK)


class AttendanceHistoryView(GenericAPIView):
    permission_classes = [IsAuthenticated, IsHROrAdmin]
    serializer_class = AttendanceHistoryQuerySerializer

    def get(self, request):
        serializer = self.get_serializer(data=request.query_params)
        serializer.is_valid(raise_exception=True)
        return success_response(
            get_employee_attendance_history(
                serializer.validated_data["employee_id"],
                serializer.validated_data["date"],
            ),
            "Attendance history retrieved",
        )
