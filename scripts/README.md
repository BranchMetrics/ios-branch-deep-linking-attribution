# L1 wire-validation scripts

`validate_l1_logs.py` is the Layer-1 PR gate that asserts the iOS SDK is
putting the right device/SDK fields on the wire. It is run by
`.github/workflows/layer1-logger-tests.yml` against a `branchlogs.txt`
produced by the L1 instrumented test, and can be run locally against any
captured log.

## Running locally

After capturing a `branchlogs.txt` (from a CI artifact, or by running
`scripts/run_l1_instrumented.sh` against a local simulator), point the
validator at it:

```bash
python3 scripts/validate_l1_logs.py path/to/branchlogs.txt
```

To run the validator's own test suite:

```bash
python3 -m unittest scripts.test_validate_l1_logs -v
```

The tests use fixtures in `scripts/fixtures/` and exercise: the happy
path, a missing-field failure, the v2-`user_data` nested shape (iOS
nests device fields under `user_data` on `/v2/event/*`), the
open-must-be-captured guard, the deep-link contract, and the
uncontracted-endpoint case.

## Endpoints on this line

The `4.0.0-beta` line does **not** emit `/v1/install` or `/v1/open`.
Install and open both post to `/v3/events/open`:

| what happens            | endpoint             |
| ----------------------- | -------------------- |
| install (fresh install) | `/v3/events/open`    |
| open (cold and warm)    | `/v3/events/open`    |
| deep link resolution    | `/v3/deeplink`       |
| event                   | `/v2/event/standard` |
| link creation           | `/v1/url`            |

`/v3/events/open` is mandatory: every session posts one, so a capture
without it is a broken capture and fails the run. `/v3/deeplink` is only
emitted when a Branch link is resolved, which the single-launch L1
runner does not do — its absence is a printed note, not a failure.

## What gets validated

Presence-only. A required field is either there (pass) or absent (fail).
No type checks, no value-format checks — those are intentionally left to
the backend ingestion gate.

The required field lists live at the top of `validate_l1_logs.py`:

- `REQUIRED_COMMON` — the device/SDK context block, required on every
  endpoint that carries it at the top level.
- `REQUIRED_OPEN_EXTRAS` — `anon_id`, `first_install_time` and
  `is_hardware_id_real`, on `/v3/events/open` and `/v3/deeplink`. The
  latter two used to be `/v1/install`-only; the open absorbed them.
  `randomized_device_token` / `randomized_bundle_token` are deliberately
  **not** required — a first-ever install open has neither.
- `REQUIRED_V2_EVENT` — the standalone list for `/v2/event/standard`,
  which does not extend `REQUIRED_COMMON`. Request identity stays at the
  top level; the device block moves under `user_data`, where
  `hardware_id` is spelled `idfv` and `sdk` splits into `sdk` +
  `sdk_version`.
- `REQUIRED_PER_ENDPOINT` — the full list per endpoint path.

Checks are keyed on the endpoint path, not on a `/v1/*` prefix. Prefix
scoping is what previously let `/v3/events/open`, `/v3/deeplink` and
`/v2/event/standard` — every endpoint carrying this line's attribution
traffic — pass without a single field being checked.

`/v3/deeplink` shares the open contract because it _is_ the open
payload: `BNCRequestFactory.dataForDeepLinkWithURLString:` copies
`dataForRequestOpenWithURLString:` and adds `ios_app_link_url`. That
extra key is not required — it is only set when the resolution was
driven by a URL.

An endpoint with no entry in `REQUIRED_PER_ENDPOINT` (e.g. `/v1/qr-code`,
`/v2/event/custom`) has its payload printed and is labelled as having no
contract. It does not fail the run, but it is not silent either.

Lookups tolerate `user_data` nesting so payloads using that shape are
still resolved correctly via the same code path.

## What gets printed on success

For every captured request: the full payload plus a per-field check
table showing the actual value that went over the wire. This is the
answer to the reviewer feedback on PR #1590 — silent passes are no
longer possible because every field's value is visible in the CI log.

## Adding a new required field

1. Confirm the field is present in **captured payloads**, on every
   sample of that endpoint. A field that is only sometimes there (the
   device tokens on a fresh-install open, `ios_app_link_url` on a cold
   deep-link resolution) will false-fail a healthy capture.
2. Add the field name to `REQUIRED_COMMON` (every endpoint carrying the
   top-level device block), `REQUIRED_OPEN_EXTRAS`, `REQUIRED_V2_EVENT`,
   or a new `REQUIRED_PER_ENDPOINT[<path>]` entry.
3. Add a fixture to `scripts/fixtures/` and a test in
   `scripts/test_validate_l1_logs.py` covering the missing-field case.

## Platform parity

The Android sibling validator lives in
`android-branch-deep-linking-attribution` and uses the same architecture
with two extra fields (`wifi` and `ui_mode`) that iOS does not emit on the
wire. Cross-platform alignment of those device-context fields is tracked
under the v4 Conversion API workstream, not this gate.
