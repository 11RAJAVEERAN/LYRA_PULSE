from django.db import models

from apps.branches.models import Branch


class Department(models.Model):
    name = models.CharField(max_length=150)
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, related_name="departments")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=("branch", "name"), name="unique_department_per_branch")]
        ordering = ["name"]

    def __str__(self):
        return self.name