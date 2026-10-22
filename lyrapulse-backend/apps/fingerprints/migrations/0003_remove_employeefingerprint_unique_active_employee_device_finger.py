from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("fingerprints", "0002_remove_fingerprintenrollment_one_active_device_fingerprint_enrollment_and_more"),
    ]

    operations = [
        migrations.RemoveConstraint(
            model_name="employeefingerprint",
            name="unique_active_employee_device_finger",
        ),
    ]
