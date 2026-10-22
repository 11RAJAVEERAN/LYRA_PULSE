from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import apps.attendance.models


class Migration(migrations.Migration):
    dependencies = [
        ("attendance", "0001_initial"),
        ("devices", "0001_initial"),
        ("accounts", "0001_initial"),
    ]
    operations = [
        migrations.RemoveConstraint("attendance", "unique_employee_attendance_per_day"),
        migrations.AlterField("attendance", "check_in_latitude", models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True)),
        migrations.AlterField("attendance", "check_in_longitude", models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True)),
        migrations.AlterField("attendance", "check_in_accuracy", models.FloatField(blank=True, help_text="GPS accuracy reported by the device, in meters.", null=True)),
        migrations.AlterField("attendance", "check_in_distance_meters", models.FloatField(blank=True, help_text="Distance from the branch attendance location, in meters.", null=True)),
        migrations.AlterField("attendance", "check_in_location_verified", models.BooleanField(blank=True, null=True)),
        migrations.AlterField("attendance", "check_in_photo", models.ImageField(blank=True, upload_to=apps.attendance.models.check_in_photo_path)),
        migrations.AddField("attendance", "source", models.CharField(choices=[("MOBILE_GPS", "Mobile GPS"), ("BIOMETRIC", "Biometric"), ("MANUAL", "Admin manual")], default="MOBILE_GPS", max_length=20)),
        migrations.AddField("attendance", "created_by", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.PROTECT, related_name="manual_attendance_records", to=settings.AUTH_USER_MODEL)),
        migrations.AddField("attendance", "device", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.PROTECT, related_name="attendance_records", to="devices.device")),
        migrations.CreateModel(
            name="DeviceAttendanceEvent",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("event_id", models.UUIDField()), ("fingerprint_slot", models.PositiveIntegerField()),
                ("occurred_at", models.DateTimeField()), ("outcome", models.CharField(default="RECEIVED", max_length=24)),
                ("response", models.JSONField(blank=True, default=dict)), ("received_at", models.DateTimeField(auto_now_add=True)),
                ("attendance", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.PROTECT, related_name="device_events", to="attendance.attendance")),
                ("device", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="attendance_events", to="devices.device")),
            ],
            options={"constraints": [models.UniqueConstraint(fields=("device", "event_id"), name="unique_device_attendance_event")], "indexes": [models.Index(fields=["device", "received_at"], name="device_event_received_idx")]},
        ),
        migrations.CreateModel(
            name="AttendanceEvent",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("action", models.CharField(choices=[("CHECK_IN", "Check-in"), ("CHECK_OUT", "Check-out")], max_length=12)),
                ("method", models.CharField(choices=[("MOBILE_GPS", "Mobile GPS"), ("BIOMETRIC", "Biometric"), ("MANUAL", "Admin manual")], max_length=16)),
                ("occurred_at", models.DateTimeField()),
                ("actor", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.PROTECT, related_name="attendance_actions", to=settings.AUTH_USER_MODEL)),
                ("attendance", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="actions", to="attendance.attendance")),
                ("device", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.PROTECT, related_name="attendance_actions", to="devices.device")),
                ("device_event", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.PROTECT, related_name="actions", to="attendance.deviceattendanceevent")),
            ],
            options={"ordering": ["occurred_at", "id"]},
        ),
    ]
