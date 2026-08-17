"""Unit tests for the iOS L1 wire-validation script.

Run from the repo root:

    python -m unittest scripts.test_validate_l1_logs

Fixtures live in scripts/fixtures/ — each file is a snippet of a real
branchlogs.txt capture, hand-tailored to exercise one validator behaviour.
They encode the 4.0.0-beta wire protocol (`/v3/events/open`, `/v3/deeplink`,
`/v2/event/standard`, `/v1/url`), not master's v1 protocol.
"""

import io
import os
import sys
import unittest
from contextlib import redirect_stderr, redirect_stdout

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, THIS_DIR)

import validate_l1_logs as v  # noqa: E402

FIXTURE_DIR = os.path.join(THIS_DIR, "fixtures")


def _fixture(name):
    return os.path.join(FIXTURE_DIR, name)


def _run_validation(fixture_name, scenario=None):
    """Run validate_entries on a fixture and capture stdout. Returns
    (errors, captured_output)."""
    entries = v.parse_branch_logs(_fixture(fixture_name))
    buf = io.StringIO()
    with redirect_stdout(buf):
        errors = v.validate_entries(entries, scenario=scenario)
    return errors, buf.getvalue()


class ParseBranchLogsTests(unittest.TestCase):
    def test_returns_none_when_file_missing(self):
        result = v.parse_branch_logs(_fixture("does_not_exist.txt"))
        self.assertIsNone(result)

    def test_parses_branchlog_request_lines(self):
        entries = v.parse_branch_logs(_fixture("happy_path.txt"))
        self.assertEqual(len(entries), 2)
        self.assertEqual(entries[0]["uri"], "/v3/events/open")
        self.assertEqual(entries[1]["uri"], "/v1/url")
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

    def test_v2_event_contract_is_satisfied_by_nested_shape(self):
        entries = v.parse_branch_logs(_fixture("v2_nested.txt"))
        request = entries[0]["request"]
        missing = [
            f for f in v.REQUIRED_V2_EVENT
            if not v.is_present(v.lookup_field(request, f))
        ]
        self.assertEqual(missing, [], f"Unresolved v2 fields: {missing}")


class OpenRequiredTests(unittest.TestCase):
    """On this line install and open both post to /v3/events/open, so every
    session produces one and a capture without it is a broken capture.
    /v1/install is never sent and is no longer asserted."""

    def test_capture_without_open_fails(self):
        errors, _ = _run_validation("no_open.txt")
        self.assertTrue(
            any("'/v3/events/open' was not captured" in e for e in errors),
            f"Expected open-missing error, got: {errors}",
        )

    def test_v1_install_is_not_demanded(self):
        # no_open.txt has no /v1/install either; the only complaint must be
        # about the open.
        errors, _ = _run_validation("no_open.txt")
        self.assertFalse(
            any("/v1/install" in e for e in errors),
            f"Retired endpoint still asserted: {errors}",
        )

    def test_retired_v1_endpoints_have_no_contract(self):
        self.assertNotIn("/v1/install", v.REQUIRED_PER_ENDPOINT)
        self.assertNotIn("/v1/open", v.REQUIRED_PER_ENDPOINT)


class BetaEndpointCoverageTests(unittest.TestCase):
    """The three endpoints this line uses for attribution traffic are
    checked, not skipped. Prefix-scoping to /v1/* was what let them pass
    unexamined."""

    def test_open_event_and_deeplink_all_have_contracts(self):
        for uri in ("/v3/events/open", "/v3/deeplink", "/v2/event/standard"):
            self.assertIn(uri, v.REQUIRED_PER_ENDPOINT)
            self.assertTrue(v.required_fields_for(uri, {}))

    def test_open_carries_the_install_identity_pair(self):
        # These were /v1/install-only on master; the open absorbed them.
        fields = v.required_fields_for("/v3/events/open", {})
        self.assertIn("first_install_time", fields)
        self.assertIn("is_hardware_id_real", fields)

    def test_open_does_not_require_conditional_tokens(self):
        # A first-ever install open has no device/bundle token yet.
        fields = v.required_fields_for("/v3/events/open", {})
        self.assertNotIn("randomized_device_token", fields)
        self.assertNotIn("randomized_bundle_token", fields)

    def test_v2_event_requires_idfv_not_hardware_id(self):
        # /v2/event/* spells the vendor id `idfv` under user_data.
        fields = v.required_fields_for("/v2/event/standard", {})
        self.assertIn("idfv", fields)
        self.assertNotIn("hardware_id", fields)

    def test_v2_event_missing_device_field_fails(self):
        errors, output = _run_validation("v2_event_missing_idfv.txt")
        self.assertTrue(
            any("missing required field 'idfv'" in e for e in errors),
            f"Expected idfv-missing error, got: {errors}",
        )
        self.assertIn("/v2/event/standard", output)

    def test_deeplink_is_checked_and_passes(self):
        errors, output = _run_validation("deeplink.txt")
        self.assertEqual(errors, [], f"Unexpected errors: {errors}")
        self.assertIn("/v3/deeplink", output)

    def test_absent_deeplink_is_a_note_not_a_failure(self):
        # The L1 runner performs a single launch and never resolves a link,
        # so a capture without /v3/deeplink is healthy.
        errors, output = _run_validation("happy_path.txt")
        self.assertEqual(errors, [], f"Unexpected errors: {errors}")
        self.assertIn("'/v3/deeplink' not present in capture", output)

    def test_deeplink_does_not_require_ios_app_link_url(self):
        # Cold resolution carries no URL; only the URL-driven one does.
        self.assertNotIn(
            "ios_app_link_url", v.required_fields_for("/v3/deeplink", {})
        )


