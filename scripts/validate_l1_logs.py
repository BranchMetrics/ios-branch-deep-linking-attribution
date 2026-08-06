"""
Layer 1 wire-validation for the Branch iOS SDK.

Parses branchlogs.txt (captured during the L1 instrumented run), extracts each
wire request, and asserts the SDK is emitting every device/SDK field that must
be on the wire. Presence-only check — a missing field fails the run; field
contents are not type-checked.

On success the validator prints the full payload for every captured request
plus a per-field check table so reviewers can verify what actually went over
the wire — no more silent passes when a value is wrong.

Source of truth for the parser: the Branch-TestBed AppDelegate registers a
`BranchAdvancedLogCallback`. For every outbound request the callback emits

    [BranchLog] Got <URL> Request: <jsonBody>

into ~/Documents/branchlogs.txt. The L1 instrumentation pulls that file out
of the simulator's app sandbox after the test run.

Endpoint contract: this file targets the 4.0.0-beta line, which does NOT
emit `/v1/install` or `/v1/open`. Install and open both land on
`/v3/events/open`, deep-link resolution on `/v3/deeplink`, and events on
`/v2/event/standard`. Only link creation still uses a v1 path (`/v1/url`).
The required-field lists below are derived from captured payloads on that
line, not from the v1 protocol master still speaks.

Platform parity note: this validator's required field set differs from the
Android sibling by design — iOS does not emit `wifi` or `ui_mode` on the
wire. The Android validator requires them, the iOS validator does not.
Cross-platform alignment of those device-context fields is tracked under
the v4 Conversion API workstream, not this gate.
"""

import json
import os
import re
import sys
from urllib.parse import urlparse


REQUEST_LINE_RE = re.compile(
    r"\[BranchLog\]\s+Got\s+(?P<url>https?://[^\s]+)\s+Request:\s*(?P<body>\{.*\})\s*$"
)

# The device/SDK context block every endpoint that carries it at the top
# level must have. `wifi` and `ui_mode` are intentionally absent — iOS does
# not emit them. See the v4 Conversion API parity tracker for the
# future-alignment plan.
REQUIRED_COMMON = [
    "branch_key",
    "sdk",
    "branch_sdk_request_timestamp",
    "branch_sdk_request_unique_id",
    "brand",
    "model",
    "os",
    "os_version",
    "country",
    "language",
    "local_ip",
    "screen_dpi",
    "screen_height",
    "screen_width",
    "connection_type",
    "hardware_id",
]

# `/v3/events/open` absorbed what master sent as `/v1/install`, so it also
# carries the install-identity pair that used to be install-only, plus the
# `anon_id` this line keys attribution on. Deliberately NOT required:
# `randomized_bundle_token` / `randomized_device_token`, which the backend
# only issues once a device is known — a first-ever install open has
# neither, so requiring them would fail a healthy fresh-install capture.
REQUIRED_OPEN_EXTRAS = ["anon_id", "first_install_time", "is_hardware_id_real"]

# `/v2/event/standard` does not extend REQUIRED_COMMON: it uses a different
# schema, so it gets its own complete list. Request identity stays at the
# top level; the device block moves under `user_data`, where `hardware_id`
# is spelled `idfv` and `sdk` splits into `sdk` + `sdk_version`. Everything
# else is REQUIRED_COMMON restated in that schema (lookup_field resolves
# both levels, so the nesting itself needs no special handling).
REQUIRED_V2_EVENT = [
    "branch_key",
    "name",
    "branch_sdk_request_timestamp",
    "branch_sdk_request_unique_id",
    "sdk",
    "sdk_version",
    "anon_id",
    "randomized_device_token",
    "idfv",
    "brand",
    "model",
    "os",
    "os_version",
    "country",
    "language",
    "local_ip",
    "screen_dpi",
    "screen_height",
    "screen_width",
    "connection_type",
]

# The full required list per endpoint. An endpoint absent from this table
# has no L1 contract yet; its payload is printed but nothing is asserted.
#
# `/v3/deeplink` shares the open contract because it IS the open payload:
# BNCRequestFactory.dataForDeepLinkWithURLString: copies
# dataForRequestOpenWithURLString: and adds `ios_app_link_url`. That extra
# key is NOT required — it is only set when the resolution was driven by a
# URL, and captured cold-resolution payloads do not carry it.
REQUIRED_PER_ENDPOINT = {
    "/v3/events/open": REQUIRED_COMMON + REQUIRED_OPEN_EXTRAS,
    "/v3/deeplink": REQUIRED_COMMON + REQUIRED_OPEN_EXTRAS,
    "/v2/event/standard": REQUIRED_V2_EVENT,
    "/v1/url": REQUIRED_COMMON,
}

