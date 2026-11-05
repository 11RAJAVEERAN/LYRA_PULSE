import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0002_admin_roles_and_admin_otp"),
        ("organizations", "0001_initial"),
        ("branches", "0002_branch_organization"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="organization",
            field=models.ForeignKey(
                blank=True,
                help_text="Company this user administers. Leave empty for SUPERADMIN (global access).",
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name="users",
                to="organizations.organization",
            ),
        ),
        migrations.AddField(
            model_name="user",
            name="allowed_branches",
            field=models.ManyToManyField(
                blank=True,
                help_text="Branches this user may manage. Must belong to the selected organization.",
                related_name="admin_users",
                to="branches.branch",
            ),
        ),
    ]
