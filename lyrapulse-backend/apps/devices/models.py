from django.contrib.auth.hashers import check_password, make_password
from django.db import models

from apps.branches.models import Branch


class Device(models.Model):
    device_id = models.CharField(max_length=100, unique=True)
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, related_name="devices")
    name = models.CharField(max_length=150, blank=True)
    is_active = models.BooleanField(default=True)
    token_hash = models.CharField(max_length=128)
    last_seen = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["device_id"]
        constraints = [
            models.UniqueConstraint(
                fields=("branch",),
                name="one_fingerprint_device_per_branch",
            ),
        ]

    def set_token(self, token):
        self.token_hash = make_password(token)

    def verify_token(self, token):
        return check_password(token, self.token_hash)

    def __str__(self):
        return self.device_id
