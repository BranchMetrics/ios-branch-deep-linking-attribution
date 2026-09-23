"""Scenario contract tests for the iOS L1 wire validator, run against
scrubbed captures from the TestBed.

Run from the repo root:

    python -m unittest discover -s scripts -p "test_*.py"
"""

import copy
import io
import os
import shutil
import sys
import tempfile
import unittest
from contextlib import redirect_stdout

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, THIS_DIR)

import validate_l1_logs as v  # noqa: E402

FIXTURE_DIR = os.path.join(THIS_DIR, "fixtures")


REPO_ROOT = os.path.dirname(THIS_DIR)
# The URL the hot_uriScheme fixture was captured with.
FIXTURE_URL = "branchtest://probe?run=D1"


def _validate(fixture_name, scenario, drop=None):
    entries = v.parse_branch_logs(os.path.join(FIXTURE_DIR, fixture_name))
    if drop is not None:
        uri, field = drop
        for entry in entries:
            if entry["uri"] == uri:
                entry["request"].pop(field, None)
    with redirect_stdout(io.StringIO()):
        return v.validate_entries(entries, v.contract_for(scenario))


class HotUriSchemeContractTests(unittest.TestCase):
    """hot_uriScheme: one resolve, then exactly one open."""

    def test_the_hot_capture_passes(self):
        # Delivery delta of a scheme URL opened into a foregrounded TestBed.
        self.assertEqual(_validate("hot_uriScheme.txt", "hot_uriScheme"), [])

    def test_a_second_open_fails(self):
        # Cold link launch after reinstall: the chained open plus a plain one.
        errors = _validate("hot_uriScheme_duplicate_open.txt", "hot_uriScheme")
        self.assertEqual(len(errors), 1, errors)
        self.assertIn("captured 2", errors[0])

    def test_a_resolve_without_external_intent_uri_fails(self):
        errors = _validate(
            "hot_uriScheme.txt", "hot_uriScheme", drop=("/v3/deeplink", "external_intent_uri")
        )
        self.assertEqual(len(errors), 1, errors)
        self.assertIn("'/v3/deeplink' request(s) to carry 'external_intent_uri'", errors[0])

    def test_an_open_without_link_data_fails(self):
        errors = _validate(
            "hot_uriScheme.txt", "hot_uriScheme", drop=("/v3/events/open", "link_data")
        )
        self.assertEqual(len(errors), 1, errors)
        self.assertIn("'/v3/events/open' request(s) to carry 'link_data'", errors[0])


# The URL the warm_uriScheme fixture was captured with.
WARM_URL = "branchtest://open?scenario=W2"
OPEN = "/v3/events/open"


def _warm_entries():
    # Resolve, the link-carrying open, then the plain duplicate open.
    return v.parse_branch_logs(os.path.join(FIXTURE_DIR, "warm_uriScheme.txt"))


def _validate_w2(entries):
    with redirect_stdout(io.StringIO()):
        return v.validate_entries(entries, v.contract_for("warm_uriScheme"))


class WarmUriSchemeContractTests(unittest.TestCase):
    """warm_uriScheme: one resolve, one link-carrying open, at most two opens,
    no install."""

    def test_the_warm_wire_capture_passes(self):
        # Two opens: the known warm duplicate, which an exact open count would fail.
        self.assertEqual(_validate_w2(_warm_entries()), [])

    def test_one_open_also_passes(self):
        self.assertEqual(_validate_w2(_warm_entries()[:-1]), [])

    def test_a_second_link_carrying_open_fails(self):
        entries = _warm_entries()
        entries[2]["request"]["link_data"] = {}
        self.assertEqual(
            _validate_w2(entries),
            ["Expected 1 of the '/v3/events/open' request(s) to carry 'link_data', but 2 of 2 did."],
        )

    def test_an_install_shaped_open_fails(self):
        entries = _warm_entries()
        entries[2]["request"].pop("randomized_bundle_token")
        self.assertEqual(
            _validate_w2(entries),
            ["Every '/v3/events/open' request must carry 'randomized_bundle_token', but 1 of 2 did not."],
        )

    def test_a_third_open_fails(self):
        entries = _warm_entries()
        entries.append(copy.deepcopy(entries[2]))
        self.assertEqual(_validate_w2(entries), ["Expected at most 2 '/v3/events/open' request(s), captured 3."])

    def test_new_rule_kinds_cannot_pass_vacuously(self):
        warm = v.SCENARIO_CONTRACTS["warm_uriScheme"]
        self.assertTrue({"carrying", "carried_by_all", "max_counts"} <= set(warm))
        for name, contract in v.SCENARIO_CONTRACTS.items():
            counts = contract["counts"]
            carrying = contract.get("carrying", {})
            bounds = contract.get("max_counts", {})
            for endpoint, fields in carrying.items():
                for field, count in fields.items():
                    self.assertGreaterEqual(count, 1, f"{name}:{endpoint}:{field}")
                    if endpoint in bounds:
                        self.assertLessEqual(count, bounds[endpoint], f"{name}:{endpoint}:{field}")
            for endpoint in contract.get("carried_by_all", {}):
                self.assertTrue(counts.get(endpoint, 0) >= 1 or endpoint in carrying, f"{name}:{endpoint}")
            for endpoint, bound in bounds.items():
                self.assertGreaterEqual(bound, 1, f"{name}:{endpoint}")
                self.assertNotIn(endpoint, counts, f"{name}:{endpoint}")


