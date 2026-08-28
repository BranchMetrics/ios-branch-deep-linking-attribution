"""Unit tests for the iOS L1 wire-validation script.

Run from the repo root:

    python -m unittest scripts.test_validate_l1_logs

Fixtures live in scripts/fixtures/ — each file is a snippet of a real
branchlogs.txt capture, hand-tailored to exercise one validator behaviour.
They encode the 4.0.0-beta wire protocol (`/v3/events/open`, `/v3/deeplink`,
`/v3/events/standard`, `/v1/url`), not master's v1 protocol.
"""

import inspect
import io
import os
import sys
import unittest
from contextlib import redirect_stderr, redirect_stdout
from urllib.parse import urlparse

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, THIS_DIR)

import validate_l1_logs as v  # noqa: E402

FIXTURE_DIR = os.path.join(THIS_DIR, "fixtures")


def _fixture(name):
    return os.path.join(FIXTURE_DIR, name)


# Asserts nothing about the wire shape, so a field-validation test is not
# also asserting counts. Scenario tests pass a real contract instead.
ANY_CAPTURE = {"counts": {}, "order": ()}


def _run_validation(fixture_name, contract=ANY_CAPTURE):
    """Run validate_entries on a fixture and capture stdout. Returns
    (errors, captured_output)."""
    entries = v.parse_branch_logs(_fixture(fixture_name))
    buf = io.StringIO()
    with redirect_stdout(buf):
        errors = v.validate_entries(entries, contract)
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


class NormalizedCaptureFormatTests(unittest.TestCase):
    """The entry shape is the seam between the platform-specific parser and
    every check downstream. Android's parser emits the same three keys, so a
    drift here silently breaks the shared checks rather than this parser."""

    def test_parser_emits_exactly_the_declared_keys(self):
        entries = v.parse_branch_logs(_fixture("happy_path.txt"))
        self.assertTrue(entries)
        for entry in entries:
            self.assertEqual(
                tuple(sorted(entry)), tuple(sorted(v.CAPTURE_ENTRY_KEYS))
            )

    def test_uri_is_the_url_path(self):
        entries = v.parse_branch_logs(_fixture("happy_path.txt"))
        for entry in entries:
            self.assertEqual(entry["uri"], urlparse(entry["url"]).path)


class ScenarioContractModelTests(unittest.TestCase):
    """The contract carries every endpoint name, so the checks can stay
    platform- and API-version-agnostic. Not yet wired into validation."""

    def test_every_contract_declares_counts_and_order(self):
        for name, contract in v.SCENARIO_CONTRACTS.items():
            self.assertEqual(
                set(contract), {"counts", "order"}, f"contract '{name}'"
            )

    def test_counts_are_non_negative_integers(self):
        for name, contract in v.SCENARIO_CONTRACTS.items():
            for endpoint, count in contract["counts"].items():
                self.assertIsInstance(count, int, f"{name}:{endpoint}")
                self.assertGreaterEqual(count, 0, f"{name}:{endpoint}")

    def test_order_entries_are_endpoint_pairs(self):
        for name, contract in v.SCENARIO_CONTRACTS.items():
            for pair in contract["order"]:
                self.assertEqual(len(pair), 2, f"contract '{name}'")
                self.assertNotEqual(pair[0], pair[1], f"contract '{name}'")

    def test_contract_for_returns_the_named_contract(self):
        self.assertIs(v.contract_for("deeplink"), v.SCENARIO_CONTRACTS["deeplink"])

    def test_contract_for_raises_on_an_unknown_name(self):
        # A typo must fail loudly instead of validating against nothing.
        with self.assertRaises(v.UnknownScenario) as ctx:
            v.contract_for("deeplnk")
        self.assertIn("deeplnk", str(ctx.exception))


def _capture(*uris):
    """Normalized entries with fabricated endpoint names. The engine must not
    care that these are not real Branch endpoints."""
    return [{"uri": u, "url": "https://example.test" + u, "request": {}} for u in uris]


