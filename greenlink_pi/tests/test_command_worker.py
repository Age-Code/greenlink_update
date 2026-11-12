import importlib
import math
import sys
import unittest
from pathlib import Path
from types import ModuleType
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


api_client = ModuleType("api_client")
api_client.get_pending_commands = Mock()
api_client.mark_command_processing = Mock()
api_client.complete_command = Mock()

config = ModuleType("config")
config.COMMAND_POLL_INTERVAL_SECONDS = 3

relay_control = ModuleType("relay_control")
relay_control.pump_for_gpio = Mock()
relay_control.led_on = Mock()
relay_control.led_off = Mock()
relay_control.all_off = Mock()
relay_control.pump_off = Mock()

sensor_service = ModuleType("sensor_service")
sensor_service.read_all_sensors = Mock()

sensor_uploader = ModuleType("sensor_uploader")
sensor_uploader.upload_sensor_data_safe = Mock()

with patch.dict(
    sys.modules,
    {
        "api_client": api_client,
        "config": config,
        "relay_control": relay_control,
        "sensor_service": sensor_service,
        "sensor_uploader": sensor_uploader,
    },
):
    command_worker = importlib.import_module("command_worker")


class CommandWorkerWaterDurationTest(unittest.TestCase):

    def setUp(self):
        api_client.mark_command_processing.reset_mock()
        api_client.complete_command.reset_mock()
        relay_control.pump_for_gpio.reset_mock()
        relay_control.all_off.reset_mock()
        relay_control.pump_off.reset_mock()
        api_client.complete_command.side_effect = None

    def test_invalid_duration_reports_failed_without_running_pump(self):
        invalid_values = [
            None,
            "1",
            True,
            0,
            -1,
            30.0001,
            math.inf,
            -math.inf,
            math.nan,
        ]

        for value in invalid_values:
            with self.subTest(value=value):
                self.setUp()

                command_worker.handle_water_command({
                    "commandId": 42,
                    "durationSeconds": value,
                    "pumpChannel": {
                        "gpioPin": 22,
                        "relayChannel": 1,
                    },
                })

                api_client.mark_command_processing.assert_called_once_with(42)
                relay_control.pump_for_gpio.assert_not_called()
                api_client.complete_command.assert_called_once()
                relay_control.pump_off.assert_called_once()
                relay_control.all_off.assert_not_called()

                failure_report = api_client.complete_command.call_args.kwargs
                self.assertEqual(failure_report["command_id"], 42)
                self.assertFalse(failure_report["success"])
                self.assertIn("급수 실패", failure_report["result_message"])

    def test_missing_duration_runs_pump_for_thirty_seconds_and_reports_success(self):
        command_worker.handle_water_command({
            "commandId": 43,
            "pumpChannel": {
                "gpioPin": 22,
                "relayChannel": 1,
            },
        })

        api_client.mark_command_processing.assert_called_once_with(43)
        relay_control.pump_for_gpio.assert_called_once_with(
            gpio_pin=22,
            seconds=30.0,
        )
        api_client.complete_command.assert_called_once()
        relay_control.pump_off.assert_not_called()

        success_report = api_client.complete_command.call_args.kwargs
        self.assertEqual(success_report["command_id"], 43)
        self.assertTrue(success_report["success"])
        self.assertIn("급수 완료", success_report["result_message"])

    def test_report_failure_after_pumping_is_retried_as_success_not_failed(self):
        api_client.complete_command.side_effect = [ConnectionError("network down"), None]

        command_worker.handle_water_command({
            "commandId": 44,
            "durationSeconds": 1,
            "pumpChannel": {
                "gpioPin": 22,
                "relayChannel": 1,
            },
        })

        relay_control.pump_for_gpio.assert_called_once()
        self.assertEqual(api_client.complete_command.call_count, 2)
        for call in api_client.complete_command.call_args_list:
            self.assertTrue(call.kwargs["success"])
        relay_control.all_off.assert_not_called()

if __name__ == "__main__":
    unittest.main()
