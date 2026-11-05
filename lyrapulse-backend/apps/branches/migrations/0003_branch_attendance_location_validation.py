import django.core.validators
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("branches", "0002_branch_organization"),
    ]

    # Metadata only (validators / labels / help text): no column is added, changed or rewritten,
    # so existing branches and their stored values are untouched.
    operations = [
        migrations.AlterField(
            model_name="branch",
            name="latitude",
            field=models.DecimalField(
                blank=True,
                decimal_places=6,
                help_text="Latitude of the branch location used for employee attendance verification.",
                max_digits=9,
                null=True,
                validators=[django.core.validators.MinValueValidator(-90), django.core.validators.MaxValueValidator(90)],
                verbose_name="attendance latitude",
            ),
        ),
        migrations.AlterField(
            model_name="branch",
            name="longitude",
            field=models.DecimalField(
                blank=True,
                decimal_places=6,
                help_text="Longitude of the branch location used for employee attendance verification.",
                max_digits=9,
                null=True,
                validators=[django.core.validators.MinValueValidator(-180), django.core.validators.MaxValueValidator(180)],
                verbose_name="attendance longitude",
            ),
        ),
        migrations.AlterField(
            model_name="branch",
            name="attendance_radius_meters",
            field=models.PositiveIntegerField(
                default=3,
                help_text="Employees must be within this distance from the branch to check in or check out.",
                validators=[django.core.validators.MinValueValidator(1)],
                verbose_name="allowed radius (meters)",
            ),
        ),
    ]