class AssertionEngineTests(unittest.TestCase):
    """Driven entirely from fabricated endpoints, which is what proves the
    engine holds no endpoint name and no log format of its own."""

    def test_exact_count_satisfied(self):
        contract = {"counts": {"/alpha": 2}, "order": ()}
        self.assertEqual(v.assert_contract(_capture("/alpha", "/alpha"), contract), [])

    def test_too_many_fails(self):
        contract = {"counts": {"/alpha": 1}, "order": ()}
        errors = v.assert_contract(_capture("/alpha", "/alpha"), contract)
        self.assertEqual(len(errors), 1)
        self.assertIn("Expected 1", errors[0])

    def test_too_few_fails(self):
        contract = {"counts": {"/alpha": 2}, "order": ()}
        errors = v.assert_contract(_capture("/alpha"), contract)
        self.assertEqual(len(errors), 1)
        self.assertIn("captured 1", errors[0])

    def test_count_zero_forbids_the_endpoint(self):
        contract = {"counts": {"/beta": 0}, "order": ()}
        self.assertEqual(v.assert_contract(_capture("/alpha"), contract), [])
        errors = v.assert_contract(_capture("/alpha", "/beta"), contract)
        self.assertEqual(len(errors), 1)
        self.assertIn("must not be captured", errors[0])

    def test_unlisted_endpoints_are_unconstrained(self):
        contract = {"counts": {"/alpha": 1}, "order": ()}
        self.assertEqual(v.assert_contract(_capture("/alpha", "/gamma"), contract), [])

    def test_order_holds_when_other_traffic_interleaves(self):
        # The real shape: a launch open precedes the link resolution, and the
        # attributed open follows it. "first after first" would fail this.
        contract = {"counts": {}, "order": (("/beta", "/alpha"),)}
        self.assertEqual(
            v.assert_contract(_capture("/alpha", "/beta", "/alpha"), contract), []
        )

    def test_order_violated_when_later_never_follows(self):
        contract = {"counts": {}, "order": (("/beta", "/alpha"),)}
        errors = v.assert_contract(_capture("/alpha", "/beta"), contract)
        self.assertEqual(len(errors), 1)
        self.assertIn("after", errors[0])

    def test_order_is_fail_closed_when_an_endpoint_is_absent(self):
        # An order check that passes vacuously repeats the defect this engine
        # exists to remove.
        contract = {"counts": {}, "order": (("/beta", "/alpha"),)}
        self.assertEqual(len(v.assert_contract(_capture("/alpha"), contract)), 1)
        self.assertEqual(len(v.assert_contract([], contract)), 1)

    def test_every_violation_is_reported_not_just_the_first(self):
        contract = {"counts": {"/alpha": 5, "/beta": 0}, "order": (("/beta", "/alpha"),)}
        self.assertEqual(len(v.assert_contract(_capture("/alpha", "/beta"), contract)), 3)

    def test_the_seeded_deeplink_contract_accepts_the_real_capture_shape(self):
        # Measured on device: open, deeplink, open.
        errors = v.assert_contract(
            _capture("/v3/events/open", "/v3/deeplink", "/v3/events/open"),
            v.contract_for("deeplink"),
        )
        self.assertEqual(errors, [], f"Unexpected errors: {errors}")


class EnginePortabilityTests(unittest.TestCase):
    def test_engine_source_holds_no_endpoint_or_log_format_literal(self):
        """The engine must be liftable into the Android repo unchanged. A
        literal endpoint or capture-format string here would break that, and
        would not be caught by the behavioural tests above."""
        source = "".join(
            inspect.getsource(fn) for fn in (v.assert_contract, v.occurs_after)
        )
        for forbidden in ("/v1", "/v2", "/v3", "BranchLog", "posting to", "Post value"):
            self.assertNotIn(forbidden, source, f"engine leaked '{forbidden}'")


