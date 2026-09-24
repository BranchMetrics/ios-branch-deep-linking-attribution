"""Tests for the hot_uriScheme and hot_https_foreground marker checker, run
against marker lines from TestBed captures.

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
        sys.argv = ["check_foreground_markers.py", post, "--pre", pre, "--scenario", "hot_uriScheme"]
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


class HotHttpsForegroundMarkerTests(unittest.TestCase):
    """hot_https_foreground reached a foregrounded app: one continueUserActivity, no transition."""

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
        sys.argv = [
            "check_foreground_markers.py", post, "--pre", pre, "--scenario", "hot_https_foreground"
        ]
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
            _fixture_bytes("hot_https_foreground_markers.pre.txt"),
            _fixture_bytes("hot_https_foreground_markers.post.txt"),
        )
        self.assertEqual((code, failed), (0, []), output)

    def test_a_safari_fallback_fails(self):
        # Catches the driver exiting green on a Safari fallback: 0 continueUserActivity,
        # the app backgrounds instead of receiving the link.
        code, output, failed = self._main(
            _fixture_bytes("hot_https_foreground_markers_safari_fallback.pre.txt"),
            _fixture_bytes("hot_https_foreground_markers_safari_fallback.post.txt"),
        )
        self.assertEqual(code, 1)
        self.assertTrue(
            any("'continueUserActivity'" in line and "found 0" in line for line in failed), output
        )
        self.assertTrue(any("'applicationWillResignActive'" in line for line in failed), output)


if __name__ == "__main__":
    unittest.main()
