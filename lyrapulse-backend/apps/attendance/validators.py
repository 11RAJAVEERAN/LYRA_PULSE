"""Server-side validation for attendance photos.

The file *content* is inspected with Pillow; the client filename and MIME type are never trusted.
Only JPEG and PNG are accepted. On success the upload's name is normalised to `photo.jpg` / `photo.png`
so that the storage path never depends on whatever the client called the file.
"""
from io import BytesIO

from PIL import Image, UnidentifiedImageError
from rest_framework import serializers

MAX_PHOTO_BYTES = 5 * 1024 * 1024
ALLOWED_FORMATS = {"JPEG": "jpg", "PNG": "png"}


def validate_attendance_photo(uploaded_file):
    if uploaded_file.size == 0:
        raise serializers.ValidationError("The uploaded photo is empty.")
    if uploaded_file.size > MAX_PHOTO_BYTES:
        raise serializers.ValidationError(f"Photo is too large. Maximum size is {MAX_PHOTO_BYTES // (1024 * 1024)} MB.")

    uploaded_file.seek(0)
    data = uploaded_file.read()
    uploaded_file.seek(0)
    try:
        image = Image.open(BytesIO(data))
        image.verify()
        detected = image.format
    except (UnidentifiedImageError, Image.DecompressionBombError, OSError, SyntaxError, ValueError):
        raise serializers.ValidationError("The uploaded file is not a valid JPEG or PNG image.")
    if detected not in ALLOWED_FORMATS:
        raise serializers.ValidationError("Unsupported image format. Only JPEG and PNG photos are accepted.")

    uploaded_file.name = f"photo.{ALLOWED_FORMATS[detected]}"
    return uploaded_file