class RetryCollapseTests(unittest.TestCase):
    """One logical request is logged once per attempt, because the SDK's retry
    handler re-runs the request builder and that is what writes the line.
    Counting attempts would fail an exact-count contract on a flaky network."""

    def test_retried_request_counts_once(self):
        entries = v.parse_branch_logs(_fixture("retried_open.txt"))
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0]["request"][v.RETRY_COUNT_FIELD], 0)

    def test_retried_capture_satisfies_an_exact_count_contract(self):
        entries = v.parse_branch_logs(_fixture("retried_open.txt"))
        self.assertEqual(v.assert_contract(entries, v.contract_for("N1")), [])

    def test_first_attempt_is_kept(self):
        kept = v.collapse_retries([{"uri": "/a", "url": "u", "request": {"retryNumber": 0}}])
        self.assertEqual(len(kept), 1)

    def test_entries_without_the_field_are_kept(self):
        # Android bodies may not carry it; dropping them would empty a capture.
        kept = v.collapse_retries([{"uri": "/a", "url": "u", "request": {}}])
        self.assertEqual(len(kept), 1)

    def test_a_boolean_is_not_read_as_an_attempt_number(self):
        kept = v.collapse_retries([{"uri": "/a", "url": "u", "request": {"retryNumber": True}}])
        self.assertEqual(len(kept), 1)

    def test_non_dict_body_is_kept(self):
        kept = v.collapse_retries([{"uri": "/a", "url": "u", "request": []}])
        self.assertEqual(len(kept), 1)


class N1ContractTests(unittest.TestCase):
    """N1 organic_open, the worked example: one open, no deep link. Each test
    below proves an assertion type FAILS on a violating capture — a contract
    only demonstrated passing is a contract that cannot fail."""

    def test_a_clean_organic_open_passes(self):
        errors, _ = _run_validation("happy_path.txt", v.contract_for("N1"))
        self.assertEqual(errors, [], f"Unexpected errors: {errors}")

    def test_wrong_count_fails(self):
        # Two opens is the duplicate-open shape #1612 produced. Before this
        # engine the capture could not fail, which is why it went unnoticed.
        errors, _ = _run_validation("n1_duplicate_open.txt", v.contract_for("N1"))
        self.assertEqual(len(errors), 1, errors)
        self.assertIn("Expected 1", errors[0])
        self.assertIn("captured 2", errors[0])

    def test_forbidden_endpoint_present_fails(self):
        errors, _ = _run_validation("deeplink.txt", v.contract_for("N1"))
        self.assertEqual(len(errors), 1, errors)
        self.assertIn("must not be captured", errors[0])
        self.assertIn("/v3/deeplink", errors[0])

    def test_wrong_order_fails(self):
        # deeplink.txt is open then deeplink, with no open after it, so the
        # deeplink contract's ordering rule is violated.
        errors, _ = _run_validation("deeplink.txt", v.contract_for("deeplink"))
        self.assertTrue(
            any("after" in e for e in errors), f"Expected an order error: {errors}"
        )

    def test_n1_does_not_assert_the_absence_of_link_data_in_the_open(self):
        # Recorded, not hidden: the plan also wants the open to carry no link
        # data. That is a field-level assertion this layer does not make.
        self.assertEqual(v.contract_for("N1")["counts"].get("/v3/deeplink"), 0)


