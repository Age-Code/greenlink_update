import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from dht_reader import find_iio_dht, read_iio_dht


class DhtReaderTest(unittest.TestCase):

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.devices = Path(self._tmp.name)

    def tearDown(self):
        self._tmp.cleanup()

    def _device(self, index, name):
        device = self.devices / f"iio:device{index}"
        device.mkdir()
        (device / "name").write_text(name + "\n")
        return device

    def test_finds_dht_device_among_other_iio_devices(self):
        self._device(0, "bh1750")
        dht = self._device(1, "dht11")

        self.assertEqual(find_iio_dht(self.devices), dht)

    def test_returns_none_without_overlay(self):
        self._device(0, "bh1750")

        self.assertIsNone(find_iio_dht(self.devices))
        self.assertIsNone(find_iio_dht(self.devices / "missing"))

    def test_reads_milli_units(self):
        dht = self._device(0, "dht11")
        (dht / "in_temp_input").write_text("23400\n")
        (dht / "in_humidityrelative_input").write_text("56700\n")

        self.assertEqual(read_iio_dht(dht), (23.4, 56.7))


if __name__ == "__main__":
    unittest.main()
