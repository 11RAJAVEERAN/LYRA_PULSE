from rest_framework.pagination import PageNumberPagination

from apps.common.responses import success_response


class AdminAttendancePagination(PageNumberPagination):
    """Page-number pagination wrapped in the project's `{success, message, data}` envelope.

    `?page=` (1-based) and `?page_size=` (default 25, max 100). Values are validated by the query serializer
    first, so malformed values return a 400 rather than being silently replaced. A page past the end is a 404.
    """
    page_size = 25
    page_size_query_param = "page_size"
    max_page_size = 100

    def get_paginated_response(self, data, extra=None):
        paginator = self.page.paginator
        return success_response({
            **(extra or {}),
            "count": paginator.count,
            "page": self.page.number,
            "page_size": paginator.per_page,
            "total_pages": paginator.num_pages,
            "next": self.get_next_link(),
            "previous": self.get_previous_link(),
            "results": data,
        })