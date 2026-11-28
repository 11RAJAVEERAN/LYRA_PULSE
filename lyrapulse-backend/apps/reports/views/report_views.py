from rest_framework.exceptions import NotFound
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from apps.accounts.permissions import CanViewEmployees
from apps.common.responses import success_response

from ..exports.renderers import export_report
from ..serializers.queries import ReportQuerySerializer
from ..serializers.rows import ReportPageSerializer
from ..services.reports import REPORT_TITLES, build_report


class ReportBaseView(APIView):
    permission_classes = [IsAuthenticated, CanViewEmployees]

    def get_report(self, report):
        if report not in REPORT_TITLES:
            raise NotFound("Report not found.")
        return report

    def get_query(self, request):
        serializer = ReportQuerySerializer(data=request.query_params, context={"request": request})
        serializer.is_valid(raise_exception=True)
        return serializer.validated_data


class ReportDataView(ReportBaseView):
    def get(self, request, report):
        report = self.get_report(report)
        query = self.get_query(request)
        data = build_report(report, request.user, query, paginate=True)
        if query["page"] > data["total_pages"]:
            raise NotFound("Page not found.")
        response = ReportPageSerializer(data={"title": REPORT_TITLES[report], **data})
        response.is_valid(raise_exception=True)
        return success_response(response.validated_data)


class ReportExportView(ReportBaseView):
    def get(self, request, report):
        report = self.get_report(report)
        query = self.get_query(request)
        data = build_report(report, request.user, query, paginate=False)
        return export_report(report, data, query)
