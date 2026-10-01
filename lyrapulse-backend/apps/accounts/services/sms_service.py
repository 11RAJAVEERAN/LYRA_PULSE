from django.conf import settings


class SMSService:
    def send_otp(self, phone_number, otp):
        raise NotImplementedError


class MockSMSService(SMSService):
    def send_otp(self, phone_number, otp):
        # Mock provider intentionally emits neither recipient nor OTP to logs.
        return None


def get_sms_service():
    if settings.SMS_PROVIDER == "mock":
        return MockSMSService()
    raise ValueError(f"Unsupported SMS provider: {settings.SMS_PROVIDER}")
