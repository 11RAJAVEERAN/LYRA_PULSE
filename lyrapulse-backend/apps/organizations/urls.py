from django.urls import path

from .views import (
    CompanySuperAdminDetailView,
    CompanySuperAdminListCreateView,
    OrganizationDetailView,
    OrganizationListCreateView,
)

urlpatterns = [
    path("", OrganizationListCreateView.as_view(), name="organization-list-create"),
    path("<int:pk>/", OrganizationDetailView.as_view(), name="organization-detail"),
    path("<int:organization_id>/super-admins/", CompanySuperAdminListCreateView.as_view(), name="company-super-admin-list-create"),
    path("<int:organization_id>/super-admins/<int:user_id>/", CompanySuperAdminDetailView.as_view(), name="company-super-admin-detail"),
]