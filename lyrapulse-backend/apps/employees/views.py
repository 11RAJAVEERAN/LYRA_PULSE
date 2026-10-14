from django.db import transaction
from django.http import FileResponse
from django.shortcuts import get_object_or_404
from rest_framework import serializers, status
from rest_framework.exceptions import NotFound
from rest_framework.generics import ListAPIView, ListCreateAPIView, RetrieveUpdateAPIView, RetrieveAPIView
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema, OpenApiParameter, OpenApiResponse, inline_serializer

from apps.accounts.permissions import (
    CanAddEmployees, CanChangeEmployees, CanChangeSensitiveEmployeeData, CanViewEmployees,
    CanViewSensitiveEmployeeData, IsEmployee, can_change_sensitive_employee_data, can_view_sensitive_employee_data,
)
from apps.accounts.scope import scope_queryset
from apps.common.responses import success_response

from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation

from .document_validation import validate_document_file
from .models import Employee, EmployeeDocument, EmployeeType, PayrollGroup
from .serializers import (
    BranchOptionSerializer, DepartmentOptionSerializer, DesignationOptionSerializer,
    EmployeeDocumentSerializer, EmployeeManagementSerializer, EmployeeSerializer,
    EmployeeTypeOptionSerializer, PayrollGroupOptionSerializer,
)


class EmployeeManagementListCreateView(ListCreateAPIView):
    def get_permissions(self):
        permission = CanAddEmployees if self.request.method == "POST" else CanViewEmployees
        return [IsAuthenticated(), permission()]
    serializer_class = EmployeeManagementSerializer

    def get_queryset(self):
        queryset = Employee.objects.select_related("user", "branch", "department", "designation", "employee_type", "payroll_group").order_by("employee_code")
        return scope_queryset(queryset, self.request.user, "branch")

    @extend_schema(responses={200: inline_serializer(name="EmployeeListResponse", fields={
        "success": serializers.BooleanField(),
        "message": serializers.CharField(),
        "data": EmployeeManagementSerializer(many=True),
    }), 401: OpenApiResponse(description="Authentication required"), 403: OpenApiResponse(description="Admin access required")})
    def list(self, request, *args, **kwargs):
        serializer = EmployeeManagementSerializer(self.get_queryset(), many=True, context={**self.get_serializer_context(), "summary": True})
        return success_response(serializer.data)

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

    def get_queryset(self):
        queryset = Employee.objects.select_related("user", "branch", "department", "designation", "employee_type", "payroll_group").prefetch_related("documents")
        return scope_queryset(queryset, self.request.user, "branch")

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


class ReadOnlyOptionListView(ListAPIView):
    """Read-only dropdown data for the Admin Web. Active records only unless ?include_inactive=true."""
    permission_classes = [IsAuthenticated, CanViewEmployees]
    pagination_class = None
    model = None
    branch_lookup = None  # ORM path to the owning branch, used for organization/branch scoping

    def get_queryset(self):
        queryset = scope_queryset(self.model.objects.all(), self.request.user, self.branch_lookup)
        if self.request.query_params.get("include_inactive", "").lower() != "true":
            queryset = queryset.filter(is_active=True)
        return queryset

    def list(self, request, *args, **kwargs):
        return success_response(self.get_serializer(self.get_queryset(), many=True).data)


def option_list_schema(name, serializer_class):
    return extend_schema(
        parameters=[OpenApiParameter("include_inactive", bool, description="Set to true to also return inactive records.")],
        responses={200: inline_serializer(name=name, fields={
            "success": serializers.BooleanField(),
            "message": serializers.CharField(),
            "data": serializer_class(many=True),
        }), 401: OpenApiResponse(description="Authentication required"), 403: OpenApiResponse(description="Employee view access required")},
    )


@option_list_schema("BranchListResponse", BranchOptionSerializer)
class BranchListView(ReadOnlyOptionListView):
    model = Branch
    branch_lookup = "id"
    serializer_class = BranchOptionSerializer


@option_list_schema("DepartmentListResponse", DepartmentOptionSerializer)
class DepartmentListView(ReadOnlyOptionListView):
    model = Department
    branch_lookup = "branch"
    serializer_class = DepartmentOptionSerializer


@option_list_schema("DesignationListResponse", DesignationOptionSerializer)
class DesignationListView(ReadOnlyOptionListView):
    model = Designation
    branch_lookup = "department__branch"
    serializer_class = DesignationOptionSerializer


class EmployeeFormAccessView(APIView):
    """Tells the Add/Edit Details form which sensitive sections (salary, bank, documents) the user may use."""
    permission_classes = [IsAuthenticated, CanViewEmployees]

    @extend_schema(responses={200: inline_serializer(name="EmployeeFormAccessResponse", fields={
        "success": serializers.BooleanField(), "message": serializers.CharField(),
        "data": inline_serializer(name="EmployeeFormAccess", fields={
            "can_view_sensitive": serializers.BooleanField(), "can_change_sensitive": serializers.BooleanField()}),
    })})
    def get(self, request):
        return success_response({
            "can_view_sensitive": can_view_sensitive_employee_data(request.user),
            "can_change_sensitive": can_change_sensitive_employee_data(request.user),
        })


