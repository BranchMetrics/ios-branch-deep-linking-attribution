"""Unit tests for the iOS L1 wire-validation script.

Run from the repo root:

    python -m unittest scripts.test_validate_l1_logs

Fixtures live in scripts/fixtures/ — each file is a snippet of a real
branchlogs.txt capture, hand-tailored to exercise one validator behaviour.
"""

import io
import os
import sys
import unittest
from contextlib import redirect_stdout

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, THIS_DIR)

import validate_l1_logs as v  # noqa: E402

FIXTURE_DIR = os.path.join(THIS_DIR, "fixtures")


def _fixture(name):
    return os.path.join(FIXTURE_DIR, name)


def _run_validation(fixture_name):
    """Run validate_entries on a fixture and capture stdout. Returns
    (errors, captured_output)."""
    entries = v.parse_branch_logs(_fixture(fixture_name))
    buf = io.StringIO()
    with redirect_stdout(buf):
        errors = v.validate_entries(entries)
    return errors, buf.getvalue()


class ParseBranchLogsTests(unittest.TestCase):
    def test_returns_none_when_file_missing(self):
        result = v.parse_branch_logs(_fixture("does_not_exist.txt"))
        self.assertIsNone(result)

    def test_parses_branchlog_request_lines(self):
        entries = v.parse_branch_logs(_fixture("happy_path.txt"))
        self.assertEqual(len(entries), 2)
        self.assertEqual(entries[0]["uri"], "/v1/install")
        self.assertEqual(entries[1]["uri"], "/v1/open")
        self.assertIsInstance(entries[0]["request"], dict)


class HappyPathTests(unittest.TestCase):
    """Every required field is present — validator must return no errors."""

    def test_no_errors(self):
        errors, _ = _run_validation("happy_path.txt")
        self.assertEqual(errors, [], f"Unexpected errors: {errors}")

    def test_prints_full_payload(self):
        _, output = _run_validation("happy_path.txt")
        self.assertIn("Full payload:", output)
        self.assertIn('"brand": "Apple"', output)

    def test_prints_check_table(self):
        _, output = _run_validation("happy_path.txt")
        self.assertIn("Required fields", output)
        for field in v.REQUIRED_COMMON:
            self.assertIn(field, output)


class IOSSpecificFieldSetTests(unittest.TestCase):
    """Verify iOS-specific divergence from Android: no wifi, no ui_mode."""

    def test_wifi_not_in_required_set(self):
        self.assertNotIn("wifi", v.REQUIRED_COMMON)

    def test_ui_mode_not_in_required_set(self):
        self.assertNotIn("ui_mode", v.REQUIRED_COMMON)

    def test_connection_type_is_required(self):
        # iOS reports connectivity exclusively via connection_type.
        self.assertIn("connection_type", v.REQUIRED_COMMON)


class MissingFieldTests(unittest.TestCase):
    """When a required field is absent the validator must surface an error
    naming the missing field and the endpoint."""

    def test_missing_country_fails_with_named_error(self):
        errors, _ = _run_validation("missing_country.txt")
        self.assertTrue(
            any("missing required field 'country'" in e for e in errors),
            f"Expected country-missing error, got: {errors}",
        )


class V2NestingTests(unittest.TestCase):
    """iOS nests device fields under user_data on /v2/event/* — lookup must
    descend into the nested block to find them."""

    def test_v2_nested_fields_resolve(self):
        entries = v.parse_branch_logs(_fixture("v2_nested.txt"))
        request = entries[0]["request"]
        self.assertEqual(v.lookup_field(request, "brand"), "Apple")
        self.assertEqual(v.lookup_field(request, "connection_type"), "wifi")
        self.assertEqual(v.lookup_field(request, "sdk"), "ios")


class InstallRequiredTests(unittest.TestCase):
    """/v1/install is the canonical entry-point and must be in the capture."""

    def test_capture_without_install_fails(self):
        errors, _ = _run_validation("no_install.txt")
        self.assertTrue(
            any("'/v1/install' was not captured" in e for e in errors),
            f"Expected install-missing error, got: {errors}",
        )


class NonV1EndpointScopeTests(unittest.TestCase):
    """L1's contract covers /v1/* only. /v2/event/* uses a different schema
    (device fields under user_data, no top-level hardware_id) and must not
    fail the run when captured alongside a valid /v1/install."""

    def test_v2_event_does_not_trigger_field_failures(self):
        errors, output = _run_validation("v2_event_out_of_scope.txt")
        self.assertEqual(
            errors, [],
            f"Mixed v1+v2 capture should not produce errors; got: {errors}",
        )
        self.assertIn("Non-v1 endpoint", output)
        self.assertIn("required-field checks skipped per L1 scope", output)


class LookupFieldTests(unittest.TestCase):
    def test_returns_top_level_value_when_present(self):
        self.assertEqual(v.lookup_field({"brand": "Apple"}, "brand"), "Apple")

    def test_falls_back_to_user_data_nested_value(self):
        request = {"user_data": {"brand": "Apple"}}
        self.assertEqual(v.lookup_field(request, "brand"), "Apple")

    def test_returns_none_when_field_missing_everywhere(self):
        self.assertIsNone(v.lookup_field({"user_data": {}}, "brand"))


class IsPresentTests(unittest.TestCase):
    def test_none_is_not_present(self):
        self.assertFalse(v.is_present(None))

    def test_empty_string_is_not_present(self):
        self.assertFalse(v.is_present(""))

    def test_zero_is_present(self):
        self.assertTrue(v.is_present(0))

    def test_false_is_present(self):
        self.assertTrue(v.is_present(False))


if __name__ == "__main__":
    unittest.main()
