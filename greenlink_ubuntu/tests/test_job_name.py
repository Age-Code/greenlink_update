import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from job_name import MAX_JOB_NAME_LENGTH, validate_job_name


class ValidateJobNameTest(unittest.TestCase):
    def test_accepts_supported_names(self):
        for name in ("basil", "user_plant_6-image_10", "바질_1"):
            with self.subTest(name=name):
                self.assertEqual(name, validate_job_name(name))

    def test_rejects_empty_or_path_like_names(self):
        invalid_names = (
            "",
            ".",
            "..",
            "../outside",
            "../../outside",
            "/tmp/outside",
            r"..\outside",
            "plant name",
            "plant\nname",
        )

        for name in invalid_names:
            with self.subTest(name=name):
                with self.assertRaises(ValueError):
                    validate_job_name(name)

    def test_rejects_overly_long_name(self):
        with self.assertRaises(ValueError):
            validate_job_name("a" * (MAX_JOB_NAME_LENGTH + 1))


if __name__ == "__main__":
    unittest.main()
