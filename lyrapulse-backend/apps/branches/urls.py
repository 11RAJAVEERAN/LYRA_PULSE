from django.urls import path

from .views import BranchAttendanceRadiusView, BranchDetailView, BranchListCreateView

urlpatterns = [
	path("branches/", BranchListCreateView.as_view(), name="branch-list-create"),
	path("branches/<int:pk>/attendance-radius/", BranchAttendanceRadiusView.as_view(), name="branch-attendance-radius"),
	path("branches/<int:pk>/", BranchDetailView.as_view(), name="branch-detail"),
]
