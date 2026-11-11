"""Tests for the multi-scene callback routing checker.

Run from the repo root:

    python -m unittest discover -s scripts -p "test_*.py"
"""

import io
import os
import shutil
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest import mock

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, THIS_DIR)

import check_scene_routing as r  # noqa: E402

NO_LINK = '{"+clicked_branch_link":false,"+is_first_session":false}'
NON_BRANCH = '{"+clicked_branch_link":false,"+is_first_session":false,"+non_branch_link":"https://example.app.link/x"}'
CLICKED = '{"+clicked_branch_link":true,"+is_first_session":false,"~referring_link":"https://example.app.link/x"}'


def _callback(scene, params=NO_LINK):
    return f"[SceneCallback] scene={scene} params={params}"


def _delivery(scene):
    return f"[TestHook] delivering -testSceneLinkURL to {scene}"


def _link_capture(target, params=CLICKED):
    """Lines in the order iOSReleaseTest writes them for a link scenario."""
    return [
        "[BranchLog] Got https://api3.branch.io/v3/deeplink Request: {}",
        _callback("scene1"),
        "[BranchLog] Got https://api3.branch.io/v3/events/open Request: {}",
        "[BranchLog] Got https://api3.branch.io/v3/deeplink Request: {}",
        _callback("scene2"),
        _delivery(target),
        "[BranchLog] Got https://api3.branch.io/v3/events/open Request: {}",
        "[BranchLog] Got https://api3.branch.io/v3/deeplink Request: {}",
        _callback(target, params),
        "[BranchLog] Got https://api3.branch.io/v3/events/open Request: {}",
    ]


def _check(lines, scenario, require_link_data=False):
    return r.check_routing(r.parse_events(lines), r.ROUTING_CONTRACTS[scenario], require_link_data)


class ParseTests(unittest.TestCase):
    def test_parses_callbacks_errors_and_deliveries_in_order(self):
        events = r.parse_events([
            "noise",
            "2026-11-10 [Branch] [2] " + _callback("scene1"),
            "[SceneCallbackError] scene=scene2 error=The request timed out.",
            _delivery("scene2"),
        ])
        self.assertEqual([e["kind"] for e in events], ["callback", "error", "delivery"])
        self.assertEqual(events[0]["params"], {"+clicked_branch_link": False, "+is_first_session": False})
        self.assertEqual(events[1]["error"], "The request timed out.")
        self.assertEqual(events[2]["scene"], "scene2")

    def test_unparseable_params_are_none(self):
        self.assertIsNone(r.parse_events([_callback("scene1", "{not json}")])[0]["params"])


class NoLinkScenarioTests(unittest.TestCase):
    """multiscene_open and multiscene_foreground: one callback per scene, no delivery."""

    def test_one_callback_per_scene_passes(self):
        lines = [_callback("scene1"), _callback("scene2")]
        self.assertEqual(_check(lines, "multiscene_open"), [])
        self.assertEqual(_check(lines, "multiscene_foreground"), [])

    def test_a_callback_on_foreground_fails(self):
        lines = [_callback("scene1"), _callback("scene2"), _callback("scene1")]
        self.assertEqual(_check(lines, "multiscene_foreground"), ["Expected 1 scene1 callback(s), captured 2."])

    def test_a_missing_scene2_callback_fails(self):
        self.assertEqual(_check([_callback("scene1")], "multiscene_open"), ["Expected 1 scene2 callback(s), captured 0."])

    def test_an_unknown_scene_fails(self):
        lines = [_callback("scene1"), _callback("scene2"), _callback("scene3")]
        self.assertEqual(_check(lines, "multiscene_open"), ["Expected 0 scene3 callback(s), captured 1."])

    def test_a_delivery_fails(self):
        lines = [_callback("scene1"), _callback("scene2"), _delivery("scene2")]
        self.assertEqual(_check(lines, "multiscene_open"), ["A link was delivered, but this scenario delivers none."])

    def test_a_callback_error_fails(self):
        lines = [_callback("scene1"), "[SceneCallbackError] scene=scene2 error=boom", _callback("scene2")]
        self.assertEqual(_check(lines, "multiscene_open"), ["scene2 callback received an error: boom"])

    def test_invalid_params_fail(self):
        lines = [_callback("scene1"), _callback("scene2", "{oops}")]
        self.assertEqual(_check(lines, "multiscene_open"), ["scene2 callback params are not valid JSON."])


