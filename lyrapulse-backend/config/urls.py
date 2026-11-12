import re

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import HttpResponseNotFound
from django.urls import include, path, re_path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView


def _block_public_attendance_media(request, path):
    return HttpResponseNotFound()


urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/auth/", include("apps.accounts.urls")),
    path("api/v1/organizations/", include("apps.organizations.urls")),
    path("api/v1/", include("apps.branches.urls")),
    path("api/v1/attendance/", include("apps.attendance.urls")),
    path("api/v1/", include("apps.shifts.urls")),
    path("api/v1/devices/", include("apps.devices.urls")),
    path("api/v1/fingerprints/", include("apps.fingerprints.urls")),
    path("api/v1/", include("apps.departments.urls")),
    path("api/v1/", include("apps.designations.urls")),
    path("api/v1/", include("apps.employees.urls")),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
]

if settings.DEBUG:  # development only; never serve user uploads through Django in production
    media_prefix = settings.MEDIA_URL.strip("/")
    if media_prefix:
        urlpatterns += [
            re_path(
                rf"^{re.escape(media_prefix)}/attendance/(?P<path>.*)$",
                _block_public_attendance_media,
            ),
        ]
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

