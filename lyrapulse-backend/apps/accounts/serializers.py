import re

from rest_framework import serializers


def normalize_phone_number(value):
    digits = re.sub(r"\D", "", value or "")
    if len(digits) == 10:
        return digits
    if len(digits) == 12 and digits.startswith("91"):
        return digits[2:]
    raise serializers.ValidationError("Enter a valid 10-digit phone number")


class PhoneSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20)

    def validate_phone_number(self, value):
        return normalize_phone_number(value)


class VerifyOTPSerializer(PhoneSerializer):
    otp = serializers.RegexField(regex=r"^\d{6}$")


class AdminOTPSendSerializer(serializers.Serializer):
    identifier = serializers.CharField(max_length=254)


class AdminOTPVerifySerializer(AdminOTPSendSerializer):
    otp = serializers.RegexField(regex=r"^\d{6}$")
