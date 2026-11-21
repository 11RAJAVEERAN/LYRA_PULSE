from django.contrib.auth.hashers import check_password, make_password
from django.db import models
from django.db.models import Q

from apps.branches.models import Branch


class Device(models.Model):
    device_id = models.CharField(max_length=100, unique=True)
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, related_name="devices")
    name = models.CharField(max_length=150, blank=True)
    is_active = models.BooleanField(default=True)
    token_hash = models.CharField(max_length=128)
    last_seen = models.DateTimeField(null=True, blank=True)
    last_health_report_at = models.DateTimeField(null=True, blank=True)
    health_status = models.CharField(max_length=20, default="UNKNOWN")
    health_details = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["device_id"]
        constraints = [
            models.UniqueConstraint(
                fields=("branch",), condition=Q(is_active=True),
                name="one_fingerprint_device_per_branch",
            ),
        ]

    def set_token(self, token):
        self.token_hash = make_password(token)

    def verify_token(self, token):
        return check_password(token, self.token_hash)

    def __str__(self):
        return self.device_id


class DeviceDiagnosticLog(models.Model):
    """A bounded, administrator-visible record of a device-reported condition."""

    device = models.ForeignKey(Device, on_delete=models.PROTECT, related_name="diagnostics")
    severity = models.CharField(max_length=12, default="ERROR")
    code = models.CharField(max_length=64)
    subsystem = models.CharField(max_length=40)
    message = models.CharField(max_length=240, blank=True)
    details = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["device", "created_at"], name="device_diag_recent_idx")]
