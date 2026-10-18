import apps.attendance.models
import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ("branches", "0003_branch_attendance_location_validation"),
        ("employees", "0002_employee_details_form"),
    ]

    operations = [
        migrations.CreateModel(
            name="Attendance",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("attendance_date", models.DateField(help_text="Calendar date in the application time zone.")),
                ("check_in_at", models.DateTimeField()),
                ("check_in_latitude", models.DecimalField(decimal_places=7, max_digits=10)),
                ("check_in_longitude", models.DecimalField(decimal_places=7, max_digits=10)),
                ("check_in_accuracy", models.FloatField(help_text="GPS accuracy reported by the device, in meters.")),
                ("check_in_distance_meters", models.FloatField(help_text="Distance from the branch attendance location, in meters.")),
                ("check_in_location_verified", models.BooleanField()),
                ("check_in_photo", models.ImageField(upload_to=apps.attendance.models.check_in_photo_path)),
                ("check_out_at", models.DateTimeField(blank=True, null=True)),
                ("check_out_latitude", models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True)),
                ("check_out_longitude", models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True)),
                ("check_out_accuracy", models.FloatField(blank=True, help_text="GPS accuracy reported by the device, in meters.", null=True)),
                ("check_out_distance_meters", models.FloatField(blank=True, help_text="Distance from the branch attendance location, in meters.", null=True)),
                ("check_out_location_verified", models.BooleanField(blank=True, null=True)),
                ("check_out_photo", models.ImageField(blank=True, upload_to=apps.attendance.models.check_out_photo_path)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "branch",
                    models.ForeignKey(
                        help_text="Branch the employee was verified against at check-in (decided by the server).",
                        on_delete=django.db.models.deletion.PROTECT,
                        related_name="attendance_records",
                        to="branches.branch",
                    ),
                ),
                (
                    "employee",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.PROTECT,
                        related_name="attendance_records",
                        to="employees.employee",
                    ),
                ),
            ],
            options={
                "ordering": ["-attendance_date", "-check_in_at"],
                "indexes": [models.Index(fields=["branch", "attendance_date"], name="attendance_branch_date_idx")],
                "constraints": [
                    models.UniqueConstraint(fields=("employee", "attendance_date"), name="unique_employee_attendance_per_day"),
                ],
            },
        ),
    ]
