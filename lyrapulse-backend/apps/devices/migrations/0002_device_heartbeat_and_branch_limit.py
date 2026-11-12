from django.db import migrations, models
from django.db.models import Count


def refuse_existing_multiple_branch_devices(apps, schema_editor):
    Device = apps.get_model("devices", "Device")
    duplicates = (
        Device.objects.using(schema_editor.connection.alias)
        .values("branch_id")
        .annotate(device_count=Count("id"))
        .filter(device_count__gt=1)
    )
    if duplicates.exists():
        raise RuntimeError(
            "Cannot enforce one fingerprint device per branch: existing branch device duplicates must be reconciled first."
        )


class Migration(migrations.Migration):
    dependencies = [("devices", "0001_initial")]

    operations = [
        migrations.AddField(
            model_name="device",
            name="last_seen",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.RunPython(refuse_existing_multiple_branch_devices, migrations.RunPython.noop),
        migrations.AddConstraint(
            model_name="device",
            constraint=models.UniqueConstraint(
                fields=("branch",), name="one_fingerprint_device_per_branch"
            ),
        ),
    ]
