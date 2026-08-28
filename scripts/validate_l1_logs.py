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

Attribution levels: a large part of the device block is conditional on the
consumer-protection attribution level, so the contract is tiered and
resolved per request from that request's own `cpp_level`. Presence in every
captured sample is not sufficient evidence that a field is unconditional —
every sample we have shares one configuration.

Platform parity note: this validator's required field set differs from the
Android sibling by design — iOS does not emit `wifi` or `ui_mode` on the
wire. The Android validator requires them, the iOS validator does not.
Cross-platform alignment of those device-context fields is tracked under
the v4 Conversion API workstream, not this gate.
"""

import argparse
import json
import os
import re
import sys
from urllib.parse import urlparse


REQUEST_LINE_RE = re.compile(
    r"\[BranchLog\]\s+Got\s+(?P<url>https?://[^\s]+)\s+Request:\s*(?P<body>\{.*\})\s*$"
)

# The normalized capture entry. `parse_branch_logs` is the only
# platform-specific layer; everything downstream sees this shape, so the
# Android validator can feed the same checks from its own log format.
# `uri` is the URL path, `url` the full URL, `request` the decoded body.
CAPTURE_ENTRY_KEYS = ("uri", "url", "request")

# The device/SDK context block every endpoint that carries it at the top
# level must have, unconditionally. `wifi` and `ui_mode` are intentionally
# absent — iOS does not emit them. See the v4 Conversion API parity tracker
# for the future-alignment plan.
#
# Everything here is written outside every attribution gate in
# BNCRequestFactory: `branch_key` and the request-identity pair in
# addDefaultRequestDataToJSON:, `sdk` in addSDKVersionToJSON:, the rest
# after the attribution block closes in updateDeviceInfoToMutableDictionary:.
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
    "screen_dpi",
    "screen_height",
    "screen_width",
    "connection_type",
]

# Written inside `if (![self isAttributionLevelNone])`
# (BNCRequestFactory.m:747) — absent by design at attribution level None.
REQUIRED_COMMON_NOT_NONE = ["local_ip"]

# Written inside the nested Full-or-uninitialized branch
# (BNCRequestFactory.m:751-752) — absent at every level below Full.
REQUIRED_COMMON_FULL = ["hardware_id"]

# `/v3/events/open` absorbed what master sent as `/v1/install`, so it also
# carries the install-identity pair that used to be install-only, plus the
# `anon_id` this line keys attribution on. Both extras are attribution-gated
# too: `anon_id` sits in the :747 block, `first_install_time` in
# addTimestampsToJSON: which returns early at None, and
# `is_hardware_id_real` is set beside `hardware_id` in the Full branch.
#
# Deliberately NOT required: `randomized_bundle_token` /
# `randomized_device_token`, which the backend only issues once a device is
# known — a first-ever install open has neither, so requiring them would
# fail a healthy fresh-install capture.
REQUIRED_OPEN_EXTRAS_NOT_NONE = ["anon_id", "first_install_time"]
REQUIRED_OPEN_EXTRAS_FULL = ["is_hardware_id_real"]

# `/v2/event/standard` does not extend REQUIRED_COMMON: it uses a different
# schema, so it gets its own complete list. Request identity stays at the
# top level; the device block moves under `user_data`, where `hardware_id`
# is spelled `idfv` and `sdk` splits into `sdk` + `sdk_version`. Everything
# else is REQUIRED_COMMON restated in that schema (lookup_field resolves
# both levels, so the nesting itself needs no special handling).
#
# v2dictionary writes `anon_id` and `local_ip` unconditionally, so unlike
# the v1 shape they are not attribution-gated here. Only `idfv` is
# (BNCRequestFactory.m:688-690).
REQUIRED_V2_EVENT = [
    "branch_key",
    "name",
    "branch_sdk_request_timestamp",
    "branch_sdk_request_unique_id",
    "sdk",
    "sdk_version",
    "anon_id",
    "randomized_device_token",
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
REQUIRED_V2_EVENT_NOT_NONE = ["idfv"]

# The required fields per endpoint, split into three tiers because a large
# part of the device block is conditional on the consumer-protection
# attribution level, not unconditional:
#
#   always    — emitted at every attribution level
#   not_none  — emitted at every level except None
#   full      — emitted only at Full, or before a level was ever set
#
# The tier is resolved per request from that request's own `cpp_level`, so
# a privacy-scenario capture is validated against what the SDK is actually
# supposed to send at that level. Applying the flat list instead failed a
# level-None `/v3/deeplink` on five fields the SDK is correct to omit.
#
# An endpoint absent from this table has no L1 contract yet; its payload is
# printed but nothing is asserted.
#
# `/v3/deeplink` shares the open contract because it IS the open payload:
# BNCRequestFactory.dataForDeepLinkWithURLString: copies
# dataForRequestOpenWithURLString: and adds `ios_app_link_url`. That extra
# key is NOT required — it is only set when the resolution was driven by a
# URL, and captured cold-resolution payloads do not carry it.
REQUIRED_PER_ENDPOINT = {
    "/v3/events/open": {
        "always": REQUIRED_COMMON,
        "not_none": REQUIRED_COMMON_NOT_NONE + REQUIRED_OPEN_EXTRAS_NOT_NONE,
        "full": REQUIRED_COMMON_FULL + REQUIRED_OPEN_EXTRAS_FULL,
    },
    "/v3/deeplink": {
        "always": REQUIRED_COMMON,
        "not_none": REQUIRED_COMMON_NOT_NONE + REQUIRED_OPEN_EXTRAS_NOT_NONE,
        "full": REQUIRED_COMMON_FULL + REQUIRED_OPEN_EXTRAS_FULL,
    },
    "/v2/event/standard": {
        "always": REQUIRED_V2_EVENT,
        "not_none": REQUIRED_V2_EVENT_NOT_NONE,
        "full": [],
    },
    "/v1/url": {
        "always": REQUIRED_COMMON,
        "not_none": REQUIRED_COMMON_NOT_NONE,
        "full": REQUIRED_COMMON_FULL,
    },
}

# Wire spelling of the levels — Branch.m:92-95.
ATTRIBUTION_LEVEL_FULL = "FULL"
ATTRIBUTION_LEVEL_NONE = "NONE"

# What the wire must look like after a scenario ran. All endpoint names live
# here rather than in the checks, so the same checks serve Android's `/v1/*`
# capture and this line's `/v3/*` one.
#
#   counts  endpoint -> exact number of requests. 0 forbids the endpoint.
#           An endpoint absent from counts is unconstrained.
#   order   (earlier, later) pairs. Relative, not adjacency: a request
#           between the two does not violate it.
#   fields  endpoint -> field -> exact number of that endpoint's requests
#           carrying the field. Same counting as `counts`, one level down;
#           0 forbids. Presence only, never a value comparison — `is_present`
#           is the whole test, so this stays the layer it claims to be.
#           It exists because an endpoint count cannot see a request changing
#           character: on 4.0 and 6.0 the install is a `/v3/events/open` like
#           any other, and EMT-4027 shipped with nothing on the surface ever
#           being an install. Counts were identical throughout.
#
# `install` and `deeplink` are not test-plan scenarios — they are the runs
# the harness drives today. Plan scenarios use their plan ID (C1, W1, N4).
SCENARIO_CONTRACTS = {
    # N1 organic_open: a launch with no link. The test plan also asks that the
    # open carry no link data; that is a field-level assertion, and this layer
    # is bounded at counts and required-field presence, so N1 is not fully
    # covered here. The endpoint half is.
    "N1": {
        "counts": {"/v3/events/open": 1, "/v3/deeplink": 0},
        "order": (),
        "fields": {},
    },
    # N3 attribution_none: a link resolved while the consumer-protection level
    # is NONE. BNCServerRequestOperation drops every request at that level
    # except BranchRequestDeepLink, so the resolution goes out and the
    # attributed open does not. The test plan also asks that identifiers be
    # cleared, which is a field-level assertion this layer does not make.
    "N3": {
        "counts": {"/v3/deeplink": 1, "/v3/events/open": 0},
        "order": (),
        "fields": {},
    },
    # C1 cold_https: a Universal Link delivered into a freshly launched
    # process. Two opens is correct, not a duplicate: the launch fires one
    # carrying no link field, then the resolution's attributed open carries
    # `link_data`. Requiring one would fail a healthy SDK. The plan also asks
    # that the resolution carry the link; that is a field-level assertion this
    # layer does not make, as with N1 and N3.
    "C1": {
        "counts": {"/v3/deeplink": 1, "/v3/events/open": 2},
        "order": (("/v3/deeplink", "/v3/events/open"),),
        # Both opens carry the token: the app was already installed, so the
        # launch open has one and the attributed open has one. This is what
        # separates C1 from C3 -- the counts and order are identical.
        "fields": {"/v3/events/open": {"randomized_bundle_token": 2}},
    },
    # C3 cold_firstInstall: the same launch on a device with no prior install.
    # There is no install endpoint on this line -- install is decided client
    # side by randomizedBundleToken == nil and posts to /v3/events/open like
    # any other. So the install shows up as the one open of the two that
    # carries no token, and that count is the only wire signal separating this
    # scenario from C1.
    "C3": {
        "counts": {"/v3/deeplink": 1, "/v3/events/open": 2},
        "order": (("/v3/deeplink", "/v3/events/open"),),
        "fields": {"/v3/events/open": {"randomized_bundle_token": 1}},
    },
    "deeplink": {
        "counts": {"/v3/deeplink": 1},
        "order": (("/v3/deeplink", "/v3/events/open"),),
        "fields": {},
    },
}


class UnknownScenario(Exception):
    """Raised for a scenario name with no contract."""


def contract_for(scenario):
    """Return the contract for `scenario`, or raise UnknownScenario.

    A typo must fail loudly rather than validate against nothing."""
    try:
        return SCENARIO_CONTRACTS[scenario]
    except KeyError:
        known = ", ".join(sorted(SCENARIO_CONTRACTS))
        raise UnknownScenario(
            f"No contract for scenario '{scenario}'. Known scenarios: {known}"
        )


# Body field carrying the attempt number, added by
# `BNCServerInterface addRetryCount:toJSON:`. First attempt is 0.
RETRY_COUNT_FIELD = "retryNumber"


def collapse_retries(entries):
    """Drop retry attempts so a capture holds one entry per logical request.

    The SDK logs a line per attempt: `genericHTTPRequest` calls its retry
    handler, which re-runs `preparePostRequest`, and that is what writes the
    capture line. Counting attempts would fail an exact-count contract
    whenever the network is flaky, which is the opposite of what the counts
    are for. Entries without the field are kept — a capture from a platform
    that does not carry it is not silently emptied."""
    return [entry for entry in entries if not is_retry_attempt(entry)]


def is_retry_attempt(entry):
    """True for a request that is a repeat of an earlier attempt."""
    request = entry.get("request")
    if not isinstance(request, dict):
        return False
    attempt = request.get(RETRY_COUNT_FIELD)
    return isinstance(attempt, int) and not isinstance(attempt, bool) and attempt > 0


def occurs_after(uris, earlier, later):
    """True when some `later` request appears after some `earlier` one.

    Relative, not adjacency: unrelated traffic between the two does not
    violate it. Deliberately not "the first `later` follows the first
    `earlier`" — a launch open legitimately precedes a link resolution, so
    that reading would fail a correct capture.

    Fail-closed: if either endpoint is missing the order is not satisfied."""
    for index, uri in enumerate(uris):
        if uri == earlier and later in uris[index + 1:]:
            return True
    return False


def assert_contract(entries, contract):
    """Check a normalized capture against a scenario contract.

    Returns a list of error strings, empty when the capture satisfies it.
    Holds no endpoint name of its own: every value compared comes from the
    contract, so the same checks serve either platform's capture."""
    errors = []
    uris = [entry["uri"] for entry in entries]

    for endpoint, expected in sorted(contract["counts"].items()):
        actual = uris.count(endpoint)
        if actual == expected:
            continue
        if expected == 0:
            errors.append(
                f"'{endpoint}' must not be captured for this scenario, "
                f"but appeared {actual} time(s)."
            )
        else:
            errors.append(
                f"Expected {expected} '{endpoint}' request(s), captured {actual}."
            )

    for earlier, later in contract["order"]:
        if not occurs_after(uris, earlier, later):
            errors.append(f"Expected a '{later}' request after a '{earlier}' one.")

    for endpoint, fields in sorted(contract.get("fields", {}).items()):
        matching = [e for e in entries if e["uri"] == endpoint]
        for field, expected in sorted(fields.items()):
            actual = sum(
                1 for e in matching if is_present(lookup_field(e["request"], field))
            )
            if actual == expected:
                continue
            if expected == 0:
                errors.append(
                    f"No '{endpoint}' request may carry '{field}', "
                    f"but {actual} of {len(matching)} did."
                )
            else:
                errors.append(
                    f"Expected {expected} of the '{endpoint}' request(s) to carry "
                    f"'{field}', but {actual} of {len(matching)} did."
                )

    return errors


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

    return collapse_retries(entries)


