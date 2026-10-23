from django.db import migrations, models


def preserve_existing_location_requirement(apps, schema_editor):
    Employee = apps.get_model("employees", "Employee")
    # Previously every mobile action was geofenced. Keep that behavior for existing mobile users.
    Employee.objects.filter(mobile_gps_attendance_enabled=True).update(location_attendance_enabled=True)


class Migration(migrations.Migration):
    dependencies = [("employees", "0003_attendance_permissions_audit")]

    operations = [
        migrations.AddField(
            model_name="employee",
            name="location_attendance_enabled",
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name="employee",
            name="auto_punch_out_enabled",
            field=models.BooleanField(default=False),
        ),
        migrations.RunPython(preserve_existing_location_requirement, migrations.RunPython.noop),
    ]
