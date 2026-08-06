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

# Required on every captured /v1/* request. `wifi` and `ui_mode` are
# intentionally absent — iOS does not emit them. See the v4 Conversion API
# parity tracker for the future-alignment plan.
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

# Endpoint-specific additions on top of REQUIRED_COMMON.
REQUIRED_PER_ENDPOINT = {
    "/v1/install": ["is_hardware_id_real", "first_install_time"],
    "/v1/open": ["randomized_device_token"],
    "/v1/url": [],
}


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

    Required-field checks are scoped to `/v1/*` endpoints — that's the L1
    contract. Non-v1 endpoints (e.g. `/v2/event/*`) use a different schema
    (device fields under `user_data`, different identity fields) and are
    out of L1's enforcement scope; the validator still dumps their payload
    for visibility but does not fail the run."""
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

    if not uri.startswith("/v1/"):
        print(f"(Non-v1 endpoint; required-field checks skipped per L1 scope)")
        return errors

    fields = REQUIRED_COMMON + REQUIRED_PER_ENDPOINT.get(uri, [])
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
    /v1/install-must-be-present check. Returns aggregated errors."""
    errors = []

    if not entries:
        errors.append("No Branch SDK wire requests were captured in the logs.")
        return errors

    print(f"Captured {len(entries)} Branch wire requests. Validating...")

    found_paths = [e["uri"] for e in entries]
    if "/v1/install" not in found_paths:
        errors.append("Mandatory endpoint '/v1/install' was not captured.")

    if "/v1/open" not in found_paths:
        print(
            "Note: '/v1/open' not present in capture. Expected after a second "
            "app launch, but not enforced here."
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
