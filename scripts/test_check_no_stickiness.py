"""Tests for the no_stickiness checker, run against latestReferringParams
fixture lines from TestBed captures.

Run from the repo root:

    python -m unittest discover -s scripts -p "test_*.py"
"""

import io
import os
import sys
import unittest
from contextlib import redirect_stdout

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, THIS_DIR)

import check_no_stickiness as c  # noqa: E402

FIXTURE_DIR = os.path.join(THIS_DIR, "fixtures")


def _fixture_path(name):
    return os.path.join(FIXTURE_DIR, name)


class NoStickinessTests(unittest.TestCase):
    """A return with no link keeps the accessor clean; a stale one does not."""

    def _main(self, pre_name, post_name):
        saved_argv = sys.argv
        sys.argv = [
            "check_no_stickiness.py",
            _fixture_path(post_name),
            "--pre",
            _fixture_path(pre_name),
        ]
        out = io.StringIO()
        try:
            with redirect_stdout(out):
                with self.assertRaises(SystemExit) as ctx:
                    c.main()
        finally:
            sys.argv = saved_argv
        return ctx.exception.code, out.getvalue()

    def test_clean_return_passes(self):
        """A resolved link, then a return with no sticky keys after it, passes."""
        code, output = self._main("no_stickiness_clean.pre.txt", "no_stickiness_clean.post.txt")
        self.assertEqual(code, 0, output)
        self.assertTrue(output.startswith("PASSED:"), output)

    def test_stale_keys_after_return_fail(self):
        """Catches a reverted clear: stale keys surviving the return fail, naming them."""
        code, output = self._main("no_stickiness_stale.pre.txt", "no_stickiness_stale.post.txt")
        self.assertEqual(code, 1, output)
        self.assertIn("FAILED: stale key(s) after return:", output)
        self.assertIn("~referring_link", output)
        self.assertIn("+clicked_branch_link", output)
        self.assertNotIn("bnctestbed.app.link", output)

    def test_link_never_resolved_fails(self):
        """A run whose link never resolved fails, never passes as a clean return."""
        code, output = self._main(
            "no_stickiness_unresolved.pre.txt", "no_stickiness_unresolved.post.txt"
        )
        self.assertEqual(code, 1, output)
        self.assertEqual(output.strip(), "FAILED: link never resolved")

    def test_no_report_after_return_fails(self):
        """No latestReferringParams line at all after the return fails, never passes."""
        code, output = self._main("no_stickiness_no_report.pre.txt", "no_stickiness_no_report.post.txt")
        self.assertEqual(code, 1, output)
        self.assertEqual(output.strip(), "FAILED: no report after return")

    def test_truncated_json_errors(self):
        """A truncated latestReferringParams line errors (exit 2), never treated as {}."""
        code, output = self._main("no_stickiness_truncated.pre.txt", "no_stickiness_truncated.post.txt")
        self.assertEqual(code, 2, output)
        self.assertIn("FAILED:", output)


if __name__ == "__main__":
    unittest.main()
