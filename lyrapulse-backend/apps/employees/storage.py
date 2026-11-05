from django.conf import settings
from django.core.files.storage import FileSystemStorage
from django.utils.deconstruct import deconstructible


@deconstructible
class PrivateDocumentStorage(FileSystemStorage):
    """Stores employee legal documents outside MEDIA_ROOT and with no public URL.

    Files are only ever served through the authenticated download endpoint
    (`/api/v1/employees/<id>/documents/<doc_id>/download/`). The location is resolved lazily so tests can
    override `PRIVATE_MEDIA_ROOT`.
    """

    def __init__(self, *args, **kwargs):
        kwargs.pop("location", None)
        super().__init__(*args, **kwargs)

    @property
    def base_location(self):
        return str(settings.PRIVATE_MEDIA_ROOT)

    @property
    def location(self):
        return str(settings.PRIVATE_MEDIA_ROOT)

    def url(self, name):
        raise ValueError("Private employee documents have no public URL.")


private_document_storage = PrivateDocumentStorage()