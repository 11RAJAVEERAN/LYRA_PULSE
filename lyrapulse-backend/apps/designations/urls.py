from django.urls import path

from .views import DesignationDetailView, DesignationListCreateView

urlpatterns = [
    path("designations/", DesignationListCreateView.as_view(), name="designation-list-create"),
    path("designations/<int:pk>/", DesignationDetailView.as_view(), name="designation-detail"),
]