class ScenarioEnforcementTests(unittest.TestCase):
    """--scenario promotes an endpoint the run is known to drive from a
    note to a failure, without changing the no-scenario default."""

    def test_deeplink_scenario_fails_when_deeplink_absent(self):
        errors, _ = _run_validation("happy_path.txt", scenario="deeplink")
        self.assertTrue(
            any("/v3/deeplink" in e for e in errors),
            f"Expected a missing-deeplink error, got: {errors}",
        )

    def test_deeplink_scenario_passes_when_deeplink_present(self):
        errors, _ = _run_validation("deeplink.txt", scenario="deeplink")
        self.assertEqual(errors, [], f"Unexpected errors: {errors}")

    def test_install_scenario_keeps_absent_deeplink_a_note(self):
        errors, output = _run_validation("happy_path.txt", scenario="install")
        self.assertEqual(errors, [], f"Unexpected errors: {errors}")
        self.assertIn("'/v3/deeplink' not present in capture", output)

    def test_unrecognised_scenario_exits_rather_than_downgrading(self):
        # A typo in a CI matrix must fail loudly, not fall back to the
        # weaker default and report a pass.
        saved_argv = sys.argv
        sys.argv = [
            "validate_l1_logs.py",
            _fixture("happy_path.txt"),
            "--scenario",
            "deeplinks",
        ]
        try:
            with redirect_stderr(io.StringIO()), redirect_stdout(io.StringIO()):
                with self.assertRaises(SystemExit) as ctx:
                    v.main()
            self.assertNotEqual(ctx.exception.code, 0)
        finally:
            sys.argv = saved_argv


class AttributionLevelTierTests(unittest.TestCase):
    """Parts of the device block are gated on the consumer-protection
    attribution level (BNCRequestFactory.m:747 and :751-752), so the
    required-field list has to be resolved per request from that request's
    own `cpp_level` rather than applied flat."""

    def test_none_level_deeplink_passes(self):
        # /v3/deeplink is exempt from the attribution-None request skip
        # (BNCServerRequestOperation.m:68-75), so a capture at level None
        # still posts one — with the device block correctly stripped.
        errors, output = _run_validation("attribution_none_deeplink.txt")
        self.assertEqual(errors, [], f"Unexpected errors: {errors}")
        self.assertIn("/v3/deeplink", output)

    def test_full_level_still_requires_the_hardware_block(self):
        errors, _ = _run_validation("attribution_full_missing_hardware.txt")
        self.assertTrue(
            any("missing required field 'hardware_id'" in e for e in errors),
            f"Expected hardware_id-missing error, got: {errors}",
        )
        self.assertTrue(
            any("missing required field 'is_hardware_id_real'" in e for e in errors),
            f"Expected is_hardware_id_real-missing error, got: {errors}",
        )

    def test_absent_cpp_level_reads_as_uninitialized_and_requires_hardware(self):
        # cpp_level is only emitted once the level has been set
        # (BNCRequestFactory.m:641-646). Absent means uninitialized, which
        # takes the same branch as Full at :751-752.
        fields = v.required_fields_for("/v3/deeplink", {})
        self.assertIn("hardware_id", fields)
        self.assertIn("is_hardware_id_real", fields)

    def test_none_level_drops_the_attribution_gated_fields(self):
        fields = v.required_fields_for("/v3/deeplink", {"cpp_level": "NONE"})
        for field in ("hardware_id", "is_hardware_id_real", "anon_id",
                      "local_ip", "first_install_time"):
            self.assertNotIn(field, fields)

    def test_reduced_level_keeps_not_none_fields_but_drops_hardware(self):
        fields = v.required_fields_for("/v3/deeplink", {"cpp_level": "REDUCED"})
        self.assertIn("local_ip", fields)
        self.assertIn("anon_id", fields)
        self.assertNotIn("hardware_id", fields)
        self.assertNotIn("is_hardware_id_real", fields)

    def test_unconditional_fields_survive_every_level(self):
        for level in (None, "FULL", "REDUCED", "MINIMAL", "NONE"):
            request = {} if level is None else {"cpp_level": level}
            fields = v.required_fields_for("/v3/events/open", request)
            for field in ("branch_key", "sdk", "brand", "os", "connection_type"):
                self.assertIn(field, fields, f"{field} dropped at level {level}")

    def test_level_resolves_from_user_data_on_v2_shape(self):
        # /v2/event/* nests cpp_level under user_data alongside the device
        # block (BNCRequestFactory.m:733).
        request = {"user_data": {"cpp_level": "REDUCED"}}
        self.assertEqual(v.attribution_level(request), "REDUCED")

    def test_v2_event_idfv_is_not_none_gated(self):
        # v2dictionary gates idfv on not-None-or-uninitialized (:688-690).
        self.assertNotIn(
            "idfv", v.required_fields_for("/v2/event/standard",
                                          {"user_data": {"cpp_level": "NONE"}})
        )
        self.assertIn(
            "idfv", v.required_fields_for("/v2/event/standard", {})
        )


class UncontractedEndpointTests(unittest.TestCase):
    """An endpoint with no entry in REQUIRED_PER_ENDPOINT is printed and
    labelled, not silently skipped and not failed."""

    def test_uncontracted_endpoint_does_not_fail_the_run(self):
        errors, output = _run_validation("uncontracted_endpoint.txt")
        self.assertEqual(
            errors, [],
            f"Uncontracted endpoint should not produce errors; got: {errors}",
        )
        self.assertIn("No L1 field contract defined for this endpoint", output)


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
