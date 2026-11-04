from rest_framework.generics import ListAPIView
from rest_framework.permissions import IsAuthenticated

from apps.accounts.permissions import IsHROrAdmin
from apps.common.responses import success_response

from .models import Branch
from .serializers import BranchSerializer


class BranchListView(ListAPIView):
    permission_classes = [IsAuthenticated, IsHROrAdmin]
    serializer_class = BranchSerializer

    def get_queryset(self):
        return Branch.objects.filter(is_active=True)

    def list(self, request, *args, **kwargs):
        branches = self.get_serializer(self.get_queryset(), many=True).data
        return success_response(branches, "Branches retrieved successfully")
