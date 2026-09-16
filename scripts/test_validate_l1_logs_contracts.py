"""Scenario contract tests for the iOS L1 wire validator, run against
scrubbed captures from the TestBed.

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

import validate_l1_logs as v  # noqa: E402

FIXTURE_DIR = os.path.join(THIS_DIR, "fixtures")


def _validate(fixture_name, scenario):
    entries = v.parse_branch_logs(os.path.join(FIXTURE_DIR, fixture_name))
    with redirect_stdout(io.StringIO()):
        return v.validate_entries(entries, v.contract_for(scenario))


class H2ContractTests(unittest.TestCase):
    """H2 hot_uriScheme: one resolve, then exactly one open."""

    def test_the_hot_capture_passes(self):
        # Delivery delta of a scheme URL opened into a foregrounded TestBed.
        self.assertEqual(_validate("h2_hot_urischeme.txt", "H2"), [])

    def test_a_second_open_fails(self):
        # Cold link launch after reinstall: the chained open plus a plain one.
        errors = _validate("h2_duplicate_open.txt", "H2")
        self.assertEqual(len(errors), 1, errors)
        self.assertIn("captured 2", errors[0])


if __name__ == "__main__":
    unittest.main()
