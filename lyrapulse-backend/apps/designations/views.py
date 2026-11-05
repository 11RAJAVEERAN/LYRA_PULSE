from django.db import IntegrityError
from django.db.models import Count, IntegerField, OuterRef, Subquery, Value
from django.db.models.deletion import ProtectedError
from django.db.models.functions import Coalesce
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import CanAddEmployees, CanChangeEmployees, CanViewEmployees
from apps.accounts.scope import scope_queryset
from apps.branches.models import Branch
from apps.common.responses import success_response
from apps.departments.models import Department
from apps.employees.models import Employee

from .models import Designation


def _scoped_employee_count(request):
    employees = scope_queryset(
        Employee.objects.filter(designation_id=OuterRef("pk")), request.user, "branch"
    )
    branch_id = request.query_params.get("branch")
    if branch_id:
        try:
            employees = employees.filter(branch_id=int(branch_id))
        except (TypeError, ValueError):
            employees = employees.none()
    return Coalesce(
        Subquery(
            employees.order_by().values("designation").annotate(total=Count("pk")).values("total")[:1],
            output_field=IntegerField(),
        ),
        Value(0),
    )


def _filter_branch(queryset, request):
    branch_id = request.query_params.get("branch")
    if not branch_id:
        return queryset
    try:
        return queryset.filter(department__branch_id=int(branch_id))
    except (TypeError, ValueError):
        return queryset.none()


def _request_id(request, field):
    value = request.data.get(field)
    if isinstance(value, bool):
        raise ValidationError({field: "Select a valid option."})
    try:
        return int(value)
    except (TypeError, ValueError):
        raise ValidationError({field: "Select a valid option."})


def _request_name(request):
    name = request.data.get("name")
    if not isinstance(name, str) or not name.strip():
        raise ValidationError({"name": "Enter a name."})
    if len(name.strip()) > 150:
        raise ValidationError({"name": "Name must be 150 characters or fewer."})
    return name.strip()


class DesignationListCreateView(APIView):
    def get_permissions(self):
        permission = CanAddEmployees if self.request.method == "POST" else CanViewEmployees
        return [IsAuthenticated(), permission()]

    def get_queryset(self):
        queryset = scope_queryset(
            Designation.objects.select_related("department__branch"),
            self.request.user,
            "department__branch",
        )
        queryset = _filter_branch(queryset, self.request)
        department_id = self.request.query_params.get("department")
        if department_id:
            try:
                queryset = queryset.filter(department_id=int(department_id))
            except (TypeError, ValueError):
                queryset = queryset.none()
        if self.request.query_params.get("include_inactive", "").lower() != "true":
            queryset = queryset.filter(is_active=True)
        return queryset.annotate(employee_count=_scoped_employee_count(self.request))

    @staticmethod
    def _payload(item):
        return {
            "id": item.pk,
            "name": item.name,
            "department": item.department_id,
            "department_name": item.department.name,
            "branch": item.department.branch_id,
            "branch_name": item.department.branch.name,
            "is_active": item.is_active,
            "employee_count": item.employee_count,
        }

    def get(self, request):
        return success_response([self._payload(item) for item in self.get_queryset()])

    def post(self, request):
        department = get_object_or_404(
            scope_queryset(Department.objects.filter(is_active=True), request.user, "branch"),
            pk=_request_id(request, "department"),
        )
        try:
            item = Designation.objects.create(department=department, name=_request_name(request))
        except IntegrityError:
            raise ValidationError({"name": "A designation with this name already exists in this department."})
        item.employee_count = 0
        return success_response(self._payload(item), "Designation created", status.HTTP_201_CREATED)


class DesignationDetailView(APIView):
    def get_permissions(self):
        return [IsAuthenticated(), CanChangeEmployees()]

    def get_object(self, request, pk):
        return get_object_or_404(
            scope_queryset(
                Designation.objects.select_related("department__branch"),
                request.user,
                "department__branch",
            ),
            pk=pk,
        )

    def patch(self, request, pk):
        item = self.get_object(request, pk)
        unknown = set(request.data) - {"name", "department", "is_active"}
        if unknown:
            raise ValidationError("Only name, department and status can be changed.")
        if "name" in request.data:
            item.name = _request_name(request)
        if "department" in request.data:
            next_department = get_object_or_404(
                scope_queryset(Department.objects.filter(is_active=True), request.user, "branch"),
                pk=_request_id(request, "department"),
            )
            if next_department.pk != item.department_id and item.employees.exists():
                raise ValidationError({"department": "Department cannot change while employees use this designation."})
            item.department = next_department
        if "is_active" in request.data:
            if not isinstance(request.data["is_active"], bool):
                raise ValidationError({"is_active": "Status must be true or false."})
            item.is_active = request.data["is_active"]
        try:
            item.save()
        except IntegrityError:
            raise ValidationError({"name": "A designation with this name already exists in this department."})
        return success_response({
            "id": item.pk, "name": item.name, "department": item.department_id,
            "department_name": item.department.name, "branch_name": item.department.branch.name,
            "is_active": item.is_active,
        })

    def delete(self, request, pk):
        item = self.get_object(request, pk)
        try:
            item.delete()
        except ProtectedError:
            return Response({"detail": "This designation is assigned to employees and cannot be deleted."}, status=status.HTTP_409_CONFLICT)
        return success_response(None, "Designation deleted")

