import unittest
from unittest.mock import patch

from config import (
    MAX_TEMPLATE_COUNT,
    R307_DETECTION_MODE,
    R307_UART_FALLBACK_ENABLED,
    R307_TOUCH_CAPTURE_MAX_ATTEMPTS,
)
from drivers.r307 import R307FingerError, R307TimeoutError
from services.fingerprint_service import FingerprintService


class ScriptedTouchSensor:
    def __init__(self, events):
        self.events = list(events)
        self.reset_calls = 0
        self.poll_calls = 0

    def poll_touch_edge(self):
        self.poll_calls += 1
        return self.events.pop(0) if self.events else False

    def reset_baseline(self):
        self.reset_calls += 1


class SearchSensor:
    def __init__(self, result):
        self.result = result
        self.search_arguments = None

    def search(self, **kwargs):
        self.search_arguments = kwargs
        return self.result


class FingerRemovalSensor:
    def __init__(self, present_polls):
        self.present_polls = present_polls
        self.calls = 0

    def get_image(self):
        self.calls += 1
        if self.calls > self.present_polls:
            raise R307FingerError("No finger placed on sensor")
        return True


class PollingSensor:
    def __init__(self, results):
        self.results = list(results)
        self.begin_calls = 0
        self.command_active = False
        self.image_calls = 0

    def get_image(self):
        self.image_calls += 1
        self.command_active = True
        try:
            result = self.results.pop(0)
            if isinstance(result, Exception):
                raise result
            return result
        finally:
            self.command_active = False

    def begin(self):
        self.begin_calls += 1
        return True


class RecoveringSensor:
    def __init__(self, results, begin_results):
        self.results = list(results)
        self.begin_results = list(begin_results)
        self.image_calls = 0
        self.begin_calls = 0

    def get_image(self):
        self.image_calls += 1
        result = self.results.pop(0)
        if isinstance(result, Exception):
            raise result
        return result

    def begin(self):
        self.begin_calls += 1
        result = self.begin_results.pop(0)
        if isinstance(result, Exception):
            raise result
        return result


