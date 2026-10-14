"""Validation for employee legal-document uploads.

Rules come from the reference form: PNG, JPG, JPEG and PDF; max 10 MB for images and 1 MB for PDFs.
The file *content* is inspected (magic bytes + Pillow for images); the client filename/MIME is never trusted.
"""
from io import BytesIO

from PIL import Image, UnidentifiedImageError
from rest_framework import serializers

MAX_IMAGE_BYTES = 10 * 1024 * 1024
MAX_PDF_BYTES = 1 * 1024 * 1024
ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "pdf"}
IMAGE_FORMATS = {"PNG": ("image/png", {"png"}), "JPEG": ("image/jpeg", {"jpg", "jpeg"})}


def validate_document_file(uploaded_file):
    """Return the detected content type, or raise a field-level ValidationError."""
    name = uploaded_file.name or ""
    extension = name.rsplit(".", 1)[-1].lower() if "." in name else ""
    if extension not in ALLOWED_EXTENSIONS:
        raise serializers.ValidationError("Unsupported file type. Allowed: PNG, JPG, JPEG and PDF.")
    if uploaded_file.size == 0:
        raise serializers.ValidationError("The uploaded file is empty.")

    uploaded_file.seek(0)
    head = uploaded_file.read(8)
    uploaded_file.seek(0)

    if extension == "pdf":
        if not head.startswith(b"%PDF-"):
            raise serializers.ValidationError("The file is not a valid PDF.")
        if uploaded_file.size > MAX_PDF_BYTES:
            raise serializers.ValidationError("PDF files must be 1 MB or smaller.")
        return "application/pdf"

    if uploaded_file.size > MAX_IMAGE_BYTES:
        raise serializers.ValidationError("Image files must be 10 MB or smaller.")
    try:
        image = Image.open(BytesIO(uploaded_file.read()))
        image.verify()
        detected = image.format
    except (UnidentifiedImageError, OSError, SyntaxError, ValueError):
        raise serializers.ValidationError("The file is not a valid PNG or JPEG image.")
    finally:
        uploaded_file.seek(0)
    if detected not in IMAGE_FORMATS or extension not in IMAGE_FORMATS[detected][1]:
        raise serializers.ValidationError("The file content does not match its extension (PNG, JPG or JPEG required).")
    return IMAGE_FORMATS[detected][0]