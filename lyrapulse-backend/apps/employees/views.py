from rest_framework import status
from rest_framework.generics import CreateAPIView, RetrieveAPIView
from rest_framework.permissions import IsAuthenticated

from apps.accounts.permissions import IsHROrAdmin
from apps.common.responses import success_response

from .serializers import EmployeeRegistrationSerializer, EmployeeSerializer


class EmployeeRegistrationView(CreateAPIView):
    permission_classes = [IsAuthenticated, IsHROrAdmin]
    serializer_class = EmployeeRegistrationSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        employee = serializer.save()
        return success_response(
            self.get_serializer(employee).data,
            "Employee created successfully",
            status.HTTP_201_CREATED,
        )


class EmployeeMeView(RetrieveAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = EmployeeSerializer

    def get_object(self):
        return self.request.user.employee

    def retrieve(self, request, *args, **kwargs):
        return success_response(self.get_serializer(self.get_object()).data)