from django.core.exceptions import ValidationError
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models

MIN_ATTENDANCE_RADIUS_METERS = 1
MAX_ATTENDANCE_RADIUS_METERS = 1000


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
    # Attendance location. Null = not configured yet; attendance fails safely for such a branch (never defaults to 0/0).
    latitude = models.DecimalField(
        "attendance latitude", max_digits=9, decimal_places=6, null=True, blank=True,
        validators=[MinValueValidator(-90), MaxValueValidator(90)],
        help_text="Latitude of the branch location used for employee attendance verification.",
    )
    longitude = models.DecimalField(
        "attendance longitude", max_digits=9, decimal_places=6, null=True, blank=True,
        validators=[MinValueValidator(-180), MaxValueValidator(180)],
        help_text="Longitude of the branch location used for employee attendance verification.",
    )
    attendance_radius_meters = models.PositiveIntegerField(
        "allowed radius (meters)", default=3, validators=[MinValueValidator(1)],
        help_text="Employees must be within this distance from the branch to check in or check out.",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        label = f"{self.name} ({self.code})"
        return f"{label} - {self.organization.name}" if self.organization_id else label

    @property
    def has_attendance_location(self):
        """True when attendance coordinates and a positive radius are configured."""
        return self.latitude is not None and self.longitude is not None and (self.attendance_radius_meters or 0) > 0

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
        if self._attendance_radius_changed():
            self._validate_attendance_radius()
        if (self.latitude is None) != (self.longitude is None):
            raise ValidationError({
                "latitude" if self.latitude is None else "longitude": "Set both latitude and longitude, or leave both empty.",
            })

    def save(self, *args, **kwargs):
        self._check_admin_scope_on_organization_change()
        update_fields = kwargs.get("update_fields")
        if (update_fields is None or "attendance_radius_meters" in update_fields) and self._attendance_radius_changed():
            self._validate_attendance_radius()
        super().save(*args, **kwargs)

    def _attendance_radius_changed(self):
        if self._state.adding:
            return True
        previous = type(self).objects.filter(pk=self.pk).values_list("attendance_radius_meters", flat=True).first()
        return previous is None or previous != self.attendance_radius_meters

    def _validate_attendance_radius(self):
        radius = self.attendance_radius_meters
        if isinstance(radius, bool) or not isinstance(radius, int) or not MIN_ATTENDANCE_RADIUS_METERS <= radius <= MAX_ATTENDANCE_RADIUS_METERS:
            raise ValidationError({"attendance_radius_meters": f"Attendance radius must be between {MIN_ATTENDANCE_RADIUS_METERS} and {MAX_ATTENDANCE_RADIUS_METERS} metres."})
