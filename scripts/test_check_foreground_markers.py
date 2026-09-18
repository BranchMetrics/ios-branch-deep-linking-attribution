"""Tests for the hot_uriScheme foreground marker checker, run against marker
lines from TestBed captures.

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

import check_foreground_markers as c  # noqa: E402

FIXTURE_DIR = os.path.join(THIS_DIR, "fixtures")


def _fixture_bytes(name):
    with open(os.path.join(FIXTURE_DIR, name), "rb") as f:
        return f.read()


class ForegroundMarkerTests(unittest.TestCase):
    """hot_uriScheme reached a foregrounded app: one openURL, no transition."""

    extra_args = ()

    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp)

    def _write(self, name, data):
        path = os.path.join(self.tmp, name)
        with open(path, "wb") as f:
            f.write(data)
        return path

    def _main(self, pre_bytes, post_bytes):
        pre = self._write("pre.txt", pre_bytes)
        post = self._write("post.txt", post_bytes)
        saved_argv = sys.argv
        sys.argv = ["check_foreground_markers.py", post, "--pre", pre] + list(self.extra_args)
        out = io.StringIO()
        try:
            with redirect_stdout(out):
                with self.assertRaises(SystemExit) as ctx:
                    c.main()
        finally:
            sys.argv = saved_argv
        failed = [line for line in out.getvalue().splitlines() if line.startswith("FAILED:")]
        return ctx.exception.code, out.getvalue(), failed

    def test_the_hot_capture_passes(self):
        code, output, failed = self._main(
            _fixture_bytes("hot_uriScheme_markers.pre.txt"),
            _fixture_bytes("hot_uriScheme_markers.post.txt"),
        )
        self.assertEqual((code, failed), (0, []), output)

    def test_a_transition_fails(self):
        # Preferences in front, then the URL: the app resigns, backgrounds and reactivates.
        code, output, failed = self._main(
            _fixture_bytes("hot_uriScheme_markers_transition.pre.txt"),
            _fixture_bytes("hot_uriScheme_markers_transition.post.txt"),
        )
        self.assertEqual(code, 1)
        self.assertEqual(len(failed), 3, output)
        for name in c.TRANSITIONS:
            self.assertTrue(any(f"'{name}'" in line for line in failed), output)

    def test_a_snapshot_without_markers_fails_liveness(self):
        # Without it, a TestBed that writes no markers would pass on zero transitions.
        pre = b"placeholder log entry\n"
        pre_len = len(_fixture_bytes("hot_uriScheme_markers.pre.txt"))
        hot = _fixture_bytes("hot_uriScheme_markers.post.txt")[pre_len:]
        code, output, failed = self._main(pre, pre + hot)
        self.assertEqual(code, 1)
        self.assertEqual(len(failed), 1, output)
        self.assertIn("'applicationDidBecomeActive' marker before delivery, found 0", failed[0])

    def test_nothing_delivered_fails(self):
        pre = _fixture_bytes("hot_uriScheme_markers.pre.txt")
        code, output, failed = self._main(pre, pre)
        self.assertEqual(code, 1)
        self.assertEqual(failed, ["FAILED: Expected exactly 1 'openURL' marker after delivery, found 0."], output)


WARM_PRE = _fixture_bytes("warm_uriScheme_markers.pre.txt")
WARM_DELTA = _fixture_bytes("warm_uriScheme_markers.post.txt")[len(WARM_PRE):]


def _markers(*names):
    return b"".join(b"[TestBedLifecycle] " + name.encode() + b"\n" for name in names)


class WarmMarkerTests(unittest.TestCase):
    """warm_uriScheme reached a backgrounded app: backgrounded last before,
    one openURL and one reactivation after."""

    extra_args = ("--scenario", "warm_uriScheme")
    setUp = ForegroundMarkerTests.setUp
    _write = ForegroundMarkerTests._write
    _main = ForegroundMarkerTests._main

    def test_the_warm_marker_capture_passes(self):
        code, output, failed = self._main(WARM_PRE, WARM_PRE + WARM_DELTA)
        self.assertEqual((code, failed), (0, []), output)
        self.assertIn("pre last transition: applicationDidEnterBackground", output)

    def test_a_reactivation_before_delivery_fails(self):
        # Same two delta markers as the passing capture, reordered: the app woke on its
        # own and the URL arrived while already foreground, a hot delivery disguised as warm.
        reordered_delta = _markers("applicationDidBecomeActive", "openURL")
        code, output, failed = self._main(WARM_PRE, WARM_PRE + reordered_delta)
        self.assertEqual(code, 1)
        self.assertEqual(len(failed), 1, output)
        self.assertIn("Expected 'openURL' before 'applicationDidBecomeActive'", failed[0])

    def test_markers_out_of_order_fail(self):
        # Every pre marker present, but the app became active again after backgrounding.
        pre = _markers("applicationDidBecomeActive", "applicationDidEnterBackground", "applicationWillResignActive")
        code, output, failed = self._main(pre, pre + WARM_DELTA)
        self.assertEqual(code, 1)
        self.assertEqual(len(failed), 1, output)
        self.assertIn("'applicationDidEnterBackground'", failed[0])
        # Backgrounded last, but no liveness marker: the TestBed may not be writing markers.
        pre = _markers("applicationWillResignActive", "applicationDidEnterBackground")
        code, output, failed = self._main(pre, pre + WARM_DELTA)
        self.assertEqual(code, 1)
        self.assertEqual(len(failed), 1, output)
        self.assertIn("'applicationDidBecomeActive' marker before delivery, found 0", failed[0])

    def test_a_hot_delivery_fails_as_warm(self):
        code, output, failed = self._main(
            _fixture_bytes("hot_uriScheme_markers.pre.txt"),
            _fixture_bytes("hot_uriScheme_markers.post.txt"),
        )
        self.assertEqual(code, 1)
        self.assertEqual(len(failed), 2, output)
        self.assertIn("'applicationDidEnterBackground'", failed[0])
        self.assertIn("'applicationDidBecomeActive' marker after delivery, found 0", failed[1])

    def test_a_resign_during_delivery_fails(self):
        # The shape of a system prompt taking the foreground during delivery.
        code, output, failed = self._main(WARM_PRE, WARM_PRE + WARM_DELTA + _markers("applicationWillResignActive"))
        self.assertEqual(code, 1)
        self.assertEqual(len(failed), 1, output)
        self.assertIn("'applicationWillResignActive'", failed[0])


if __name__ == "__main__":
    unittest.main()