class N3ContractTests(unittest.TestCase):
    """N3 attribution_none: at consumer-protection level NONE,
    BNCServerRequestOperation drops every request except BranchRequestDeepLink,
    so the resolution goes out and the attributed open does not."""

    def test_the_none_level_capture_passes(self):
        errors, _ = _run_validation("n3_attribution_none.txt", v.contract_for("N3"))
        self.assertEqual(errors, [], f"Unexpected errors: {errors}")

    def test_an_open_at_none_level_fails(self):
        # The regression N3 exists to catch: an open must not be sent at NONE.
        errors, _ = _run_validation("attribution_none_deeplink.txt", v.contract_for("N3"))
        self.assertEqual(len(errors), 1, errors)
        self.assertIn("must not be captured", errors[0])
        self.assertIn("/v3/events/open", errors[0])

    def test_the_old_global_rule_would_have_failed_this_correct_capture(self):
        # The retired MANDATORY_ENDPOINT required an open in every capture. N1
        # still does, and N3's capture is correct without one — which is why a
        # single global rule could not serve both scenarios.
        errors, _ = _run_validation("n3_attribution_none.txt", v.contract_for("N1"))
        self.assertTrue(
            any("/v3/events/open" in e for e in errors),
            f"Expected the open requirement to fire: {errors}",
        )

    def test_n3_does_not_assert_that_identifiers_were_cleared(self):
        # Recorded, not hidden: that is a field-level assertion, and this layer
        # is bounded at counts and required-field presence.
        self.assertEqual(set(v.contract_for("N3")["counts"]), {"/v3/deeplink", "/v3/events/open"})


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
    """iOS nests device fields under user_data on /v3/events/* — lookup must
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

    def test_capture_without_open_fails_when_the_contract_requires_one(self):
        errors, _ = _run_validation("no_open.txt", v.contract_for("N1"))
        self.assertTrue(
            any("'/v3/events/open'" in e for e in errors),
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
        for uri in ("/v3/events/open", "/v3/deeplink", "/v3/events/standard"):
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
        # /v3/events/* spells the vendor id `idfv` under user_data.
        fields = v.required_fields_for("/v3/events/standard", {})
        self.assertIn("idfv", fields)
        self.assertNotIn("hardware_id", fields)

    def test_v2_event_missing_device_field_fails(self):
        errors, output = _run_validation("v2_event_missing_idfv.txt")
        self.assertTrue(
            any("missing required field 'idfv'" in e for e in errors),
            f"Expected idfv-missing error, got: {errors}",
        )
        self.assertIn("/v3/events/standard", output)

    def test_deeplink_is_checked_and_passes(self):
        errors, output = _run_validation("deeplink.txt")
        self.assertEqual(errors, [], f"Unexpected errors: {errors}")
        self.assertIn("/v3/deeplink", output)

    def test_absent_deeplink_is_fine_when_no_contract_mentions_it(self):
        # Replaces the old unconditional note: silence is now the contract's
        # job, not a hardcoded exception for one endpoint.
        errors, _ = _run_validation("happy_path.txt")
        self.assertEqual(errors, [], f"Unexpected errors: {errors}")

    def test_deeplink_does_not_require_ios_app_link_url(self):
        # Cold resolution carries no URL; only the URL-driven one does.
        self.assertNotIn(
            "ios_app_link_url", v.required_fields_for("/v3/deeplink", {})
        )


class ScenarioEnforcementTests(unittest.TestCase):
    """A capture is judged against its scenario's contract, so the same file
    passes one scenario and fails another."""

    def test_deeplink_scenario_fails_when_deeplink_absent(self):
        errors, _ = _run_validation("happy_path.txt", v.contract_for("deeplink"))
        self.assertTrue(
            any("/v3/deeplink" in e for e in errors),
            f"Expected a missing-deeplink error, got: {errors}",
        )

    def test_deeplink_scenario_passes_on_the_measured_capture_shape(self):
        # open, deeplink, open — measured on device. The launch open precedes
        # the resolution, so an order rule of "first after first" would fail
        # this correct capture.
        errors, _ = _run_validation("deeplink_scenario.txt", v.contract_for("deeplink"))
        self.assertEqual(errors, [], f"Unexpected errors: {errors}")

    def test_the_same_capture_passes_install_and_fails_deeplink(self):
        # The point of per-scenario contracts: one global rule cannot express
        # this, and before this change the install capture could not fail.
        passing, _ = _run_validation("happy_path.txt", v.contract_for("N1"))
        failing, _ = _run_validation("happy_path.txt", v.contract_for("deeplink"))
        self.assertEqual(passing, [])
        self.assertTrue(failing)

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
        # /v3/events/* nests cpp_level under user_data alongside the device
        # block (BNCRequestFactory.m:733).
        request = {"user_data": {"cpp_level": "REDUCED"}}
        self.assertEqual(v.attribution_level(request), "REDUCED")

    def test_v2_event_idfv_is_not_none_gated(self):
        # v2dictionary gates idfv on not-None-or-uninitialized (:688-690).
        self.assertNotIn(
            "idfv", v.required_fields_for("/v3/events/standard",
                                          {"user_data": {"cpp_level": "NONE"}})
        )
        self.assertIn(
            "idfv", v.required_fields_for("/v3/events/standard", {})
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
