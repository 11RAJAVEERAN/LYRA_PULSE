from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("accounts", "0001_initial")]

    operations = [
        migrations.AlterField(
            model_name="user",
            name="role",
            field=models.CharField(
                choices=[
                    ("SUPERADMIN", "Superadmin"),
                    ("ADMIN", "Admin"),
                    ("HR", "HR"),
                    ("MANAGER", "Manager"),
                    ("EMPLOYEE", "Employee"),
                ],
                default="EMPLOYEE",
                max_length=20,
            ),
        ),
        migrations.AlterField(
            model_name="otpverification",
            name="purpose",
            field=models.CharField(
                choices=[
                    ("LOGIN", "Login"),
                    ("ADMIN_LOGIN", "Admin login"),
                    ("PHONE_VERIFICATION", "Phone verification"),
                ],
                default="LOGIN",
                max_length=30,
            ),
        ),
    ]