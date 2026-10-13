from django.core.exceptions import ValidationError
from django.db import models


class Branch(models.Model):
    # Nullable on purpose: branches created before organizations existed keep working
    # until a SUPERADMIN assigns them (Django Admin -> Branches).
    organization = models.ForeignKey(
        "organizations.Organization", on_delete=models.PROTECT, related_name="branches",
        null=True, blank=True,
        help_text="Company that owns this branch.",
    )
    name = models.CharField(max_length=150)
    code = models.CharField(max_length=30, unique=True)
    address = models.TextField(blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    attendance_radius_meters = models.PositiveIntegerField(default=3)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        label = f"{self.name} ({self.code})"
        return f"{label} - {self.organization.name}" if self.organization_id else label

    def _check_admin_scope_on_organization_change(self):
        """A branch cannot move to another organization while admins are scoped to it."""
        if not self.pk:
            return
        previous = Branch.objects.filter(pk=self.pk).values_list("organization_id", flat=True).first()
        if previous == self.organization_id:
            return
        if self.admin_users.exists():
            raise ValidationError({
                "organization": "Remove this branch from its admin users' allowed branches before changing its organization.",
            })

    def clean(self):
        super().clean()
        self._check_admin_scope_on_organization_change()

    def save(self, *args, **kwargs):
        self._check_admin_scope_on_organization_change()
        super().save(*args, **kwargs)
