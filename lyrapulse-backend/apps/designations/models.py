from django.db import models

from apps.departments.models import Department


class Designation(models.Model):
    name = models.CharField(max_length=150)
    department = models.ForeignKey(Department, on_delete=models.PROTECT, related_name="designations")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=("department", "name"), name="unique_designation_per_department")]
        ordering = ["name"]

    def __str__(self):
        return self.name