from rest_framework.response import Response


def success_response(data=None, message="Operation successful", status=200):
    return Response({"success": True, "message": message, "data": data if data is not None else {}}, status=status)