# A session on this line always posts an open, so a capture without one is
# a broken capture, not a quiet pass. This replaces master's mandatory
# `/v1/install`, which this line never sends.
MANDATORY_ENDPOINT = "/v3/events/open"


def parse_branch_logs(file_path):
    """Walk branchlogs.txt and pull each `[BranchLog] Got <URL> Request: <body>`
    line. Returns list of {uri, url, request}, or None if the file is missing.
    """
    if not os.path.exists(file_path):
        print(f"Error: Log file not found at {file_path}")
        return None

    entries = []
    with open(file_path, "r", encoding="utf-8", errors="replace") as f:
        for line_no, raw in enumerate(f, start=1):
            line = raw.rstrip("\r\n")
            match = REQUEST_LINE_RE.search(line)
            if not match:
                continue

            url = match.group("url")
            body_str = match.group("body")

            try:
                request = json.loads(body_str)
            except json.JSONDecodeError as e:
                print(f"Warning: line {line_no}: failed to parse request JSON: {e}")
                continue

            try:
                path = urlparse(url).path or url
            except Exception:
                path = url

            entries.append({"uri": path, "url": url, "request": request})

    return entries


def lookup_field(request, field):
    """Return value at top-level, else under user_data (v2 shape)."""
    if field in request:
        return request[field]
    user_data = request.get("user_data")
    if isinstance(user_data, dict) and field in user_data:
        return user_data[field]
    return None


def is_present(value):
    """A field is considered present when it has a non-null, non-empty value."""
    if value is None:
        return False
    if isinstance(value, str) and value == "":
        return False
    return True


def validate_request(entry, idx, total):
    """Print the full payload + per-field table for one request. Return a
    list of error strings (empty when everything required is present).

    Required-field checks are keyed on the endpoint path, not on a `/v1/*`
    prefix: on this line the endpoints that carry attribution are v2 and v3,
    and prefix-scoping left all three of them unchecked. An endpoint with no
    entry in REQUIRED_PER_ENDPOINT still gets its payload dumped, and says
    so, so an uncontracted endpoint is visible rather than silent."""
    errors = []
    uri = entry["uri"]
    url = entry["url"]
    request = entry["request"]

    print()
    print("=" * 64)
    print(f"[{idx}/{total}] {uri} — POST {url}")
    print("=" * 64)

    if not isinstance(request, dict):
        errors.append(f"Request {idx} ({uri}): payload is not a JSON object")
        return errors

    print("Full payload:")
    print(json.dumps(request, indent=2, sort_keys=True))
    print()

    fields = REQUIRED_PER_ENDPOINT.get(uri)
    if fields is None:
        print("(No L1 field contract defined for this endpoint; payload printed only)")
        return errors

    print(f"Required fields ({len(fields)}):")
    for field in fields:
        value = lookup_field(request, field)
        present = is_present(value)
        marker = "✓" if present else "✗"
        if present:
            print(f"  {marker} {field:<35} {value}")
        else:
            print(f"  {marker} {field:<35} MISSING")
            errors.append(f"Request {idx} ({uri}): missing required field '{field}'")

    return errors


def validate_entries(entries):
    """Run validate_request on every entry plus the top-level
    open-must-be-present check. Returns aggregated errors."""
    errors = []

    if not entries:
        errors.append("No Branch SDK wire requests were captured in the logs.")
        return errors

    print(f"Captured {len(entries)} Branch wire requests. Validating...")

    found_paths = [e["uri"] for e in entries]
    if MANDATORY_ENDPOINT not in found_paths:
        errors.append(
            f"Mandatory endpoint '{MANDATORY_ENDPOINT}' was not captured."
        )

    if "/v3/deeplink" not in found_paths:
        print(
            "Note: '/v3/deeplink' not present in capture. Only emitted when a "
            "Branch link is resolved, which the L1 runner does not do; not "
            "enforced here."
        )

    for i, entry in enumerate(entries, start=1):
        errors.extend(validate_request(entry, i, len(entries)))

    return errors


def main():
    log_file_path = sys.argv[1] if len(sys.argv) > 1 else "branchlogs.txt"

    entries = parse_branch_logs(log_file_path)

    if entries is None:
        print("\n--- VALIDATION FAILED ---")
        print(f"FAILED: Log file not found at {log_file_path}")
        sys.exit(1)

    try:
        if os.path.getsize(log_file_path) == 0:
            print("\n--- VALIDATION FAILED ---")
            print("FAILED: Log file is empty; no Branch SDK wire requests were captured.")
            sys.exit(1)
    except OSError:
        pass

    errors = validate_entries(entries)

    if errors:
        print("\n--- VALIDATION FAILED ---")
        for err in errors:
            print(f"FAILED: {err}")
        sys.exit(1)

    print(f"\n--- VALIDATION PASSED ({len(entries)}/{len(entries)} requests valid) ---")
    sys.exit(0)


if __name__ == "__main__":
    main()
