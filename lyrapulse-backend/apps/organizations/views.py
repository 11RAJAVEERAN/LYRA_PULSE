from django.contrib.auth import get_user_model
from django.db import IntegrityError
from django.db import transaction
from django.shortcuts import get_object_or_404
from rest_framework import serializers, status
from rest_framework.exceptions import NotFound, PermissionDenied
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.common.responses import success_response

from .models import Organization
from .serializers import CompanySuperAdminSerializer, OrganizationSerializer

User = get_user_model()


def _is_company_superadmin(user):
    return bool(
        user.role == User.Role.SUPERADMIN
        and not user.is_platform_superadmin
        and user.organization_id
        and user.organization.is_active
    )


def _get_organization(user, organization_id):
    if user.is_platform_superadmin:
        queryset = Organization.objects.all()
    elif _is_company_superadmin(user) and user.organization_id == organization_id:
        queryset = Organization.objects.filter(pk=user.organization_id, is_active=True)
    else:
        raise NotFound("Company not found.")
    return get_object_or_404(queryset, pk=organization_id)


class OrganizationListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.is_platform_superadmin:
            queryset = Organization.objects.all()
        elif _is_company_superadmin(request.user):
            queryset = Organization.objects.filter(pk=request.user.organization_id)
        else:
            raise PermissionDenied("Company management access is required.")

        search = request.query_params.get("search", "").strip()
        if search:
            queryset = queryset.filter(name__icontains=search) | queryset.filter(code__icontains=search)
        state = request.query_params.get("status", "all").lower()
        if state == "active":
            queryset = queryset.filter(is_active=True)
        elif state == "inactive":
            queryset = queryset.filter(is_active=False)
        elif state != "all":
            raise serializers.ValidationError({"status": "Use active, inactive, or all."})
        return success_response(OrganizationSerializer(queryset.distinct(), many=True).data)

    def post(self, request):
        if not request.user.is_platform_superadmin:
            raise PermissionDenied("Only a Platform Super Admin can create a company.")
        serializer = OrganizationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            organization = serializer.save()
        except IntegrityError:
            raise serializers.ValidationError({"code": "A company with this code already exists."}) from None
        return success_response(OrganizationSerializer(organization).data, "Company created.", status.HTTP_201_CREATED)


class OrganizationDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        organization = _get_organization(request.user, pk)
        return success_response(OrganizationSerializer(organization).data)

    def patch(self, request, pk):
        organization = _get_organization(request.user, pk)
        if not request.user.is_platform_superadmin and set(request.data) - {"name"}:
            raise PermissionDenied("Company Super Admins may only edit their company name.")
        serializer = OrganizationSerializer(organization, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        try:
            organization = serializer.save()
        except IntegrityError:
            raise serializers.ValidationError({"code": "A company with this code already exists."}) from None
        return success_response(OrganizationSerializer(organization).data, "Company updated.")


class CompanySuperAdminListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get_queryset(self, request, organization_id):
        organization = _get_organization(request.user, organization_id)
        return organization, User.objects.filter(
            organization=organization,
            role=User.Role.SUPERADMIN,
            is_superuser=False,
        ).order_by("first_name", "last_name", "phone_number")

    def get(self, request, organization_id):
        _, queryset = self.get_queryset(request, organization_id)
        return success_response(CompanySuperAdminSerializer(queryset, many=True).data)

    def post(self, request, organization_id):
        organization, _ = self.get_queryset(request, organization_id)
        if not organization.is_active:
            raise PermissionDenied("Company Super Admins cannot be created for an inactive company.")
        serializer = CompanySuperAdminSerializer(
            data=request.data,
            context={"organization": organization, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return success_response(CompanySuperAdminSerializer(user).data, "Company Super Admin created.", status.HTTP_201_CREATED)


class CompanySuperAdminDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get_object(self, request, organization_id, user_id):
        organization = _get_organization(request.user, organization_id)
        return get_object_or_404(
            User.objects.filter(
                organization=organization,
                role=User.Role.SUPERADMIN,
                is_superuser=False,
            ),
            pk=user_id,
        )

    def get(self, request, organization_id, user_id):
        user = self.get_object(request, organization_id, user_id)
        return success_response(CompanySuperAdminSerializer(user).data)

    @transaction.atomic
    def patch(self, request, organization_id, user_id):
        organization = _get_organization(request.user, organization_id)
        Organization.objects.select_for_update().get(pk=organization.pk)
        user = self.get_object(request, organization_id, user_id)
        serializer = CompanySuperAdminSerializer(
            user,
            data=request.data,
            partial=True,
            context={"organization": user.organization, "request": request},
        )
        serializer.is_valid(raise_exception=True)
        next_organization = serializer.validated_data.get("organization", user.organization)
        is_deactivated = serializer.validated_data.get("is_active") is False
        if user.is_active and (is_deactivated or next_organization.pk != user.organization_id):
            active_count = User.objects.filter(
                organization_id=organization_id,
                role=User.Role.SUPERADMIN,
                is_superuser=False,
                is_active=True,
            ).count()
            if active_count <= 1:
                raise serializers.ValidationError({"organization_id": "At least one active Company Super Admin must remain assigned."})
        user = serializer.save()
        return success_response(CompanySuperAdminSerializer(user).data, "Company Super Admin updated.")