from django.db.models import Count, Prefetch, Q
from django.utils import timezone
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.accounts.scope import scope_queryset
from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation
from apps.employees.models import Employee
from apps.common.responses import success_response

from .models import Shift, ShiftAssignment, ShiftScheduleRevision
from .pagination import ShiftPagination
from .permissions import CanAssignShifts, CanManageShifts, CanViewShiftManagement
from .serializers import (
    AssignmentReadSerializer, AssignmentWriteSerializer, BulkAssignmentWriteSerializer, ShiftSerializer,
)
from .services import assign_shift, bulk_assign_shifts


def _require(request, permission):
    checker = permission()
    checker.message = "You do not have permission to manage Shift Management."
    if not checker.has_permission(request, None):
        raise PermissionDenied(checker.message)


def _parse_scope_id(request, parameter, model, branch_lookup, label):
    value = request.query_params.get(parameter)
    if not value:
        return None
    try:
        value = int(value)
    except (TypeError, ValueError):
        raise ValidationError({parameter: f"Select a valid {label}."}) from None
    if not scope_queryset(model.objects.filter(pk=value), request.user, branch_lookup).exists():
        raise ValidationError({parameter: f"You do not have access to this {label}."})
    return value


def _shift_queryset(user):
    today = timezone.localdate()
    current_schedule = (ShiftScheduleRevision.objects.filter(effective_from__lte=today)
                        .order_by("-effective_from").prefetch_related("days"))
    return (scope_queryset(Shift.objects.all(), user, "branch")
        .order_by("branch__name", "name", "pk")
        .select_related("branch")
        .annotate(assigned_employee_count=Count(
            "assignments__employee_id", distinct=True,
            filter=Q(assignments__effective_from__lte=today)
            & (Q(assignments__effective_to__isnull=True) | Q(assignments__effective_to__gte=today)),
        ))
        .prefetch_related(Prefetch("schedule_revisions", queryset=current_schedule, to_attr="_prefetched_schedule_revisions")))


class ShiftListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        _require(request, CanViewShiftManagement)
        queryset = _shift_queryset(request.user)
        branch_id = _parse_scope_id(request, "branch", Branch, "id", "branch")
        if branch_id:
            queryset = queryset.filter(branch_id=branch_id)
        status_filter = request.query_params.get("status", "active").lower()
        if status_filter not in ("active", "inactive", "all"):
            raise ValidationError({"status": "Use active, inactive, or all."})
        if status_filter != "all":
            queryset = queryset.filter(is_active=(status_filter == "active"))
        search = request.query_params.get("search", "").strip()
        if len(search) > 100:
            raise ValidationError({"search": "Search must be 100 characters or fewer."})
        if search:
            queryset = queryset.filter(name__icontains=search)
        paginator = ShiftPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        return paginator.get_paginated_response(ShiftSerializer(page, many=True, context={"request": request}).data)

    def post(self, request):
        _require(request, CanManageShifts)
        serializer = ShiftSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        shift = serializer.save()
        shift = _shift_queryset(request.user).get(pk=shift.pk)
        return success_response(ShiftSerializer(shift, context={"request": request, "include_schedule_history": True}).data,
                                "Shift created successfully.", 201)


class ShiftDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def _get(self, request, pk):
        shift = _shift_queryset(request.user).filter(pk=pk).first()
        if shift is None:
            raise NotFound("Shift not found.")
        # Detail includes all schedule revisions for the history drawer while keeping list queries bounded.
        revisions = list(shift.schedule_revisions.order_by("effective_from").prefetch_related("days", "created_by", "updated_by"))
        shift._all_schedule_revisions = revisions
        shift._prefetched_schedule_revisions = revisions
        return shift

    def get(self, request, pk):
        _require(request, CanViewShiftManagement)
        shift = self._get(request, pk)
        return success_response(ShiftSerializer(shift, context={"request": request, "include_schedule_history": True}).data)

    def patch(self, request, pk):
        _require(request, CanManageShifts)
        shift = self._get(request, pk)
        serializer = ShiftSerializer(shift, data=request.data, partial=True, context={"request": request})
        serializer.is_valid(raise_exception=True)
        shift = serializer.save()
        shift = self._get(request, shift.pk)
        return success_response(ShiftSerializer(shift, context={"request": request, "include_schedule_history": True}).data,
                                "Shift updated successfully.")


