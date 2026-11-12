from django.db import IntegrityError
from django.shortcuts import get_object_or_404
from rest_framework import serializers, status
from rest_framework.exceptions import NotFound, PermissionDenied
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.accounts.scope import scope_queryset
from apps.common.responses import success_response

from .models import Branch
from .serializers import AttendanceRadiusUpdateSerializer, BranchSerializer


def _is_company_superadmin(user):
    return bool(
        user.role == User.Role.SUPERADMIN
        and not user.is_platform_superadmin
        and user.organization_id
        and user.organization.is_active
    )


def _can_read_branches(user):
    return user.is_platform_superadmin or _is_company_superadmin(user) or user.has_perm("employees.view_employee")


def _branch_queryset(user):
    if user.is_platform_superadmin:
        return Branch.objects.select_related("organization")
    if _is_company_superadmin(user):
        return Branch.objects.filter(organization_id=user.organization_id).select_related("organization")
    if user.is_active and user.organization_id and user.organization.is_active and user.has_perm("employees.view_employee"):
        return scope_queryset(Branch.objects.all(), user, "id").select_related("organization")
    return Branch.objects.none()


def _require_manager(user):
    if not (user.is_platform_superadmin or _is_company_superadmin(user)):
        raise PermissionDenied("Only a Platform or Company Super Admin can manage branches.")


class BranchAttendanceRadiusView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        user = request.user
        if not user.is_active or not user.has_active_company_access:
            raise PermissionDenied("Active company access is required.")

        if user.is_platform_superadmin:
            branches = Branch.objects.all()
        elif _is_company_superadmin(user):
            branches = Branch.objects.filter(organization_id=user.organization_id)
        elif user.role == User.Role.ADMIN:
            branches = scope_queryset(
                Branch.objects.filter(organization_id=user.organization_id),
                user,
                "id",
            )
        else:
            raise PermissionDenied("You do not have permission to update a branch attendance radius.")

        branch = get_object_or_404(branches, pk=pk)
        serializer = AttendanceRadiusUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        branch.attendance_radius_meters = serializer.validated_data["attendance_radius_meters"]
        branch.save(update_fields=("attendance_radius_meters", "updated_at"))
        return success_response(
            {"id": branch.pk, "attendance_radius_meters": branch.attendance_radius_meters},
            "Branch attendance radius updated.",
        )


class BranchListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _can_read_branches(request.user):
            raise PermissionDenied("Branch access is required.")
        queryset = _branch_queryset(request.user)

        organization_id = request.query_params.get("organization")
        if organization_id:
            if not request.user.is_platform_superadmin and str(request.user.organization_id) != organization_id:
                raise NotFound("Company not found.")
            try:
                queryset = queryset.filter(organization_id=int(organization_id))
            except (TypeError, ValueError):
                raise serializers.ValidationError({"organization": "Select a valid company."}) from None

        if request.query_params.get("unassigned", "").lower() == "true":
            if not request.user.is_platform_superadmin:
                raise PermissionDenied("Only a Platform Super Admin can view unassigned legacy branches.")
            queryset = queryset.filter(organization__isnull=True)

        state = request.query_params.get("status")
        if state is None:
            state = "all" if request.query_params.get("include_inactive", "").lower() == "true" else "active"
        state = state.lower()
        if state == "active":
            queryset = queryset.filter(is_active=True)
        elif state == "inactive":
            queryset = queryset.filter(is_active=False)
        elif state != "all":
            raise serializers.ValidationError({"status": "Use active, inactive, or all."})

        search = request.query_params.get("search", "").strip()
        if len(search) > 100:
            raise serializers.ValidationError({"search": "Search must be 100 characters or fewer."})
        if search:
            queryset = queryset.filter(name__icontains=search) | queryset.filter(code__icontains=search)
        branches = BranchSerializer(queryset.distinct().order_by("name", "pk"), many=True).data
        return success_response(branches, "Branches retrieved successfully")

    def post(self, request):
        _require_manager(request.user)
        serializer = BranchSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        try:
            branch = serializer.save()
        except IntegrityError:
            raise serializers.ValidationError({"code": "A branch with this code already exists."}) from None
        return success_response(BranchSerializer(branch).data, "Branch created.", status.HTTP_201_CREATED)


class BranchDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get_object(self, request, pk):
        if not _can_read_branches(request.user):
            raise PermissionDenied("Branch access is required.")
        return get_object_or_404(_branch_queryset(request.user), pk=pk)

    def get(self, request, pk):
        return success_response(BranchSerializer(self.get_object(request, pk)).data)

    def patch(self, request, pk):
        _require_manager(request.user)
        branch = self.get_object(request, pk)
        serializer = BranchSerializer(branch, data=request.data, partial=True, context={"request": request})
        serializer.is_valid(raise_exception=True)
        try:
            branch = serializer.save()
        except IntegrityError:
            raise serializers.ValidationError({"code": "A branch with this code already exists."}) from None
        return success_response(BranchSerializer(branch).data, "Branch updated.")