class DeliveredUrlTests(unittest.TestCase):
    """`--url` ties the resolve and the open to the URL the driver delivered."""

    def _entries(self):
        return v.parse_branch_logs(os.path.join(FIXTURE_DIR, "hot_uriScheme.txt"))

    def test_an_open_without_link_data_is_not_checked_for_the_url(self):
        self.assertEqual(v.assert_delivered_url(_warm_entries(), WARM_URL), [])

    def test_a_link_carrying_open_with_another_url_fails(self):
        entries = _warm_entries()
        entries[1]["request"]["link_data"]["+non_branch_link"] = "branchtest://open?scenario=H2"
        errors = v.assert_delivered_url(entries, WARM_URL)
        self.assertEqual(len(errors), 1, errors)
        self.assertIn(f"'{OPEN}'", errors[0])

    def test_the_delivered_url_passes(self):
        self.assertEqual(v.assert_delivered_url(self._entries(), FIXTURE_URL), [])

    def test_a_different_url_fails_on_both_requests(self):
        errors = v.assert_delivered_url(self._entries(), "branchtest://open?scenario=H2")
        self.assertEqual(len(errors), 2, errors)
        self.assertIn("'/v3/deeplink'", errors[0])
        self.assertIn("'/v3/events/open'", errors[1])


class HotUriSchemeWiringTests(unittest.TestCase):
    """These checks protect nothing unless the workflow and the TestBed run them."""

    def _read(self, *parts):
        with open(os.path.join(REPO_ROOT, *parts)) as f:
            return f.read()

    def test_the_workflow_runs_both_checkers_on_the_delta(self):
        workflow = self._read(".github", "workflows", "layer1-logger-tests.yml")
        self.assertIn('post="$OUTPUT_DIR/wire-hot_uriScheme.post.txt"', workflow)
        self.assertIn('pre="$OUTPUT_DIR/wire-hot_uriScheme.pre.txt"', workflow)
        self.assertIn('validate_l1_logs.py "$post" --scenario hot_uriScheme', workflow)
        self.assertIn('--pre "$pre" --url "$H2_URL"', workflow)
        self.assertIn('check_foreground_markers.py "$post" --pre "$pre"', workflow)
        self.assertEqual(workflow.count("H2_URL: branchtest://open?scenario=H2"), 2)

    def test_the_testbed_delivers_urls_only_through_the_marked_app_delegate_method(self):
        # A scene manifest or openURL:options: would bypass the openURL marker.
        self.assertNotIn("UIApplicationSceneManifest", self._read("Branch-TestBed", "Branch-TestBed", "Branch-TestBed-Info.plist"))
        app_delegate = self._read("Branch-TestBed", "Branch-TestBed", "AppDelegate.m")
        self.assertEqual(app_delegate.count("openURL:(NSURL *)"), 1)
        self.assertEqual(app_delegate.count('logLifecycleMarker:@"openURL"'), 1)


def _fixture_bytes(name):
    with open(os.path.join(FIXTURE_DIR, name), "rb") as f:
        return f.read()


class CaptureDeltaTests(unittest.TestCase):
    """`--pre` validates only what the delivery appended to the capture."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp)

    def _write(self, name, data):
        path = os.path.join(self.tmp, name)
        with open(path, "wb") as f:
            f.write(data)
        return path

    def _main(self, post, pre, url=None):
        saved_argv = sys.argv
        sys.argv = [
            "validate_l1_logs.py", post, "--scenario", "hot_uriScheme", "--pre", pre
        ]
        if url is not None:
            sys.argv += ["--url", url]
        out = io.StringIO()
        try:
            with redirect_stdout(out):
                with self.assertRaises(SystemExit) as ctx:
                    v.main()
        finally:
            sys.argv = saved_argv
        return ctx.exception.code, out.getvalue()

    def test_launch_traffic_before_the_snapshot_is_not_counted(self):
        # The launch open sits in the snapshot; counted, it is a second open.
        pre_bytes = _fixture_bytes("hot_uriScheme_launch_pre.txt")
        pre = self._write("pre.txt", pre_bytes)
        post = self._write("post.txt", pre_bytes + _fixture_bytes("hot_uriScheme.txt"))
        code, output = self._main(post, pre)
        self.assertEqual(code, 0, output)
        self.assertIn("--- VALIDATION PASSED (2/2 requests valid) ---", output)

    def test_a_delta_for_another_url_fails(self):
        pre_bytes = _fixture_bytes("hot_uriScheme_launch_pre.txt")
        pre = self._write("pre.txt", pre_bytes)
        post = self._write("post.txt", pre_bytes + _fixture_bytes("hot_uriScheme.txt"))
        self.assertEqual(self._main(post, pre, url=FIXTURE_URL)[0], 0)
        code, output = self._main(post, pre, url="branchtest://open?scenario=H2")
        self.assertEqual(code, 1)
        self.assertIn("to carry the delivered URL branchtest://open?scenario=H2", output)

    def test_a_snapshot_that_is_not_a_prefix_fails(self):
        # A relaunch deletes and restarts the log, so the snapshot no longer leads it.
        pre = self._write("pre.txt", _fixture_bytes("hot_uriScheme_launch_pre.txt"))
        post = self._write("post.txt", _fixture_bytes("hot_uriScheme.txt"))
        code, output = self._main(post, pre)
        self.assertEqual(code, 1)
        self.assertIn("FAILED: --pre capture is not a byte prefix of the capture", output)

    def test_an_empty_snapshot_fails(self):
        pre = self._write("pre.txt", b"")
        post = self._write("post.txt", _fixture_bytes("hot_uriScheme.txt"))
        code, output = self._main(post, pre)
        self.assertEqual(code, 1)
        self.assertIn("FAILED: --pre capture is empty", output)


if __name__ == "__main__":
    unittest.main()
