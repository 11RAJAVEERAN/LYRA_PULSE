import logging

from django.conf import settings

logger = logging.getLogger(__name__)


class SMSService:
    def send_otp(self, phone_number, otp):
        raise NotImplementedError


class MockSMSService(SMSService):
    def send_otp(self, phone_number, otp):
        if settings.DEBUG:
            logger.info("Development OTP generated for %s: %s", phone_number, otp)


def get_sms_service():
    if settings.SMS_PROVIDER == "mock":
        return MockSMSService()
    raise ValueError(f"Unsupported SMS provider: {settings.SMS_PROVIDER}")