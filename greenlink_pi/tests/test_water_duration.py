import math
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from water_duration import (
    DEFAULT_WATER_DURATION_SECONDS,
    MAX_WATER_DURATION_SECONDS,
    resolve_water_duration,
)


class WaterDurationTest(unittest.TestCase):

    def test_missing_duration_uses_one_second_default(self):
        self.assertEqual(DEFAULT_WATER_DURATION_SECONDS, 1.0)
        self.assertEqual(resolve_water_duration({}), 1.0)

    def test_positive_duration_up_to_max_is_allowed(self):
        self.assertEqual(MAX_WATER_DURATION_SECONDS, 1.0)
        self.assertEqual(resolve_water_duration({"durationSeconds": 0.5}), 0.5)
        self.assertEqual(resolve_water_duration({"durationSeconds": 1}), 1.0)

    def test_invalid_duration_is_rejected(self):
        invalid_values = [
            None,
            "1",
            True,
            False,
            0,
            -1,
            1.0001,
            math.inf,
            -math.inf,
            math.nan,
        ]

        for value in invalid_values:
            with self.subTest(value=value):
                with self.assertRaises(ValueError):
                    resolve_water_duration({"durationSeconds": value})


if __name__ == "__main__":
    unittest.main()
