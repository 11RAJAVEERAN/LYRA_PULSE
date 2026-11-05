class AttendanceError(Exception):
    """A business-rule failure that is reported to the client with a stable machine-readable `code`.

    Rendered by the attendance views as:
        {"success": false, "message": "<message>", "errors": {"code": "<code>", ...extra}}
    """

    def __init__(self, code, message, status_code=400, **extra):
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code
        self.extra = extra