class FingerprintAttendanceSearchTests(unittest.TestCase):
    def test_uses_r307_match_slot_and_searches_configured_template_range(self):
        sensor = SearchSensor({"fingerprint_id": 847, "score": 932})
        service = FingerprintService(sensor)

        matched_slot = service.search_fingerprint()

        self.assertEqual(matched_slot, 847)
        self.assertEqual(
            sensor.search_arguments,
            {
                "buffer_id": 1,
                "start_page": 0,
                "page_num": MAX_TEMPLATE_COUNT,
            },
        )

    def test_sensor_no_match_is_returned_as_none(self):
        sensor = SearchSensor(None)
        service = FingerprintService(sensor)

        self.assertIsNone(service.search_fingerprint())

    def test_wait_for_removal_does_not_return_while_finger_is_detected(self):
        sensor = FingerRemovalSensor(present_polls=3)
        service = FingerprintService(sensor)

        with patch("services.fingerprint_service.time.sleep") as sleep:
            self.assertTrue(service.wait_for_finger_removed())

        self.assertEqual(sensor.calls, 6)
        self.assertEqual(
            [call.args for call in sleep.call_args_list],
            [(0.2,)] * 3 + [(0.1,)] * 2,
        )

    def test_wait_for_finger_retries_no_finger_then_returns_only_after_image_success(self):
        sensor = PollingSensor([
            R307FingerError("No finger"),
            R307FingerError("No finger"),
            True,
        ])
        service = FingerprintService(sensor, ScriptedTouchSensor([True]))

        with patch("services.fingerprint_service.time.sleep"):
            self.assertTrue(service.wait_for_finger())

        self.assertEqual(sensor.begin_calls, 0)
        self.assertEqual(sensor.results, [])

    def test_wait_for_finger_recovers_after_temporary_uart_timeouts(self):
        sensor = PollingSensor([
            R307TimeoutError("zero bytes"),
            R307TimeoutError("zero bytes"),
            R307TimeoutError("zero bytes"),
            True,
        ])
        service = FingerprintService(sensor, ScriptedTouchSensor([True]))

        with patch("services.fingerprint_service.time.sleep"):
            self.assertTrue(service.wait_for_finger())

        self.assertEqual(sensor.begin_calls, 1)
        self.assertEqual(sensor.results, [])

    def test_enrollment_poll_callback_runs_between_uart_commands(self):
        sensor = PollingSensor([True])
        service = FingerprintService(
            sensor,
            ScriptedTouchSensor([False] * 101 + [True]),
        )
        callback_command_active = []

        def poll_enrollment():
            callback_command_active.append(sensor.command_active)
            return None

        with patch("services.fingerprint_service.time.sleep"):
            self.assertTrue(
                service.wait_for_finger(
                    on_wait=poll_enrollment,
                    poll_interval_seconds=1,
                )
            )

        self.assertEqual(callback_command_active, [False])
        self.assertEqual(sensor.image_calls, 1)

    def test_wait_for_touch_does_not_send_get_image_until_a_debounced_edge(self):
        sensor = PollingSensor([True])
        service = FingerprintService(
            sensor,
            ScriptedTouchSensor([False, False, True]),
        )

        with patch("services.fingerprint_service.time.sleep"):
            self.assertTrue(service.wait_for_finger())

        self.assertEqual(sensor.image_calls, 1)

    def test_gpio_only_mode_never_polls_uart_before_touch_edge(self):
        sensor = PollingSensor([True])
        touch = ScriptedTouchSensor([False, False, False, True])
        service = FingerprintService(sensor, touch)

        with patch("services.fingerprint_service.time.sleep"):
            self.assertTrue(
                service.wait_for_finger(
                    detection_mode="gpio_only",
                    uart_fallback_enabled=True,
                )
            )

        self.assertEqual(sensor.image_calls, 1)
        self.assertEqual(touch.poll_calls, 4)

    def test_hybrid_fallback_is_low_frequency_and_getimage_confirms_capture(self):
        sensor = PollingSensor([R307FingerError("No finger"), True])
        touch = ScriptedTouchSensor([False] * 250)
        service = FingerprintService(sensor, touch)
        sleep_count = [0]
        sleep_before_each_command = []

        def counted_sleep(_seconds):
            sleep_count[0] += 1

        original_get_image = sensor.get_image

        def counted_get_image():
            sleep_before_each_command.append(sleep_count[0])
            return original_get_image()

        sensor.get_image = counted_get_image
        with (
            patch("services.fingerprint_service.R307_UART_FALLBACK_INTERVAL_SECONDS", 0.01),
            patch("services.fingerprint_service.time.sleep", side_effect=counted_sleep),
        ):
            self.assertTrue(
                service.wait_for_finger(
                    detection_mode="hybrid",
                    uart_fallback_enabled=True,
                )
            )

        self.assertEqual(sensor.image_calls, 2)
        self.assertGreaterEqual(
            sleep_before_each_command[1] - sleep_before_each_command[0],
            200,
        )
        self.assertGreaterEqual(touch.poll_calls, 200)

    def test_default_detection_uses_configured_hybrid_fallback(self):
        self.assertEqual(R307_DETECTION_MODE, "hybrid")
        self.assertTrue(R307_UART_FALLBACK_ENABLED)
        sensor = PollingSensor([True])
        service = FingerprintService(sensor, ScriptedTouchSensor([]))

        with (
            patch("services.fingerprint_service.R307_UART_FALLBACK_INTERVAL_SECONDS", 0.01),
            patch("services.fingerprint_service.R307_TOUCH_SAMPLE_INTERVAL_SECONDS", 1),
            patch("services.fingerprint_service.time.sleep"),
        ):
            self.assertTrue(service.wait_for_finger())

        self.assertEqual(sensor.image_calls, 1)

    def test_hybrid_fallback_disabled_waits_for_gpio_without_uart_probes(self):
        sensor = PollingSensor([True])
        touch = ScriptedTouchSensor([False] * 6 + [True])
        service = FingerprintService(sensor, touch)

        with (
            patch("services.fingerprint_service.R307_UART_FALLBACK_INTERVAL_SECONDS", 0.01),
            patch("services.fingerprint_service.time.sleep"),
        ):
            self.assertTrue(
                service.wait_for_finger(
                    detection_mode="hybrid",
                    uart_fallback_enabled=False,
                )
            )

        self.assertEqual(sensor.image_calls, 1)
        self.assertEqual(touch.poll_calls, 7)

    def test_uart_fallback_timeout_is_not_treated_as_a_mismatch(self):
        sensor = PollingSensor([R307TimeoutError("zero bytes"), True])
        touch = ScriptedTouchSensor([])
        service = FingerprintService(sensor, touch)

        with (
            patch("services.fingerprint_service.R307_UART_FALLBACK_INTERVAL_SECONDS", 0.01),
            patch("services.fingerprint_service.time.sleep"),
        ):
            self.assertTrue(
                service.wait_for_finger(
                    detection_mode="uart_fallback",
                    uart_fallback_enabled=True,
                )
            )

        self.assertEqual(sensor.image_calls, 2)
        self.assertEqual(sensor.begin_calls, 0)

    def test_capture_timeout_waits_for_removal_before_rearming_touch(self):
        sensor = PollingSensor(
            [R307FingerError("No finger")] * (R307_TOUCH_CAPTURE_MAX_ATTEMPTS + 3)
            + [True]
        )
        touch = ScriptedTouchSensor([True, True])
        service = FingerprintService(sensor, touch)

        with patch("services.fingerprint_service.time.sleep"):
            self.assertTrue(service.wait_for_finger())

        self.assertEqual(
            sensor.image_calls,
            R307_TOUCH_CAPTURE_MAX_ATTEMPTS + 4,
        )
        self.assertEqual(touch.reset_calls, 1)

    def test_wait_for_removal_retries_temporary_timeout_until_no_finger(self):
        sensor = PollingSensor([
            True,
            R307TimeoutError("zero bytes"),
            True,
            R307FingerError("No finger"),
            R307FingerError("No finger"),
            R307FingerError("No finger"),
        ])
        service = FingerprintService(sensor)

        with patch("services.fingerprint_service.time.sleep"):
            self.assertTrue(service.wait_for_finger_removed())

        self.assertEqual(sensor.results, [])

    def test_removal_timeout_uses_cooldown_before_rearming(self):
        sensor = PollingSensor([])
        touch = ScriptedTouchSensor([True])
        service = FingerprintService(sensor, touch)
        service._awaiting_removal = True

        with (
            patch("services.fingerprint_service.R307_FINGER_REMOVAL_TIMEOUT_SECONDS", 1),
            patch(
                "services.fingerprint_service._ticks_ms",
                side_effect=[0, 1000, 2000, 3000],
            ),
            patch(
                "services.fingerprint_service._ticks_add",
                side_effect=lambda ticks, delta: ticks + delta,
            ),
        ):
            self.assertFalse(service.wait_for_finger_removed())
            self.assertEqual(service._removal_rearm_deadline, 31000)
            self.assertFalse(service._awaiting_removal)

        self.assertIsNotNone(service._removal_rearm_deadline)
        self.assertEqual(sensor.image_calls, 0)

    def test_removal_requires_three_consecutive_no_finger_responses(self):
        sensor = PollingSensor([
            True,
            R307FingerError("transient no image"),
            True,
            R307FingerError("no finger 1"),
            R307FingerError("no finger 2"),
            R307FingerError("no finger 3"),
        ])
        service = FingerprintService(sensor)

        with patch("services.fingerprint_service.time.sleep") as sleep:
            self.assertTrue(service.wait_for_finger_removed())

        self.assertEqual(sensor.results, [])
        self.assertEqual(
            [call.args for call in sleep.call_args_list],
            [(0.2,), (0.1,), (0.2,), (0.1,), (0.1,)],
        )

    def test_removal_poll_backs_off_and_reinitializes_without_extra_image_commands(self):
        sensor = RecoveringSensor(
            [
                True,
                R307TimeoutError("zero bytes"),
                R307TimeoutError("zero bytes"),
                R307TimeoutError("zero bytes"),
                R307FingerError("No finger"),
                R307FingerError("No finger"),
                R307FingerError("No finger"),
            ],
            [R307TimeoutError("verify timeout"), True],
        )
        service = FingerprintService(sensor)

        with (
            patch("services.fingerprint_service.time.sleep") as sleep,
            patch("services.fingerprint_service.log") as log,
        ):
            self.assertTrue(service.wait_for_finger_removed())

        self.assertEqual(sensor.image_calls, 7)
        self.assertEqual(sensor.begin_calls, 2)
        self.assertIn((2,), [call.args for call in sleep.call_args_list])
        self.assertIn((4,), [call.args for call in sleep.call_args_list])
        logged_phases = [
            call.args[1]
            for call in log.call_args_list
            if len(call.args) > 1 and isinstance(call.args[1], str)
        ]
        self.assertTrue(
            any("WAITING_FOR_REMOVAL" in message for message in logged_phases)
        )


if __name__ == "__main__":
    unittest.main()
