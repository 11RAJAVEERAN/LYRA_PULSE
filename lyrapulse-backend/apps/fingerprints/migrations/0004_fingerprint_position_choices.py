from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("fingerprints", "0003_remove_employeefingerprint_unique_active_employee_device_finger"),
    ]

    operations = [
        migrations.AlterField(
            model_name="fingerprintenrollment",
            name="finger",
            field=models.CharField(
                choices=[
                    ("first_finger", "First finger"),
                    ("second_finger", "Second finger"),
                    ("left_thumb", "Left thumb"),
                    ("left_index", "Left index"),
                    ("left_middle", "Left middle"),
                    ("left_ring", "Left ring"),
                    ("left_little", "Left little"),
                    ("right_thumb", "Right thumb"),
                    ("right_index", "Right index"),
                    ("right_middle", "Right middle"),
                    ("right_ring", "Right ring"),
                    ("right_little", "Right little"),
                ],
                max_length=20,
            ),
        ),
        migrations.AlterField(
            model_name="employeefingerprint",
            name="finger",
            field=models.CharField(
                choices=[
                    ("first_finger", "First finger"),
                    ("second_finger", "Second finger"),
                    ("left_thumb", "Left thumb"),
                    ("left_index", "Left index"),
                    ("left_middle", "Left middle"),
                    ("left_ring", "Left ring"),
                    ("left_little", "Left little"),
                    ("right_thumb", "Right thumb"),
                    ("right_index", "Right index"),
                    ("right_middle", "Right middle"),
                    ("right_ring", "Right ring"),
                    ("right_little", "Right little"),
                ],
                max_length=20,
            ),
        ),
    ]
