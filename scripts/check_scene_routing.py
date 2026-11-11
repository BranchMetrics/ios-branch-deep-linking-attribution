#!/usr/bin/env python3
"""Checks which scene's deep link callback received each result in a multi-scene capture.

iOSReleaseTest writes every scene callback to branchlogs.txt as

    [SceneCallback] scene=<name> params=<json>

and a callback error as `[SceneCallbackError] scene=<name> error=<description>`. When the UI test
asks for a link to be delivered to one scene, the app writes

    [TestHook] delivering -testSceneLinkURL to <name>

before delivering it. This script checks those lines against the scenario's routing contract:
how many callbacks each scene received, and, for a link scenario, that the link was delivered to
the expected scene and that only that scene's callback fired after it.

Usage:

    python3 scripts/check_scene_routing.py <capture> --scenario <name> [--require-link-data]

--require-link-data also requires the callback after the delivery to carry
`+clicked_branch_link: true`, so a fixture link that no longer resolves fails instead of passing
on counts alone.

Exits 0 on success and 1 on failure, printing one `FAILED:` line per error.
"""

import argparse
import json
import re
import sys

CALLBACK_RE = re.compile(r"\[SceneCallback\] scene=(?P<scene>\S+) params=(?P<params>\{.*\})\s*$")
CALLBACK_ERROR_RE = re.compile(r"\[SceneCallbackError\] scene=(?P<scene>\S+) error=(?P<error>.*)$")
DELIVERY_RE = re.compile(r"\[TestHook\] delivering -testSceneLinkURL to (?P<scene>\S+)\s*$")

# callbacks: exact number of callbacks each scene receives over the whole capture.
# link_scene: scene the link is delivered to, or None when the scenario delivers no link.
ROUTING_CONTRACTS = {
    # Scene 1's no-link lookup, then Scene 2's nil-options lookup.
    "multiscene_open": {"callbacks": {"scene1": 1, "scene2": 1}, "link_scene": None},
    # multiscene_open, then the link's result on Scene 2 only.
    "multiscene_link_scene2": {"callbacks": {"scene1": 1, "scene2": 2}, "link_scene": "scene2"},
    # multiscene_open, then the link's result on Scene 1 only.
    "multiscene_link_scene1": {"callbacks": {"scene1": 2, "scene2": 1}, "link_scene": "scene1"},
    # multiscene_open, then a background and foreground, which fires no callback.
    "multiscene_foreground": {"callbacks": {"scene1": 1, "scene2": 1}, "link_scene": None},
}


def parse_events(lines):
    """Returns the routing events in lines, in order.

    Each event is a dict with `kind` ("callback", "error" or "delivery") and `scene`. A callback
    also has `params`, the parsed dict, or None when its JSON does not parse. An error also has
    `error`."""
    events = []
    for line in lines:
        match = CALLBACK_RE.search(line)
        if match:
            try:
                params = json.loads(match.group("params"))
            except ValueError:
                params = None
            events.append({"kind": "callback", "scene": match.group("scene"), "params": params})
            continue
        match = CALLBACK_ERROR_RE.search(line)
        if match:
            events.append({"kind": "error", "scene": match.group("scene"), "error": match.group("error").strip()})
            continue
        match = DELIVERY_RE.search(line)
        if match:
            events.append({"kind": "delivery", "scene": match.group("scene")})
    return events


def check_routing(events, contract, require_link_data=False):
    """Returns a list of error strings, empty when events satisfy contract.

    events: output of parse_events.
    contract: an entry of ROUTING_CONTRACTS.
    require_link_data: also require the callback after the delivery to carry
        `+clicked_branch_link: true`."""
    errors = []
    callbacks = [e for e in events if e["kind"] == "callback"]

    for event in events:
        if event["kind"] == "error":
            errors.append(f"{event['scene']} callback received an error: {event['error']}")
    for event in callbacks:
        if event["params"] is None:
            errors.append(f"{event['scene']} callback params are not valid JSON.")

    expected = contract["callbacks"]
    for scene in sorted(set(expected) | {e["scene"] for e in callbacks}):
        actual = sum(1 for e in callbacks if e["scene"] == scene)
        want = expected.get(scene, 0)
        if actual != want:
            errors.append(f"Expected {want} {scene} callback(s), captured {actual}.")

    deliveries = [i for i, e in enumerate(events) if e["kind"] == "delivery"]
    link_scene = contract["link_scene"]
    if link_scene is None:
        if deliveries:
            errors.append("A link was delivered, but this scenario delivers none.")
        return errors

    if len(deliveries) != 1:
        errors.append(f"Expected 1 link delivery, captured {len(deliveries)}.")
        return errors

    delivery = events[deliveries[0]]
    if delivery["scene"] != link_scene:
        errors.append(f"The link was delivered to {delivery['scene']}, expected {link_scene}.")

    after = [e for e in events[deliveries[0] + 1:] if e["kind"] == "callback"]
    for event in after:
        if event["scene"] != link_scene:
            errors.append(f"{event['scene']} callback fired for the link delivered to {link_scene}.")
    on_target = [e for e in after if e["scene"] == link_scene]
    if len(on_target) != 1:
        errors.append(f"Expected 1 {link_scene} callback after the link delivery, captured {len(on_target)}.")
    elif require_link_data:
        params = on_target[0]["params"] or {}
        if params.get("+clicked_branch_link") is not True:
            errors.append(
                f"The {link_scene} callback for the link does not carry +clicked_branch_link: true; "
                "the fixture link may no longer resolve."
            )

    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("log_file", help="branchlogs.txt capture from iOSReleaseTest")
    parser.add_argument("--scenario", choices=sorted(ROUTING_CONTRACTS), required=True)
    parser.add_argument(
        "--require-link-data",
        action="store_true",
        help="require the link's callback to carry +clicked_branch_link: true",
    )
    args = parser.parse_args()

    try:
        with open(args.log_file, encoding="utf-8", errors="replace") as f:
            lines = f.read().splitlines()
    except OSError as e:
        print(f"FAILED: cannot read {args.log_file}: {e}")
        return 1

    events = parse_events(lines)
    for event in events:
        if event["kind"] == "callback":
            clicked = (event["params"] or {}).get("+clicked_branch_link")
            print(f"callback: {event['scene']} +clicked_branch_link={clicked}")
        elif event["kind"] == "delivery":
            print(f"delivery: {event['scene']}")

    errors = check_routing(events, ROUTING_CONTRACTS[args.scenario], args.require_link_data)
    if errors:
        for error in errors:
            print(f"FAILED: {error}")
        return 1
    print(f"PASSED: scene routing for {args.scenario}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
