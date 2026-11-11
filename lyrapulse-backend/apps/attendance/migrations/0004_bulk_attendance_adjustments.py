from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("attendance", "0003_one_open_attendance_per_employee_day"),
        ("employees", "0002_employee_details_form"),
    ]

    operations = [
        migrations.CreateModel(
            name="AttendanceAdjustment",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("attendance_date", models.DateField()),
                ("code", models.CharField(choices=[("FD", "Full Day"), ("A", "Absent"), ("HD", "Half Day"), ("WO", "Week Off")], max_length=2)),
                ("reason", models.CharField(blank=True, max_length=500)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("employee", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="attendance_adjustments", to="employees.employee")),
                ("updated_by", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="attendance_adjustments", to=settings.AUTH_USER_MODEL)),
            ],
            options={"ordering": ["attendance_date", "employee__employee_code"]},
        ),
        migrations.AddConstraint(
            model_name="attendanceadjustment",
            constraint=models.UniqueConstraint(fields=("employee", "attendance_date"), name="unique_attendance_adjustment_day"),
        ),
        migrations.AddIndex(
            model_name="attendanceadjustment",
            index=models.Index(fields=["attendance_date", "employee"], name="att_adjustment_date_emp_idx"),
        ),
        migrations.CreateModel(
            name="AttendanceAdjustmentAudit",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("attendance_date", models.DateField()),
                ("previous_code", models.CharField(blank=True, choices=[("FD", "Full Day"), ("A", "Absent"), ("HD", "Half Day"), ("WO", "Week Off")], max_length=2, null=True)),
                ("new_code", models.CharField(choices=[("FD", "Full Day"), ("A", "Absent"), ("HD", "Half Day"), ("WO", "Week Off")], max_length=2)),
                ("reason", models.CharField(blank=True, max_length=500)),
                ("changed_at", models.DateTimeField(auto_now_add=True)),
                ("actor", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="attendance_adjustment_audits", to=settings.AUTH_USER_MODEL)),
                ("adjustment", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="audit_entries", to="attendance.attendanceadjustment")),
                ("employee", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="attendance_adjustment_audits", to="employees.employee")),
            ],
            options={"ordering": ["-changed_at", "-id"]},
        ),
        migrations.AddIndex(
            model_name="attendanceadjustmentaudit",
            index=models.Index(fields=["employee", "attendance_date"], name="att_adjust_audit_emp_day_idx"),
        ),
    ]