def lookup_field(request, field):
    """Return value at top-level, else under user_data (v2 shape)."""
    if field in request:
        return request[field]
    user_data = request.get("user_data")
    if isinstance(user_data, dict) and field in user_data:
        return user_data[field]
    return None


def attribution_level(request):
    """Return this request's consumer-protection attribution level as it
    appears on the wire, or None when the payload does not carry one.

    `cpp_level` is only written once a level has been set
    (BNCRequestFactory.addConsumerProtectionAttributionLevel: guards on
    attributionLevelInitialized), so its absence is meaningful rather than
    missing data: it means the level was never initialized. It sits at the
    top level on the v1 shape and under `user_data` on the v2 shape, both
    of which lookup_field resolves.
    """
    value = lookup_field(request, "cpp_level")
    if not isinstance(value, str) or value == "":
        return None
    return value.upper()


def required_fields_for(uri, request):
    """Resolve the required-field list for one request, tiering the
    contract by that request's own attribution level. Returns None when the
    endpoint has no contract.

    An uninitialized level (no `cpp_level` on the wire) takes the same
    branch as Full in BNCRequestFactory.m:751-752, so it requires the
    hardware block exactly as Full does.
    """
    contract = REQUIRED_PER_ENDPOINT.get(uri)
    if contract is None:
        return None

    level = attribution_level(request)
    fields = list(contract["always"])
    if level != ATTRIBUTION_LEVEL_NONE:
        fields.extend(contract["not_none"])
    if level is None or level == ATTRIBUTION_LEVEL_FULL:
        fields.extend(contract["full"])
    return fields


