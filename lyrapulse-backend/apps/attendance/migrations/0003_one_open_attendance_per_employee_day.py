from django.db import migrations, models
from django.db.models import Q


class Migration(migrations.Migration):
    dependencies = [("attendance", "0002_sessions_devices_events")]

    operations = [
        migrations.AddConstraint(
            model_name="attendance",
            constraint=models.UniqueConstraint(
                fields=("employee", "attendance_date"),
                condition=Q(check_out_at__isnull=True),
                name="one_open_attendance_per_employee_day",
            ),
        ),
    ]
