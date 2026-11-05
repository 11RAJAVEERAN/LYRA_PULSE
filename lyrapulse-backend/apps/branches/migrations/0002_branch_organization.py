import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("organizations", "0001_initial"),
        ("branches", "0001_initial"),
    ]

    operations = [
        # Nullable: existing branches are intentionally left unassigned (no fake company is invented).
        migrations.AddField(
            model_name="branch",
            name="organization",
            field=models.ForeignKey(
                blank=True,
                help_text="Company that owns this branch.",
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name="branches",
                to="organizations.organization",
            ),
        ),
    ]
