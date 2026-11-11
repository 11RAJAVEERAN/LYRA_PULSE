from django.db import migrations, models
from django.db.models import Count


def reject_duplicate_branch_devices(apps, schema_editor):
    Device = apps.get_model("devices", "Device")
    conflicts = list(
        Device.objects.using(schema_editor.connection.alias)
        .values("branch_id")
        .annotate(device_count=Count("pk"))
        .filter(device_count__gt=1)
        .order_by("branch_id")
    )
    if conflicts:
        summary = ", ".join(
            "branch %s (%s devices)" % (row["branch_id"], row["device_count"])
            for row in conflicts
        )
        raise RuntimeError(
            "Cannot enforce one fingerprint device per branch; "
            "reconcile these branches without deleting or reassigning devices: "
            + summary
        )


class Migration(migrations.Migration):
    dependencies = [
        ("devices", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(
            reject_duplicate_branch_devices,
            reverse_code=migrations.RunPython.noop,
        ),
        migrations.AddConstraint(
            model_name="device",
            constraint=models.UniqueConstraint(
                fields=("branch",),
                name="one_fingerprint_device_per_branch",
            ),
        ),
    ]
