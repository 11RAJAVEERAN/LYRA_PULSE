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
from apps.employees.models import Employee

from .models import Department


def _scoped_employee_count(request):
    employees = scope_queryset(
        Employee.objects.filter(department_id=OuterRef("pk")), request.user, "branch"
    )
    branch_id = request.query_params.get("branch")
    if branch_id:
        try:
            employees = employees.filter(branch_id=int(branch_id))
        except (TypeError, ValueError):
            employees = employees.none()
    return Coalesce(
        Subquery(
            employees.order_by().values("department").annotate(total=Count("pk")).values("total")[:1],
            output_field=IntegerField(),
        ),
        Value(0),
    )


def _filter_branch(queryset, request):
    branch_id = request.query_params.get("branch")
    if not branch_id:
        return queryset
    try:
        return queryset.filter(branch_id=int(branch_id))
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


class DepartmentListCreateView(APIView):
    def get_permissions(self):
        permission = CanAddEmployees if self.request.method == "POST" else CanViewEmployees
        return [IsAuthenticated(), permission()]

    def get_queryset(self):
        queryset = scope_queryset(
            Department.objects.select_related("branch"), self.request.user, "branch"
        )
        queryset = _filter_branch(queryset, self.request)
        if self.request.query_params.get("include_inactive", "").lower() != "true":
            queryset = queryset.filter(is_active=True)
        return queryset.annotate(
            employee_count=_scoped_employee_count(self.request),
            designation_count=Count("designations"),
        )

    @staticmethod
    def _payload(item):
        return {
            "id": item.pk,
            "name": item.name,
            "branch": item.branch_id,
            "branch_name": item.branch.name,
            "is_active": item.is_active,
            "employee_count": item.employee_count,
            "designation_count": item.designation_count,
        }

    def get(self, request):
        return success_response([self._payload(item) for item in self.get_queryset()])

    def post(self, request):
        branch = get_object_or_404(
            scope_queryset(Branch.objects.filter(is_active=True), request.user, "id"),
            pk=_request_id(request, "branch"),
        )
        try:
            item = Department.objects.create(branch=branch, name=_request_name(request))
        except IntegrityError:
            raise ValidationError({"name": "A department with this name already exists in this branch."})
        item.employee_count = 0
        item.designation_count = 0
        return success_response(self._payload(item), "Department created", status.HTTP_201_CREATED)


class DepartmentDetailView(APIView):
    def get_permissions(self):
        return [IsAuthenticated(), CanChangeEmployees()]

    def get_object(self, request, pk):
        return get_object_or_404(
            scope_queryset(Department.objects.select_related("branch"), request.user, "branch"), pk=pk
        )

    def patch(self, request, pk):
        item = self.get_object(request, pk)
        unknown = set(request.data) - {"name", "branch", "is_active"}
        if unknown:
            raise ValidationError("Only name, branch and status can be changed.")
        if "name" in request.data:
            item.name = _request_name(request)
        if "branch" in request.data:
            next_branch = get_object_or_404(
                scope_queryset(Branch.objects.filter(is_active=True), request.user, "id"),
                pk=_request_id(request, "branch"),
            )
            if next_branch.pk != item.branch_id and (item.employees.exists() or item.designations.exists()):
                raise ValidationError({"branch": "Branch cannot change while employees or designations use this department."})
            item.branch = next_branch
        if "is_active" in request.data:
            if not isinstance(request.data["is_active"], bool):
                raise ValidationError({"is_active": "Status must be true or false."})
            item.is_active = request.data["is_active"]
        try:
            item.save()
        except IntegrityError:
            raise ValidationError({"name": "A department with this name already exists in this branch."})
        return success_response({
            "id": item.pk, "name": item.name, "branch": item.branch_id,
            "branch_name": item.branch.name, "is_active": item.is_active,
        })

    def delete(self, request, pk):
        item = self.get_object(request, pk)
        try:
            item.delete()
        except ProtectedError:
            return Response({"detail": "This department is assigned to employees or designations and cannot be deleted."}, status=status.HTTP_409_CONFLICT)
        return success_response(None, "Department deleted")