def describe_attribution_level(level):
    """Human label for the check-table header, so a reviewer can see which
    tier was applied without cross-referencing the payload."""
    if level is None:
        return "uninitialized (no cpp_level) — hardware block required"
    if level == ATTRIBUTION_LEVEL_FULL:
        return "FULL — hardware block required"
    if level == ATTRIBUTION_LEVEL_NONE:
        return "NONE — device block not required"
    return f"{level} — hardware block not required"


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

    fields = required_fields_for(uri, request)
    if fields is None:
        print("(No L1 field contract defined for this endpoint; payload printed only)")
        return errors

    level = describe_attribution_level(attribution_level(request))
    print(f"Required fields ({len(fields)}) [attribution: {level}]:")
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


def validate_entries(entries, contract):
    """Check a capture against `contract` and validate every request's
    required fields. Returns aggregated errors.

    The contract carries what the scenario must have put on the wire —
    counts, forbidden endpoints and ordering. There is no global
    mandatory-endpoint rule: a scenario that requires an open says so."""
    errors = []

    if not entries:
        errors.append("No Branch SDK wire requests were captured in the logs.")
        return errors

    print(f"Captured {len(entries)} Branch wire requests. Validating...")

    errors.extend(assert_contract(entries, contract))

    for i, entry in enumerate(entries, start=1):
        errors.extend(validate_request(entry, i, len(entries)))

    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    parser.add_argument(
        "log_file",
        nargs="?",
        default="branchlogs.txt",
        help="capture to validate (default: branchlogs.txt)",
    )
    parser.add_argument(
        "--scenario",
        choices=sorted(SCENARIO_CONTRACTS),
        required=True,
        help="which scenario produced this capture; selects its contract",
    )
    args = parser.parse_args()
    log_file_path = args.log_file

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

    errors = validate_entries(entries, contract_for(args.scenario))

    if errors:
        print("\n--- VALIDATION FAILED ---")
        for err in errors:
            print(f"FAILED: {err}")
        sys.exit(1)

    print(f"\n--- VALIDATION PASSED ({len(entries)}/{len(entries)} requests valid) ---")
    sys.exit(0)


if __name__ == "__main__":
    main()
