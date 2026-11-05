from django.urls import path

from .views import ShiftAssignmentBulkView, ShiftAssignmentHistoryView, ShiftAssignmentListView, ShiftDetailView, ShiftListCreateView

urlpatterns = [
    path("shifts/", ShiftListCreateView.as_view(), name="shift-list-create"),
    path("shifts/<int:pk>/", ShiftDetailView.as_view(), name="shift-detail"),
    path("shift-assignments/", ShiftAssignmentListView.as_view(), name="shift-assignment-list-create"),
    path("shift-assignments/bulk/", ShiftAssignmentBulkView.as_view(), name="shift-assignment-bulk"),
    path("shift-assignments/history/<int:employee_id>/", ShiftAssignmentHistoryView.as_view(), name="shift-assignment-history"),
]
