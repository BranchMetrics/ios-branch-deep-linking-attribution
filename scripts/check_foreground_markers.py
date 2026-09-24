"""
Foreground receipt for hot_uriScheme and hot_https_foreground, read from TestBed
lifecycle markers.

One `/v3/events/open` on the delivery delta does not prove the app stayed
foreground: a transition whose foreground open was suppressed also sends one.
The TestBed writes `[TestBedLifecycle] <name>` lines into branchlogs.txt, and
this checker asserts the delivery reached a foregrounded app:

- the snapshot taken before delivery (--pre) holds at least one
  applicationDidBecomeActive, so markers are being written;
- the bytes appended after it hold exactly one delivery marker (openURL for
  hot_uriScheme, continueUserActivity for hot_https_foreground) and no
  applicationWillResignActive, applicationDidEnterBackground or
  applicationDidBecomeActive.

Usage:

    check_foreground_markers.py wire-hot_uriScheme.post.txt \
        --pre wire-hot_uriScheme.pre.txt --scenario hot_uriScheme
"""

import argparse
import os
import re
import sys
from collections import Counter

from validate_l1_logs import capture_delta

MARKER_RE = re.compile(rb"\[TestBedLifecycle\] (\w+)")

LIVENESS = "applicationDidBecomeActive"
# Logged by the TestBed delegate method, so it proves the method ran after
# delivery, not that the activity carried a Branch link; validate_l1_logs.py
# asserts that from the wire contract.
MARKER_FOR_SCENARIO = {
    "hot_uriScheme": "openURL",
    "hot_https_foreground": "continueUserActivity",
}
TRANSITIONS = (
    "applicationWillResignActive",
    "applicationDidEnterBackground",
    "applicationDidBecomeActive",
)


def count_markers(data):
    """Count each marker name in `data` (bytes)."""
    return Counter(name.decode("ascii") for name in MARKER_RE.findall(data))


def check_markers(pre_counts, delta_counts, delivery):
    """Return one error string per broken rule."""
    errors = []
    if pre_counts[LIVENESS] < 1:
        errors.append(
            f"Expected at least 1 '{LIVENESS}' marker before delivery, found 0; "
            "the TestBed is not writing markers."
        )
    if delta_counts[delivery] != 1:
        errors.append(
            f"Expected exactly 1 '{delivery}' marker after delivery, found {delta_counts[delivery]}."
        )
    for name in TRANSITIONS:
        if delta_counts[name]:
            errors.append(
                f"Expected 0 '{name}' markers after delivery, found {delta_counts[name]}; "
                "the app left the foreground."
            )
    return errors


def format_counts(label, counts, delivery):
    markers = (delivery,) + TRANSITIONS
    return f"{label}: " + " ".join(f"{name}={counts[name]}" for name in markers)


def main():
    parser = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    parser.add_argument("log_file", help="capture taken after delivery")
    parser.add_argument(
        "--pre",
        metavar="SNAPSHOT",
        required=True,
        help="copy of the capture taken before delivery",
    )
    parser.add_argument(
        "--scenario",
        choices=sorted(MARKER_FOR_SCENARIO),
        required=True,
        help="which scenario produced this capture; selects its delivery marker",
    )
    args = parser.parse_args()
    delivery = MARKER_FOR_SCENARIO[args.scenario]

    for path in (args.pre, args.log_file):
        if not os.path.exists(path):
            print(f"FAILED: Log file not found at {path}")
            sys.exit(1)
    try:
        delta = capture_delta(args.pre, args.log_file)
    except ValueError as e:
        print(f"FAILED: {e}")
        sys.exit(1)
    with open(args.pre, "rb") as f:
        pre_counts = count_markers(f.read())
    delta_counts = count_markers(delta)

    print(format_counts("pre", pre_counts, delivery))
    print(format_counts("delta", delta_counts, delivery))
    errors = check_markers(pre_counts, delta_counts, delivery)
    for error in errors:
        print(f"FAILED: {error}")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
