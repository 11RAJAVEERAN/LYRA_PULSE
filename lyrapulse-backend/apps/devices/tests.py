from datetime import timedelta

from django.contrib.auth.models import Permission
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.branches.models import Branch
from apps.organizations.models import Organization

from .models import Device


class DeviceManagementSecurityTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.organization = Organization.objects.create(
            name="Device Test Company",
            code="DEVICE-TEST-COMPANY",
        )
        self.branch = Branch.objects.create(
            organization=self.organization,
            name="Device Test Branch",
            code="DEVICE-TEST-BRANCH",
        )
        self.device = Device(
            device_id="DEVICE-TEST-001",
            branch=self.branch,
            name="Test Device",
        )
        self.device.set_token("test-only-original-device-token")
        self.device.save()
        self.admin = User.objects.create_user(
            "9000000081",
            role=User.Role.SUPERADMIN,
            is_superuser=True,
        )
        self.employee = User.objects.create_user(
            "9000000082",
            role=User.Role.EMPLOYEE,
        )

    def rotate(self):
        self.client.force_authenticate(self.admin)
        return self.client.post(
            f"/api/v1/devices/{self.device.device_id}/rotate-token/",
            {},
            format="json",
        )

    def heartbeat(self, token):
        self.client.force_authenticate(user=None)
        self.client.credentials(HTTP_AUTHORIZATION=f"Device {token}")
        return self.client.post(
            f"/api/v1/devices/{self.device.device_id}/heartbeat/",
            {},
            format="json",
        )

    def test_rotation_invalidates_old_token_and_new_token_authenticates(self):
        response = self.rotate()

        self.assertEqual(response.status_code, 200, response.data)
        token = response.data["data"]["rotated_token"]
        self.assertTrue(bool(token))
        self.device.refresh_from_db()
        self.assertFalse(self.device.verify_token("test-only-original-device-token"))
        self.assertTrue(self.device.verify_token(token))
        self.assertEqual(self.heartbeat("test-only-original-device-token").status_code, 401)
        self.assertEqual(self.heartbeat(token).status_code, 200)

    def test_repeated_rotation_invalidates_the_previously_issued_token(self):
        first = self.rotate()
        self.assertEqual(first.status_code, 200, first.data)
        first_token = first.data["data"]["rotated_token"]

        second = self.rotate()
        self.assertEqual(second.status_code, 200, second.data)
        second_token = second.data["data"]["rotated_token"]

        self.assertFalse(first_token == second_token)
        self.device.refresh_from_db()
        self.assertFalse(self.device.verify_token(first_token))
        self.assertTrue(self.device.verify_token(second_token))
        self.assertEqual(self.heartbeat(first_token).status_code, 401)
        self.assertEqual(self.heartbeat(second_token).status_code, 200)

    def test_unauthorized_user_cannot_rotate_token(self):
        original_hash = self.device.token_hash
        self.client.force_authenticate(self.employee)

        response = self.client.post(
            f"/api/v1/devices/{self.device.device_id}/rotate-token/",
            {},
            format="json",
        )

        self.assertEqual(response.status_code, 403)
        self.device.refresh_from_db()
        self.assertEqual(self.device.token_hash, original_hash)
        self.assertNotIn("rotated_token", response.data.get("data", {}))

    def test_branch_admin_cannot_rotate_a_device_outside_assigned_branch(self):
        other_branch = Branch.objects.create(
            organization=self.organization,
            name="Other Device Branch",
            code="OTHER-DEVICE-BRANCH",
        )
        other_device = Device(device_id="DEVICE-TEST-002", branch=other_branch)
        other_device.set_token("test-only-other-device-token")
        other_device.save()
        branch_admin = User.objects.create_user(
            "9000000083",
            role=User.Role.ADMIN,
            organization=self.organization,
        )
        view_permission = Permission.objects.get(
            content_type__app_label="employees",
            codename="view_employee",
        )
        branch_admin.user_permissions.add(view_permission)
        branch_admin.allowed_branches.add(self.branch)
        original_hash = other_device.token_hash
        self.client.force_authenticate(branch_admin)

        response = self.client.post(
            f"/api/v1/devices/{other_device.device_id}/rotate-token/",
            {},
            format="json",
        )

        self.assertEqual(response.status_code, 404)
        other_device.refresh_from_db()
        self.assertEqual(other_device.token_hash, original_hash)

    def test_list_and_update_responses_do_not_expose_credentials(self):
        self.client.force_authenticate(self.admin)

        listed = self.client.get("/api/v1/devices/")
        updated = self.client.patch(
            "/api/v1/devices/",
            {"device_id": self.device.device_id, "name": "Renamed Device"},
            format="json",
        )

        for response in (listed, updated):
            self.assertEqual(response.status_code, 200, response.data)
            content = str(response.data)
            self.assertNotIn("token_hash", content)
            self.assertNotIn("rotated_token", content)
            self.assertNotIn("provisioning_token", content)

    def test_inactive_device_rejects_heartbeat_authentication(self):
        self.device.is_active = False
        self.device.save(update_fields=("is_active",))

        response = self.heartbeat("test-only-original-device-token")

        self.assertEqual(response.status_code, 401)
        self.device.refresh_from_db()
        self.assertIsNone(self.device.last_seen)

    def test_inactive_branch_or_organization_rejects_heartbeat(self):
        for owner, field in (
            (self.branch, "is_active"),
            (self.organization, "is_active"),
        ):
            with self.subTest(inactive=owner.__class__.__name__):
                owner.is_active = False
                owner.save(update_fields=(field,))
                response = self.heartbeat("test-only-original-device-token")
                self.assertEqual(response.status_code, 401)
                self.device.refresh_from_db()
                self.assertIsNone(self.device.last_seen)
                owner.is_active = True
                owner.save(update_fields=(field,))


    def test_valid_heartbeat_updates_last_seen_and_reports_online(self):
        before = timezone.now()

        response = self.heartbeat("test-only-original-device-token")

        self.assertEqual(response.status_code, 200, response.data)
        self.device.refresh_from_db()
        self.assertIsNotNone(self.device.last_seen)
        self.assertGreaterEqual(self.device.last_seen, before)
        self.assertEqual(response.data["data"]["status"], "Online")
        self.assertEqual(response.data["data"]["last_seen"], self.device.last_seen)

    def test_invalid_token_does_not_update_last_seen(self):
        response = self.heartbeat("test-only-invalid-device-token")

        self.assertEqual(response.status_code, 401)
        self.device.refresh_from_db()
        self.assertIsNone(self.device.last_seen)

    @override_settings(DEVICE_ONLINE_THRESHOLD_SECONDS=60)
    def test_device_status_is_derived_from_configured_threshold(self):
        old = timezone.now() - timedelta(seconds=61)
        self.device.last_seen = old
        self.device.save(update_fields=("last_seen",))
        self.client.force_authenticate(self.admin)

        response = self.client.get("/api/v1/devices/")

        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(response.data["data"][0]["status"], "Offline")
        self.assertEqual(response.data["data"][0]["branch"], self.branch.name)