def _assignment_queryset(user):
    return (scope_queryset(ShiftAssignment.objects.all(), user, "employee__branch")
        .select_related("employee__user", "employee__branch", "employee__department", "employee__designation",
                        "shift__branch", "assigned_by", "updated_by")
        .prefetch_related("week_offs"))


class ShiftAssignmentListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        _require(request, CanViewShiftManagement)
        queryset = _assignment_queryset(request.user)
        branch_id = _parse_scope_id(request, "branch", Branch, "id", "branch")
        department_id = _parse_scope_id(request, "department", Department, "branch", "department")
        designation_id = _parse_scope_id(request, "designation", Designation, "department__branch", "designation")
        if branch_id:
            queryset = queryset.filter(employee__branch_id=branch_id)
        if department_id:
            queryset = queryset.filter(employee__department_id=department_id)
        if designation_id:
            queryset = queryset.filter(employee__designation_id=designation_id)
        employee_id = request.query_params.get("employee_id")
        if employee_id:
            try:
                employee_id = int(employee_id)
            except (TypeError, ValueError):
                raise ValidationError({"employee_id": "Select a valid employee."}) from None
            if not scope_queryset(Employee.objects.filter(pk=employee_id), request.user, "branch").exists():
                raise ValidationError({"employee_id": "You do not have access to this employee."})
            queryset = queryset.filter(employee_id=employee_id)
        search = request.query_params.get("search", "").strip()
        if len(search) > 100:
            raise ValidationError({"search": "Search must be 100 characters or fewer."})
        if search:
            queryset = queryset.filter(
                Q(employee__employee_code__icontains=search)
                | Q(employee__display_name__icontains=search)
                | Q(employee__user__first_name__icontains=search)
                | Q(employee__user__last_name__icontains=search)
            )
        state = request.query_params.get("status", "all").lower()
        today = timezone.localdate()
        if state == "current":
            queryset = queryset.filter(effective_from__lte=today).filter(Q(effective_to__isnull=True) | Q(effective_to__gte=today))
        elif state == "future":
            queryset = queryset.filter(effective_from__gt=today)
        elif state == "expired":
            queryset = queryset.filter(effective_to__lt=today)
        elif state != "all":
            raise ValidationError({"status": "Use current, future, expired, or all."})
        paginator = ShiftPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        return paginator.get_paginated_response(AssignmentReadSerializer(page, many=True).data)

    def post(self, request):
        _require(request, CanAssignShifts)
        serializer = AssignmentWriteSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        values = serializer.validated_data
        assignment = assign_shift(
            employee_id=values["employee_id"], shift_id=values["shift_id"],
            effective_from=values["effective_from"], effective_to=values.get("effective_to"),
            week_off_days=values["week_off_days"], actor=request.user,
        )
        assignment = _assignment_queryset(request.user).get(pk=assignment.pk)
        return success_response(AssignmentReadSerializer(assignment).data, "Shift assigned successfully.", 201)


class ShiftAssignmentBulkView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        _require(request, CanAssignShifts)
        serializer = BulkAssignmentWriteSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        values = serializer.validated_data
        assignments = bulk_assign_shifts(
            employees=values["employees"], shift=values["shift"], effective_from=values["effective_from"],
            effective_to=values.get("effective_to"), week_off_days=values["week_off_days"], actor=request.user,
        )
        rows = _assignment_queryset(request.user).filter(pk__in=[item.pk for item in assignments]).order_by("employee__employee_code")
        return success_response({"created_count": len(assignments), "results": AssignmentReadSerializer(rows, many=True).data},
                                f"Shift assigned to {len(assignments)} employees.", 201)


class ShiftAssignmentHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, employee_id):
        _require(request, CanViewShiftManagement)
        employee = scope_queryset(Employee.objects.select_related("branch"), request.user, "branch").filter(pk=employee_id).first()
        if employee is None:
            raise NotFound("Employee not found in your branch scope.")
        queryset = _assignment_queryset(request.user).filter(employee=employee).order_by("-effective_from", "-pk")
        paginator = ShiftPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        return paginator.get_paginated_response(AssignmentReadSerializer(page, many=True).data)

