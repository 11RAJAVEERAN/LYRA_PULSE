import os

from django.conf import settings
from django.core.files.storage import FileSystemStorage
from django.utils.deconstruct import deconstructible


@deconstructible
class PrivateAttendanceStorage(FileSystemStorage):
    """Keep new attendance photos private while allowing reads of legacy media files."""

    def __init__(self, *args, **kwargs):
        kwargs.pop("location", None)
        super().__init__(*args, **kwargs)

    @property
    def base_location(self):
        return str(settings.PRIVATE_MEDIA_ROOT)

    @property
    def location(self):
        return str(settings.PRIVATE_MEDIA_ROOT)

    @property
    def _legacy_storage(self):
        return FileSystemStorage(location=settings.MEDIA_ROOT)

    def _open(self, name, mode="rb"):
        try:
            return super()._open(name, mode)
        except FileNotFoundError:
            return self._legacy_storage._open(name, mode)

    def exists(self, name):
        private_path = FileSystemStorage.path(self, name)
        return os.path.lexists(private_path) or self._legacy_storage.exists(name)

    def path(self, name):
        return FileSystemStorage.path(self, name)

    def url(self, name):
        raise ValueError("Attendance photos have no public URL.")


private_attendance_storage = PrivateAttendanceStorage()
