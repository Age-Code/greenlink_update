import io
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest.mock import Mock, patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

_created_s3_client = Mock(name="created_s3_client")
_boto3_client = Mock(return_value=_created_s3_client)

_fake_boto3 = types.ModuleType("boto3")
_fake_boto3.client = _boto3_client

_fake_dotenv = types.ModuleType("dotenv")
_fake_dotenv.load_dotenv = Mock()

with patch.dict(
    sys.modules,
    {
        "boto3": _fake_boto3,
        "dotenv": _fake_dotenv,
    },
):
    import s3_client


class DownloadSourceImageFromS3Test(unittest.TestCase):
    BUCKET = "greenlink-test"
    REGION = "ap-northeast-2"
    BASE_URL = (
        "https://greenlink-test.s3.ap-northeast-2.amazonaws.com/"
        "greenlink/userplant/"
    )

    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.output_path = Path(self.temp_dir.name) / "source.jpg"
        self.client = Mock()

        self.bucket_patch = patch.object(s3_client, "S3_BUCKET", self.BUCKET)
        self.region_patch = patch.object(s3_client, "AWS_REGION", self.REGION)
        self.client_patch = patch.object(s3_client, "s3", self.client)

        self.bucket_patch.start()
        self.region_patch.start()
        self.client_patch.start()

    def tearDown(self):
        self.client_patch.stop()
        self.region_patch.stop()
        self.bucket_patch.stop()
        self.temp_dir.cleanup()

    def make_response(
        self,
        data=b"image-bytes",
        content_length=None,
        content_type="image/jpeg",
    ):
        body = io.BytesIO(data)
        response = {
            "Body": body,
            "ContentLength": len(data) if content_length is None else content_length,
            "ContentType": content_type,
        }
        return response, body

    def test_boto3_client_uses_default_credential_provider_chain(self):
        _boto3_client.assert_called_once_with(
            "s3",
            region_name=s3_client.AWS_REGION,
        )

    def test_downloads_allowed_image_types_from_configured_virtual_host(self):
        cases = (
            ("source.jpg", "image/jpeg"),
            ("source.jpeg", "image/jpeg"),
            ("source.png", "image/png"),
            ("source.webp", "image/webp"),
        )

        for index, (filename, content_type) in enumerate(cases):
            with self.subTest(filename=filename):
                data = f"image-{index}".encode()
                response, body = self.make_response(
                    data=data,
                    content_type=content_type,
                )
                self.client.get_object.return_value = response
                output_path = Path(self.temp_dir.name) / filename

                result = s3_client.download_source_image_from_s3(
                    self.BASE_URL + filename,
                    output_path,
                )

                self.assertEqual(output_path, result)
                self.assertEqual(data, output_path.read_bytes())
                self.assertTrue(body.closed)
                self.client.get_object.assert_called_once_with(
                    Bucket=self.BUCKET,
                    Key=f"greenlink/userplant/{filename}",
                )
                self.client.reset_mock()

    def test_accepts_explicit_https_port_and_decodes_key(self):
        response, _ = self.make_response()
        self.client.get_object.return_value = response
        url = (
            "https://greenlink-test.s3.ap-northeast-2.amazonaws.com:443/"
            "greenlink/userplant/user%2Dplant%2D1.jpg"
        )

        s3_client.download_source_image_from_s3(url, self.output_path)

        self.client.get_object.assert_called_once_with(
            Bucket=self.BUCKET,
            Key="greenlink/userplant/user-plant-1.jpg",
        )

    def test_rejects_untrusted_or_ambiguous_urls_before_s3_call(self):
        invalid_urls = (
            # scheme, host, credentials, port
            self.BASE_URL.replace("https://", "http://") + "source.jpg",
            "https://attacker.example/greenlink/userplant/source.jpg",
            "https://greenlink-test.s3.ap-northeast-2.amazonaws.com.attacker.example/"
            "greenlink/userplant/source.jpg",
            "https://user@greenlink-test.s3.ap-northeast-2.amazonaws.com/"
            "greenlink/userplant/source.jpg",
            "https://greenlink-test.s3.ap-northeast-2.amazonaws.com:444/"
            "greenlink/userplant/source.jpg",
            "https://greenlink-test.s3.ap-northeast-2.amazonaws.com:/"
            "greenlink/userplant/source.jpg",
            "https://greenlink-test.s3.ap-northeast-2.amazonaws.com:0443/"
            "greenlink/userplant/source.jpg",
            "https://greenlink-test.s3.ap-northeast-2.amazonaws.com:invalid/"
            "greenlink/userplant/source.jpg",
            # query, fragment, path-style URL
            self.BASE_URL + "source.jpg?versionId=1",
            self.BASE_URL + "source.jpg?",
            self.BASE_URL + "source.jpg#fragment",
            self.BASE_URL + "source.jpg#",
            "https://s3.ap-northeast-2.amazonaws.com/greenlink-test/"
            "greenlink/userplant/source.jpg",
            # prefix and segment restrictions
            "https://greenlink-test.s3.ap-northeast-2.amazonaws.com/"
            "greenlink/ai/userplant/source.jpg",
            self.BASE_URL,
            self.BASE_URL + "nested/source.jpg",
            self.BASE_URL + "nested%2Fsource.jpg",
            self.BASE_URL + r"nested\source.jpg",
            self.BASE_URL + "nested%5Csource.jpg",
            self.BASE_URL + "%2E%2E%2Fsource.jpg",
            self.BASE_URL + "source%20name.jpg",
            # extension restrictions
            self.BASE_URL + "source",
            self.BASE_URL + "source.gif",
        )

        for url in invalid_urls:
            with self.subTest(url=url):
                with self.assertRaises(ValueError):
                    s3_client.download_source_image_from_s3(
                        url,
                        self.output_path,
                    )

                self.client.get_object.assert_not_called()
                self.client.reset_mock()

    def test_rejects_missing_or_non_image_content_type(self):
        for content_type in (None, "", "application/octet-stream", "text/html"):
            with self.subTest(content_type=content_type):
                response, body = self.make_response(content_type=content_type)
                self.client.get_object.return_value = response

                with self.assertRaises(ValueError):
                    s3_client.download_source_image_from_s3(
                        self.BASE_URL + "source.jpg",
                        self.output_path,
                    )

                self.assertTrue(body.closed)
                self.assertFalse(self.output_path.exists())

    def test_rejects_content_type_that_does_not_match_extension(self):
        response, body = self.make_response(content_type="image/png")
        self.client.get_object.return_value = response

        with self.assertRaises(ValueError):
            s3_client.download_source_image_from_s3(
                self.BASE_URL + "source.jpg",
                self.output_path,
            )

        self.assertTrue(body.closed)
        self.assertFalse(self.output_path.exists())

    def test_rejects_response_without_stream_body(self):
        self.client.get_object.return_value = {
            "ContentLength": 10,
            "ContentType": "image/jpeg",
        }

        with self.assertRaises(ValueError):
            s3_client.download_source_image_from_s3(
                self.BASE_URL + "source.jpg",
                self.output_path,
            )

        self.assertFalse(self.output_path.exists())

    def test_rejects_missing_empty_or_oversized_content_length(self):
        cases = (
            (None, b"image"),
            (0, b""),
            (s3_client.MAX_SOURCE_IMAGE_BYTES + 1, b"image"),
        )

        for content_length, data in cases:
            with self.subTest(content_length=content_length):
                response, body = self.make_response(
                    data=data,
                    content_length=content_length,
                )
                if content_length is None:
                    response.pop("ContentLength")
                self.client.get_object.return_value = response

                with self.assertRaises(ValueError):
                    s3_client.download_source_image_from_s3(
                        self.BASE_URL + "source.jpg",
                        self.output_path,
                    )

                self.assertTrue(body.closed)
                self.assertFalse(self.output_path.exists())

    def test_rejects_actual_stream_larger_than_limit(self):
        response, body = self.make_response(
            data=b"123456789",
            content_length=8,
        )
        self.client.get_object.return_value = response

        with patch.object(s3_client, "MAX_SOURCE_IMAGE_BYTES", 8):
            with self.assertRaises(ValueError):
                s3_client.download_source_image_from_s3(
                    self.BASE_URL + "source.jpg",
                    self.output_path,
                )

        self.assertTrue(body.closed)
        self.assertFalse(self.output_path.exists())

    def test_rejects_empty_or_truncated_stream(self):
        cases = (
            (1, b""),
            (10, b"short"),
        )

        for content_length, data in cases:
            with self.subTest(content_length=content_length):
                response, body = self.make_response(
                    data=data,
                    content_length=content_length,
                )
                self.client.get_object.return_value = response

                with self.assertRaises(ValueError):
                    s3_client.download_source_image_from_s3(
                        self.BASE_URL + "source.jpg",
                        self.output_path,
                    )

                self.assertTrue(body.closed)
                self.assertFalse(self.output_path.exists())


if __name__ == "__main__":
    unittest.main()