@option_list_schema("EmployeeTypeListResponse", EmployeeTypeOptionSerializer)
class EmployeeTypeListView(ReadOnlyOptionListView):
    serializer_class = EmployeeTypeOptionSerializer

    def get_queryset(self):
        queryset = EmployeeType.objects.all()
        if self.request.query_params.get("include_inactive", "").lower() != "true":
            queryset = queryset.filter(is_active=True)
        return queryset


@option_list_schema("PayrollGroupListResponse", PayrollGroupOptionSerializer)
class PayrollGroupListView(ReadOnlyOptionListView):
    serializer_class = PayrollGroupOptionSerializer

    def get_queryset(self):
        queryset = PayrollGroup.objects.all()
        if self.request.query_params.get("include_inactive", "").lower() != "true":
            queryset = queryset.filter(is_active=True)
        return queryset


class EmployeeDocumentMixin:
    def get_employee(self):
        queryset = scope_queryset(Employee.objects.select_related("user"), self.request.user, "branch")
        return get_object_or_404(queryset, pk=self.kwargs["pk"])


class EmployeeDocumentListCreateView(EmployeeDocumentMixin, APIView):
    """List, upload or replace an employee's legal documents (multipart/form-data)."""
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_permissions(self):
        permission = CanChangeSensitiveEmployeeData if self.request.method == "POST" else CanViewSensitiveEmployeeData
        return [IsAuthenticated(), permission()]

    @extend_schema(responses={200: EmployeeDocumentSerializer(many=True)})
    def get(self, request, pk):
        employee = self.get_employee()
        return success_response(EmployeeDocumentSerializer(employee.documents.all(), many=True).data)

    @extend_schema(request=inline_serializer(name="EmployeeDocumentUpload", fields={
        "doc_type": serializers.ChoiceField(choices=EmployeeDocument.DocType.choices),
        "side": serializers.ChoiceField(choices=EmployeeDocument.Side.choices, required=False),
        "file": serializers.FileField(),
    }), responses={201: EmployeeDocumentSerializer})
    def post(self, request, pk):
        employee = self.get_employee()
        errors = {}
        doc_type = request.data.get("doc_type")
        side = request.data.get("side") or EmployeeDocument.Side.SINGLE
        upload = request.FILES.get("file")
        if doc_type not in EmployeeDocument.DocType.values:
            errors["doc_type"] = ["Select a valid document type."]
        if side not in EmployeeDocument.Side.values:
            errors["side"] = ["Select a valid side."]
        if upload is None:
            errors["file"] = ["Choose a file to upload."]
        if errors:
            raise serializers.ValidationError(errors)
        # Aadhar and Driving Licence have front/back; PAN and photo are single uploads.
        two_sided = doc_type in (EmployeeDocument.DocType.AADHAAR, EmployeeDocument.DocType.DRIVING_LICENCE)
        if two_sided and side == EmployeeDocument.Side.SINGLE:
            raise serializers.ValidationError({"side": ["Specify FRONT or BACK for this document."]})
        if not two_sided and side != EmployeeDocument.Side.SINGLE:
            raise serializers.ValidationError({"side": ["This document has a single upload."]})
        try:
            content_type = validate_document_file(upload)
        except serializers.ValidationError as error:
            raise serializers.ValidationError({"file": error.detail})

        with transaction.atomic():
            existing = EmployeeDocument.objects.select_for_update().filter(employee=employee, doc_type=doc_type, side=side).first()
            old_file = existing.file if existing else None
            document = existing or EmployeeDocument(employee=employee, doc_type=doc_type, side=side)
            document.original_name = (upload.name or "document")[:255]
            document.content_type = content_type
            document.size = upload.size
            document.file = upload
            document.save()
            if old_file:
                transaction.on_commit(lambda: old_file.storage.delete(old_file.name))
        return success_response(EmployeeDocumentSerializer(document).data, "Document uploaded successfully", status.HTTP_201_CREATED)


class EmployeeDocumentDetailView(EmployeeDocumentMixin, APIView):
    """Authenticated download (GET) and removal (DELETE) of one document."""

    def get_permissions(self):
        permission = CanChangeSensitiveEmployeeData if self.request.method == "DELETE" else CanViewSensitiveEmployeeData
        return [IsAuthenticated(), permission()]

    def get_document(self):
        return get_object_or_404(EmployeeDocument, pk=self.kwargs["doc_id"], employee=self.get_employee())

    @extend_schema(responses={200: OpenApiResponse(description="The document file")})
    def get(self, request, pk, doc_id):
        document = self.get_document()
        try:
            handle = document.file.open("rb")
        except FileNotFoundError:
            raise NotFound("The stored file is missing.")
        response = FileResponse(handle, content_type=document.content_type)
        response["Content-Disposition"] = 'inline; filename="document"'
        response["X-Content-Type-Options"] = "nosniff"
        response["Cache-Control"] = "private, no-store"
        return response

    @extend_schema(responses={200: OpenApiResponse(description="Document removed")})
    def delete(self, request, pk, doc_id):
        document = self.get_document()
        file = document.file
        with transaction.atomic():
            document.delete()
            transaction.on_commit(lambda: file.storage.delete(file.name))
        return success_response(None, "Document removed successfully")