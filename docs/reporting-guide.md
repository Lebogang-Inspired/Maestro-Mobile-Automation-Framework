# Reporting & Evidence Guide

How evidence is produced, where it lives, and how to read it. All paths and
formats below are verified against Maestro 2.12.0.

## Formats Maestro supports (this version)

`maestro test --format <FORMAT>` where FORMAT is one of:
`JUNIT`, `HTML`, `HTML-DETAILED`, `NOOP` (default). Pair with `--output <file>`.

## The evidence bundle

`./scripts/run-with-evidence.sh [smoke|regression|all] [--no-video]` creates a
timestamped, self-contained bundle:

```
reports/<RUN_ID>/
├── junit/report.xml            # machine-readable results (counts, durations, tags)
├── html/report.html           # Maestro HTML-DETAILED report
├── screenshots/                # all takeScreenshot PNGs, TC-prefixed
├── videos/                     # MP4 recordings of priority journeys
├── debug/
│   └── raw/<timestamp>/<flow>/ # commands.json, manifest.json, logs/
└── execution-summary.md        # business-readable summary (generated from JUnit)
```

`<RUN_ID>` is a timestamp (e.g. `20261027-235851`); runs never overwrite each other.

## How each artifact is produced

| Artifact | Source |
|---|---|
| JUnit XML | `maestro test --format JUNIT --output junit/report.xml` |
| HTML report | a second `maestro test --format HTML-DETAILED` run (Maestro has no report-only mode) |
| Screenshots | `takeScreenshot:` steps in flows → captured under `--test-output-dir`, flattened into `screenshots/` |
| Videos | `maestro record --local <flow> <out.mp4>` for the priority journeys |
| Debug | `--test-output-dir` writes `commands.json` / `manifest.json` / `logs/` per flow |
| Business summary | `scripts/create-business-summary.sh` parses the JUnit XML — **counts are never hard-coded** |

## Reading the JUnit report

`<testsuite tests="N" failures="F" ...>` gives totals; each `<testcase>` carries
`name`, `time`, `status`, `file`, and a `tags` property. Example (real):

```xml
<testsuite name="Test Suite" device="Pixel_10_Pro" tests="8" failures="0" time="238.739" ...>
  <testcase name="TC007 - Checkout Journey" time="114.126" status="SUCCESS" .../>
</testsuite>
```

## Screenshots captured (by TC)

| TC | Screenshot name(s) |
|---|---|
| TC001 | `TC001-landing-screen` |
| TC002 | `TC002-authenticated` |
| TC003 | `TC003-validation-error` |
| TC004 | `TC004-product-details` |
| TC005 | `TC005-product-added-to-cart` |
| TC006 | `TC006-cart-after-removal` |
| TC007 | `TC007-01-cart` … `TC007-05-confirmation` (5 checkpoints) |
| TC008 | `TC008-01-webview`, `TC008-02-geolocation`, `TC008-03-back-to-catalog` |

## Failure evidence

On failure, Maestro still writes the per-flow `debug/` artifacts (commands,
manifest, device logcat, maestro.log) and any screenshots taken before the
failure. The script preserves Maestro's non-zero exit code — a failed run never
reports green.

## Integrity rules

- Counts in `execution-summary.md` come from the JUnit XML, not literals.
- A screenshot existing never counts as a pass; assertions determine status.
- Non-zero exit codes are preserved by every script.
