from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


def preserve_existing_mobile_behavior(apps, schema_editor):
    Employee = apps.get_model("employees", "Employee")
    # Project B previously allowed GPS attendance and required a photo for every mobile action.
    # Preserve that effective behavior for existing employees; biometric is new and remains opt-in.
    Employee.objects.all().update(
        biometric_attendance_enabled=False,
        mobile_gps_attendance_enabled=True,
        photo_attendance_enabled=True,
    )


class Migration(migrations.Migration):
    dependencies = [("employees", "0002_employee_details_form"), migrations.swappable_dependency(settings.AUTH_USER_MODEL)]
    operations = [
        migrations.AddField("employee", "biometric_attendance_enabled", models.BooleanField(default=False)),
        migrations.AddField("employee", "mobile_gps_attendance_enabled", models.BooleanField(default=False)),
        migrations.AddField("employee", "photo_attendance_enabled", models.BooleanField(default=False)),
        migrations.RunPython(preserve_existing_mobile_behavior, migrations.RunPython.noop),
        migrations.CreateModel(
            name="AttendancePermissionAudit",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("previous_values", models.JSONField()),
                ("new_values", models.JSONField()),
                ("changed_at", models.DateTimeField(auto_now_add=True)),
                ("actor", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="attendance_permission_changes", to=settings.AUTH_USER_MODEL)),
                ("employee", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="attendance_permission_audits", to="employees.employee")),
            ],
            options={"ordering": ["-changed_at"]},
        ),
    ]
