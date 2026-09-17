"""
Foreground receipt for H2 hot_uriScheme, read from TestBed lifecycle markers.

One `/v3/events/open` on the delivery delta does not prove the app stayed
foreground: a transition whose foreground open was suppressed also sends one.
The TestBed writes `[TestBedLifecycle] <name>` lines into branchlogs.txt, and
this checker asserts the delivery reached a foregrounded app:

- the snapshot taken before delivery (--pre) holds at least one
  applicationDidBecomeActive, so markers are being written;
- the bytes appended after it hold exactly one openURL and no
  applicationWillResignActive, applicationDidEnterBackground or
  applicationDidBecomeActive.

With --scenario W2 it asserts the inverse, a delivery into a backgrounded app:

- the snapshot holds at least one applicationDidBecomeActive, and its last
  transition marker is applicationDidEnterBackground;
- the bytes appended after it hold exactly one openURL, exactly one
  applicationDidBecomeActive, and no applicationWillResignActive or
  applicationDidEnterBackground.

Usage:

    check_foreground_markers.py wire-h2.post.txt --pre wire-h2.pre.txt
    check_foreground_markers.py wire-w2.post.txt --pre wire-w2.pre.txt --scenario W2
"""

import argparse
import os
import re
import sys
from collections import Counter

from validate_l1_logs import capture_delta

MARKER_RE = re.compile(rb"\[TestBedLifecycle\] (\w+)")

LIVENESS = "applicationDidBecomeActive"
DELIVERY = "openURL"
TRANSITIONS = (
    "applicationWillResignActive",
    "applicationDidEnterBackground",
    "applicationDidBecomeActive",
)
MARKERS = (DELIVERY,) + TRANSITIONS


def count_markers(data):
    """Count each marker name in `data` (bytes)."""
    return Counter(name.decode("ascii") for name in MARKER_RE.findall(data))


def liveness_errors(pre_counts):
    """Return the error for a snapshot with no liveness marker, or none."""
    if pre_counts[LIVENESS] >= 1:
        return []
    return [
        f"Expected at least 1 '{LIVENESS}' marker before delivery, found 0; "
        "the TestBed is not writing markers."
    ]


def check_markers(pre_counts, delta_counts):
    """Return one error string per broken rule."""
    errors = liveness_errors(pre_counts)
    if delta_counts[DELIVERY] != 1:
        errors.append(
            f"Expected exactly 1 '{DELIVERY}' marker after delivery, found {delta_counts[DELIVERY]}."
        )
    for name in TRANSITIONS:
        if delta_counts[name]:
            errors.append(
                f"Expected 0 '{name}' markers after delivery, found {delta_counts[name]}; "
                "the app left the foreground."
            )
    return errors


BACKGROUND = "applicationDidEnterBackground"


def last_transition(data):
    """Return the last transition marker name in `data` (bytes), or None."""
    names = [name.decode("ascii") for name in MARKER_RE.findall(data)]
    transitions = [name for name in names if name in TRANSITIONS]
    return transitions[-1] if transitions else None


def check_warm_markers(pre_counts, pre_last, delta_counts):
    """Return one error string per broken W2 rule."""
    errors = liveness_errors(pre_counts)
    if pre_last != BACKGROUND:
        errors.append(
            f"Expected the last transition marker before delivery to be '{BACKGROUND}', "
            f"found {pre_last or 'none'}; the app was not backgrounded."
        )
    for name, expected in ((DELIVERY, 1), (LIVENESS, 1)):
        if delta_counts[name] != expected:
            errors.append(
                f"Expected exactly {expected} '{name}' marker after delivery, found {delta_counts[name]}."
            )
    for name in TRANSITIONS:
        if name != LIVENESS and delta_counts[name]:
            errors.append(
                f"Expected 0 '{name}' markers after delivery, found {delta_counts[name]}; "
                "the app left the foreground."
            )
    return errors


def format_counts(label, counts):
    return f"{label}: " + " ".join(f"{name}={counts[name]}" for name in MARKERS)


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
        choices=("H2", "W2"),
        default="H2",
        help="H2 asserts a foregrounded app (default), W2 a backgrounded one",
    )
    args = parser.parse_args()

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
        pre_bytes = f.read()
    pre_counts = count_markers(pre_bytes)
    delta_counts = count_markers(delta)

    print(format_counts("pre", pre_counts))
    print(format_counts("delta", delta_counts))
    if args.scenario == "W2":
        pre_last = last_transition(pre_bytes)
        print(f"pre last transition: {pre_last or 'none'}")
        errors = check_warm_markers(pre_counts, pre_last, delta_counts)
    else:
        errors = check_markers(pre_counts, delta_counts)
    for error in errors:
        print(f"FAILED: {error}")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
