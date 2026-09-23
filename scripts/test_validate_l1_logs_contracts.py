"""Scenario contract tests for the iOS L1 wire validator, run against
scrubbed captures from the TestBed.

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

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, THIS_DIR)

import validate_l1_logs as v  # noqa: E402

FIXTURE_DIR = os.path.join(THIS_DIR, "fixtures")


def _validate(fixture_name, scenario):
    entries = v.parse_branch_logs(os.path.join(FIXTURE_DIR, fixture_name))
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


class HotHttpsForegroundContractTests(unittest.TestCase):
    """hot_https_foreground: one resolve, then exactly one open."""

    def test_the_hot_capture_passes(self):
        # Delivery delta of a Universal Link opened into a foregrounded TestBed.
        self.assertEqual(_validate("hot_https_foreground.txt", "hot_https_foreground"), [])

    def test_a_cold_capture_fails(self):
        # A cold launch carries an extra unattributed open the hot contract forbids.
        errors = _validate("cold_https.txt", "hot_https_foreground")
        self.assertEqual(len(errors), 1, errors)
        self.assertIn("captured 2", errors[0])


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

    def _main(self, post, pre):
        saved_argv = sys.argv
        sys.argv = [
            "validate_l1_logs.py", post, "--scenario", "hot_uriScheme", "--pre", pre
        ]
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
