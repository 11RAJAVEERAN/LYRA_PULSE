from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.contrib.auth.models import PermissionsMixin
from django.db import models
from django.db.models.signals import m2m_changed
from django.dispatch import receiver


class UserManager(BaseUserManager):
    def create_user(self, phone_number, password=None, **extra_fields):
        if not phone_number:
            raise ValueError("Phone number is required")
        user = self.model(phone_number=phone_number, **extra_fields)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number, password=None, **extra_fields):
        if not password:
            raise ValueError("Superusers must have a password")
        extra_fields.setdefault("role", User.Role.SUPERADMIN)
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("is_active", True)
        return self.create_user(phone_number, password=password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        SUPERADMIN = "SUPERADMIN", "Superadmin"
        ADMIN = "ADMIN", "Admin"
        HR = "HR", "HR"
        MANAGER = "MANAGER", "Manager"
        EMPLOYEE = "EMPLOYEE", "Employee"

    phone_number = models.CharField(max_length=15, unique=True)
    email = models.EmailField(blank=True)
    first_name = models.CharField(max_length=100, blank=True)
    last_name = models.CharField(max_length=100, blank=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.EMPLOYEE)
    # Business data scope (separate from `role` = what they can do, and from is_staff/is_superuser = Django admin access).
    organization = models.ForeignKey(
        "organizations.Organization", on_delete=models.PROTECT, related_name="users",
        null=True, blank=True,
        help_text="Company this user administers. Leave empty for SUPERADMIN (global access).",
    )
    allowed_branches = models.ManyToManyField(
        "branches.Branch", related_name="admin_users", blank=True,
        help_text="Branches this user may manage. Must belong to the selected organization.",
    )
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    BUSINESS_ROLES = (Role.ADMIN, Role.HR, Role.MANAGER)

    objects = UserManager()
    USERNAME_FIELD = "phone_number"
    REQUIRED_FIELDS = ["email"]

    def __str__(self):
        return self.phone_number

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}".strip() or self.phone_number

    @property
    def has_global_scope(self):
        return self.role == self.Role.SUPERADMIN

    def scoped_branch_ids(self):
        """Branch ids a non-SUPERADMIN may access: allowed branches that belong to the user's active organization."""
        if self.organization_id is None or not self.organization.is_active:
            return []
        return list(self.allowed_branches.filter(organization_id=self.organization_id).values_list("id", flat=True))

    def clean(self):
        super().clean()
        from .scope import validate_scope
        # Branch assignments are validated where they are submitted (admin form / API serializer / m2m signal).
        validate_scope(self.role, self.organization, [])


class OTPVerification(models.Model):
    class Purpose(models.TextChoices):
        LOGIN = "LOGIN", "Login"
        ADMIN_LOGIN = "ADMIN_LOGIN", "Admin login"
        PHONE_VERIFICATION = "PHONE_VERIFICATION", "Phone verification"

    phone_number = models.CharField(max_length=15, db_index=True)
    otp_hash = models.CharField(max_length=128)
    purpose = models.CharField(max_length=30, choices=Purpose.choices, default=Purpose.LOGIN)
    attempts = models.PositiveSmallIntegerField(default=0)
    max_attempts = models.PositiveSmallIntegerField(default=5)
    expires_at = models.DateTimeField()
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    verified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [models.Index(fields=("phone_number", "purpose", "created_at"))]


@receiver(m2m_changed, sender=User.allowed_branches.through)
def validate_allowed_branches_organization(sender, instance, action, reverse, pk_set, **kwargs):
    """Last line of defence: an allowed branch must belong to the user's organization."""
    if action != "pre_add" or not pk_set:
        return
    from django.core.exceptions import ValidationError
    if reverse:  # branch.admin_users.add(...): instance is a Branch, pk_set holds user ids
        if instance.organization_id is None or User.objects.filter(pk__in=pk_set).exclude(organization_id=instance.organization_id).exists():
            raise ValidationError("A branch can only be assigned to users of the same organization.")
        return
    from apps.branches.models import Branch  # instance is a User, pk_set holds branch ids
    if instance.organization_id is None or Branch.objects.filter(pk__in=pk_set).exclude(organization_id=instance.organization_id).exists():
        raise ValidationError("Allowed branches must belong to the user's organization.")
