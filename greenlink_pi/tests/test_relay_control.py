import importlib
import sys
import unittest
from pathlib import Path
from types import ModuleType
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


gpiozero = ModuleType("gpiozero")
gpiozero.OutputDevice = MagicMock(side_effect=lambda *args, **kwargs: MagicMock())

config = ModuleType("config")
config.RELAY_LED_GPIO = 27
config.RELAY_PUMP_GPIO = 22
config.RELAY_ACTIVE_HIGH = False

with patch.dict(sys.modules, {"gpiozero": gpiozero, "config": config}):
    relay_control = importlib.import_module("relay_control")


class RelayControlTest(unittest.TestCase):

    def setUp(self):
        relay_control.pump_relay.reset_mock()

    def test_pump_turns_off_after_duration(self):
        with patch.object(relay_control, "sleep") as sleep:
            relay_control.pump_for_gpio(22, 0.5)

        sleep.assert_called_once_with(0.5)
        relay_control.pump_relay.on.assert_called_once()
        relay_control.pump_relay.off.assert_called_once()

    def test_pump_turns_off_even_if_interrupted(self):
        with patch.object(relay_control, "sleep", side_effect=KeyboardInterrupt):
            with self.assertRaises(KeyboardInterrupt):
                relay_control.pump_for_gpio(22, 0.5)

        relay_control.pump_relay.off.assert_called_once()

    def test_unregistered_gpio_is_rejected_without_switching_pump(self):
        with self.assertRaises(ValueError):
            relay_control.pump_for_gpio(23, 0.5)

        relay_control.pump_relay.on.assert_not_called()


if __name__ == "__main__":
    unittest.main()
