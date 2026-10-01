"""
no_stickiness receipt, read from the TestBed's latestReferringParams reports.

The TestBed writes `[TestBedLifecycle] latestReferringParams <json>` on
applicationDidBecomeActive and after every wire response (logBranchRequest:).
Own single-line JSON parser: MARKER_RE (check_foreground_markers.py) captures
only `\\w+` and would drop this line's payload.

Reads two captures like the other L1 checkers: --pre is the snapshot taken
right before the return, log_file the full run. Verdict:

- non-vacuous: some report in --pre must carry this run's own
  `+clicked_branch_link: true` (the link actually resolved), else "link
  never resolved";
- clean return: at least one report must exist after the return (the bytes
  --pre gains in log_file), else "no report after return", and none of them
  may carry `~referring_link` or `+clicked_branch_link`, else the offending
  key names.

A latestReferringParams line whose JSON fails to parse is an error, never
silently treated as `{}`.

Usage:

    check_no_stickiness.py branchlogs.txt --pre branchlogs.pre.txt
"""

import argparse
import json
import os
import re
import sys

from validate_l1_logs import capture_delta

REPORT_RE = re.compile(rb"\[TestBedLifecycle\] latestReferringParams\s+(.+)$")

STICKY_KEYS = ("~referring_link", "+clicked_branch_link")


class ReportParseError(Exception):
    """A latestReferringParams line's JSON failed to parse."""


def parse_reports(data, label):
    """Return the JSON object from each latestReferringParams line in `data`.

    `label` identifies the capture in an error message (`--pre` vs the
    post-return delta). Raises ReportParseError on a line whose payload is
    not a valid JSON object -- that line is an error, never treated as {}."""
    reports = []
    for line_no, raw_line in enumerate(data.splitlines(), start=1):
        match = REPORT_RE.search(raw_line.rstrip(b"\r"))
        if not match:
            continue
        try:
            parsed = json.loads(match.group(1))
        except json.JSONDecodeError as e:
            raise ReportParseError(
                f"{label} line {line_no}: failed to parse latestReferringParams JSON: {e}"
            )
        if not isinstance(parsed, dict):
            raise ReportParseError(
                f"{label} line {line_no}: latestReferringParams payload is not a JSON object"
            )
        reports.append(parsed)
    return reports


def resolved_this_run(pre_reports):
    """True when some pre-return report carries this run's own resolved link."""
    return any(report.get("+clicked_branch_link") is True for report in pre_reports)


def offending_keys(delta_reports):
    """Sorted sticky keys present on any post-return report, empty when clean."""
    return sorted({key for report in delta_reports for key in STICKY_KEYS if key in report})


def main():
    parser = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    parser.add_argument("log_file", help="full capture, taken after the return")
    parser.add_argument(
        "--pre",
        metavar="SNAPSHOT",
        required=True,
        help="capture taken right before the return",
    )
    args = parser.parse_args()

    for path in (args.pre, args.log_file):
        if not os.path.exists(path):
            print(f"FAILED: Log file not found at {path}")
            sys.exit(1)

    with open(args.pre, "rb") as f:
        pre_bytes = f.read()
    try:
        delta = capture_delta(args.pre, args.log_file)
    except ValueError as e:
        print(f"FAILED: {e}")
        sys.exit(1)

    try:
        pre_reports = parse_reports(pre_bytes, "pre")
        delta_reports = parse_reports(delta, "post-return")
    except ReportParseError as e:
        print(f"FAILED: {e}")
        sys.exit(2)

    if not resolved_this_run(pre_reports):
        print("FAILED: link never resolved")
        sys.exit(1)

    if not delta_reports:
        print("FAILED: no report after return")
        sys.exit(1)

    offending = offending_keys(delta_reports)
    if offending:
        print(f"FAILED: stale key(s) after return: {', '.join(offending)}")
        sys.exit(1)

    print(
        f"PASSED: no_stickiness ({len(pre_reports)} report(s) before return, "
        f"{len(delta_reports)} after)"
    )
    sys.exit(0)


if __name__ == "__main__":
    main()
