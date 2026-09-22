from rest_framework.views import exception_handler


def api_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is None:
        return response
    detail = response.data
    if isinstance(detail, dict) and "detail" in detail and len(detail) == 1:
        errors = {}
        message = str(detail["detail"])
    else:
        errors = detail
        message = "Request failed"
    response.data = {"success": False, "message": message, "errors": errors}
    return response