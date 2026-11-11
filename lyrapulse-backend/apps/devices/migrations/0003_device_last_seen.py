from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("devices", "0002_one_fingerprint_device_per_branch"),
    ]

    operations = [
        migrations.AddField(
            model_name="device",
            name="last_seen",
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
