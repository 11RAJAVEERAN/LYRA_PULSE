from rest_framework import serializers, status
from rest_framework.exceptions import NotFound
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateAPIView, RetrieveAPIView
from rest_framework.permissions import IsAuthenticated
from drf_spectacular.utils import extend_schema, OpenApiResponse, inline_serializer

from apps.accounts.permissions import CanAddEmployees, CanChangeEmployees, CanViewEmployees, IsEmployee
from apps.common.responses import success_response

from .models import Employee
from .serializers import EmployeeManagementSerializer, EmployeeSerializer


class EmployeeManagementListCreateView(ListCreateAPIView):
    def get_permissions(self):
        permission = CanAddEmployees if self.request.method == "POST" else CanViewEmployees
        return [IsAuthenticated(), permission()]
    serializer_class = EmployeeManagementSerializer

    def get_queryset(self):
        return Employee.objects.select_related("user", "branch", "department", "designation").order_by("employee_code")

    @extend_schema(responses={200: inline_serializer(name="EmployeeListResponse", fields={
        "success": serializers.BooleanField(),
        "message": serializers.CharField(),
        "data": EmployeeManagementSerializer(many=True),
    }), 401: OpenApiResponse(description="Authentication required"), 403: OpenApiResponse(description="Admin access required")})
    def list(self, request, *args, **kwargs):
        return success_response(self.get_serializer(self.get_queryset(), many=True).data)

    @extend_schema(request=EmployeeManagementSerializer, responses={201: inline_serializer(name="EmployeeCreateResponse", fields={
        "success": serializers.BooleanField(),
        "message": serializers.CharField(),
        "data": EmployeeManagementSerializer(),
    }), 400: OpenApiResponse(description="Invalid employee data"), 401: OpenApiResponse(description="Authentication required"), 403: OpenApiResponse(description="Admin access required")})
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        employee = serializer.save()
        return success_response(self.get_serializer(employee).data, "Employee created successfully", status.HTTP_201_CREATED)


class EmployeeManagementDetailView(RetrieveUpdateAPIView):
    def get_permissions(self):
        permission = CanChangeEmployees if self.request.method in {"PUT", "PATCH"} else CanViewEmployees
        return [IsAuthenticated(), permission()]
    serializer_class = EmployeeManagementSerializer
    queryset = Employee.objects.select_related("user", "branch", "department", "designation")

    @extend_schema(responses={200: inline_serializer(name="EmployeeDetailResponse", fields={
        "success": serializers.BooleanField(),
        "message": serializers.CharField(),
        "data": EmployeeManagementSerializer(),
    }), 401: OpenApiResponse(description="Authentication required"), 403: OpenApiResponse(description="Admin access required"), 404: OpenApiResponse(description="Employee not found")})
    def retrieve(self, request, *args, **kwargs):
        return success_response(self.get_serializer(self.get_object()).data)

    @extend_schema(request=EmployeeManagementSerializer, responses={200: inline_serializer(name="EmployeeUpdateResponse", fields={
        "success": serializers.BooleanField(),
        "message": serializers.CharField(),
        "data": EmployeeManagementSerializer(),
    }), 400: OpenApiResponse(description="Invalid employee data"), 401: OpenApiResponse(description="Authentication required"), 403: OpenApiResponse(description="Admin access required"), 404: OpenApiResponse(description="Employee not found")})
    def partial_update(self, request, *args, **kwargs):
        employee = self.get_object()
        serializer = self.get_serializer(employee, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        return success_response(serializer.save() and serializer.data, "Employee updated successfully")


class EmployeeMeView(RetrieveAPIView):
    permission_classes = [IsAuthenticated, IsEmployee]
    serializer_class = EmployeeSerializer

    def get_object(self):
        employee = getattr(self.request.user, "employee", None)
        if not employee or not employee.is_active or not self.request.user.is_active:
            raise NotFound("Active employee profile not found")
        return employee

    @extend_schema(responses={200: inline_serializer(name="MobileEmployeeProfileResponse", fields={
        "success": serializers.BooleanField(),
        "message": serializers.CharField(),
        "data": EmployeeSerializer(),
    }), 401: OpenApiResponse(description="Authentication required"), 403: OpenApiResponse(description="Employee role required"), 404: OpenApiResponse(description="Active employee profile not found")})
    def retrieve(self, request, *args, **kwargs):
        return success_response(self.get_serializer(self.get_object()).data)
