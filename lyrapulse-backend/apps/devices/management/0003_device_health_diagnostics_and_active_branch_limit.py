from django.db import migrations, models
from django.db.models import Q
import django.db.models.deletion


def refuse_multiple_active_devices(apps, schema_editor):
    Device = apps.get_model("devices", "Device")
    duplicate = (
        Device.objects.using(schema_editor.connection.alias)
        .filter(is_active=True)
        .values("branch_id")
        .annotate(device_count=models.Count("id"))
        .filter(device_count__gt=1)
        .exists()
    )
    if duplicate:
        raise RuntimeError(
            "Cannot enforce one active fingerprint device per branch: reconcile active duplicates first."
        )


class Migration(migrations.Migration):
    dependencies = [("devices", "0002_device_heartbeat_and_branch_limit")]

    operations = [
        migrations.RemoveConstraint(
            model_name="device", name="one_fingerprint_device_per_branch",
        ),
        migrations.RunPython(refuse_multiple_active_devices, migrations.RunPython.noop),
        migrations.AddConstraint(
            model_name="device",
            constraint=models.UniqueConstraint(
                fields=("branch",), condition=Q(is_active=True),
                name="one_fingerprint_device_per_branch",
            ),
        ),
        migrations.AddField(
            model_name="device", name="last_health_report_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="device", name="health_status",
            field=models.CharField(default="UNKNOWN", max_length=20),
        ),
        migrations.AddField(
            model_name="device", name="health_details",
            field=models.JSONField(blank=True, default=dict),
        ),
        migrations.CreateModel(
            name="DeviceDiagnosticLog",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("severity", models.CharField(default="ERROR", max_length=12)),
                ("code", models.CharField(max_length=64)),
                ("subsystem", models.CharField(max_length=40)),
                ("message", models.CharField(blank=True, max_length=240)),
                ("details", models.JSONField(blank=True, default=dict)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("resolved_at", models.DateTimeField(blank=True, null=True)),
                ("device", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="diagnostics", to="devices.device")),
            ],
            options={
                "ordering": ["-created_at"],
                "indexes": [models.Index(fields=["device", "created_at"], name="device_diag_recent_idx")],
            },
        ),
    ]
