from django.urls import path

from .views.report_views import ReportDataView, ReportExportView

urlpatterns = [
    path("<slug:report>/export/", ReportExportView.as_view(), name="report-export"),
    path("<slug:report>/", ReportDataView.as_view(), name="report-list"),
]