class LinkScenarioTests(unittest.TestCase):
    """multiscene_link_scene1/2: the link's result reaches only the target scene."""

    def test_link_to_scene2_passes(self):
        self.assertEqual(_check(_link_capture("scene2"), "multiscene_link_scene2"), [])

    def test_link_to_scene1_passes(self):
        self.assertEqual(_check(_link_capture("scene1"), "multiscene_link_scene1"), [])

    def test_result_on_the_other_scene_fails(self):
        lines = _link_capture("scene2")
        lines[-2] = _callback("scene1", CLICKED)
        self.assertEqual(_check(lines, "multiscene_link_scene2"), [
            "Expected 1 scene1 callback(s), captured 2.",
            "Expected 2 scene2 callback(s), captured 1.",
            "scene1 callback fired for the link delivered to scene2.",
            "Expected 1 scene2 callback after the link delivery, captured 0.",
        ])

    def test_result_on_both_scenes_fails(self):
        lines = _link_capture("scene1") + [_callback("scene2", CLICKED)]
        self.assertIn("scene2 callback fired for the link delivered to scene1.", _check(lines, "multiscene_link_scene1"))

    def test_delivery_to_the_wrong_scene_fails(self):
        self.assertIn(
            "The link was delivered to scene1, expected scene2.",
            _check(_link_capture("scene1"), "multiscene_link_scene2"),
        )

    def test_a_missing_delivery_fails(self):
        lines = [line for line in _link_capture("scene2") if "TestHook" not in line]
        self.assertIn("Expected 1 link delivery, captured 0.", _check(lines, "multiscene_link_scene2"))

    def test_link_data_is_only_checked_when_required(self):
        lines = _link_capture("scene2", NON_BRANCH)
        self.assertEqual(_check(lines, "multiscene_link_scene2"), [])
        self.assertEqual(_check(lines, "multiscene_link_scene2", require_link_data=True), [
            "The scene2 callback for the link does not carry +clicked_branch_link: true; "
            "the fixture link may no longer resolve.",
        ])

    def test_resolved_link_data_passes_when_required(self):
        self.assertEqual(_check(_link_capture("scene2"), "multiscene_link_scene2", require_link_data=True), [])


class ContractTests(unittest.TestCase):
    def test_every_routing_scenario_has_a_wire_contract(self):
        import validate_l1_logs as v
        for name in r.ROUTING_CONTRACTS:
            self.assertIn(name, v.SCENARIO_CONTRACTS, name)

    def test_link_scenarios_expect_an_extra_callback_on_the_target(self):
        for name, contract in r.ROUTING_CONTRACTS.items():
            target = contract["link_scene"]
            extra = {s: n - 1 for s, n in contract["callbacks"].items()}
            if target is None:
                self.assertEqual(set(extra.values()), {0}, name)
            else:
                self.assertEqual(extra, {s: int(s == target) for s in extra}, name)


class MainTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp)

    def _run(self, lines, *args):
        path = os.path.join(self.tmp, "capture.txt")
        with open(path, "w") as f:
            f.write("\n".join(lines) + "\n")
        out = io.StringIO()
        with mock.patch.object(sys, "argv", ["check_scene_routing.py", path, *args]), redirect_stdout(out):
            code = r.main()
        return code, out.getvalue()

    def test_pass_exits_zero(self):
        code, out = self._run(_link_capture("scene2"), "--scenario", "multiscene_link_scene2", "--require-link-data")
        self.assertEqual(code, 0)
        self.assertIn("PASSED: scene routing for multiscene_link_scene2", out)

    def test_failure_exits_one_with_failed_lines(self):
        code, out = self._run([_callback("scene1")], "--scenario", "multiscene_open")
        self.assertEqual(code, 1)
        self.assertIn("FAILED: Expected 1 scene2 callback(s), captured 0.", out)

    def test_missing_file_fails(self):
        out = io.StringIO()
        missing = os.path.join(self.tmp, "missing.txt")
        with mock.patch.object(sys, "argv", ["check_scene_routing.py", missing, "--scenario", "multiscene_open"]), \
                redirect_stdout(out):
            self.assertEqual(r.main(), 1)
        self.assertIn("FAILED: cannot read", out.getvalue())


if __name__ == "__main__":
    unittest.main()
