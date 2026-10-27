# Project Context

Fast orientation for anyone (human or agent) working in this repo.

## What this is

A Maestro-native mobile automation POC for business stakeholders. It automates
the installed **Sauce Labs My Demo App** on a local Android emulator, produces
HTML + JUnit reports, screenshots and MP4 evidence, and is ready for Azure DevOps.

## Verified environment (see docs/application-discovery.md for the full map)

- App under test: `com.saucelabs.mydemoapp.android` (My Demo App, versionName 2.3.0).
- Device: `emulator-5554`, AVD `Pixel_10_Pro`, Android 17 (API 37).
- Maestro CLI: 2.12.0. adb at `~/Library/Android/sdk/platform-tools/adb`.

## Layout

- `.maestro/config.yaml` — workspace config (run `maestro test .maestro`).
- `.maestro/flows/{smoke,regression,navigation}/**` — the 8 test cases (TC001-TC008).
- `subflows/{authentication,navigation,cart}/*.yaml` — reusable `runFlow` targets.
- `environments/` — `.env.example` + per-env files (real ones git-ignored).
- `scripts/` — check-environment, run-smoke, run-regression, run-with-evidence,
  create-business-summary, plus `lib-common.sh` (shared helpers).
- `reports/<RUN_ID>/` — generated evidence (git-ignored).
- `docs/` — architecture, discovery, setup, strategy, reporting, mcp, demo guides.
- `azure-pipelines.yml` — unvalidated CI template (needs an emulator-capable agent).

## Working agreements

- Follow `maestro-standards.md` and `test-design.md`.
- Use Maestro MCP (`list_devices` → `inspect_screen` → `run`) to discover real
  selectors before writing a flow. Surface the Maestro Viewer URL to the user.
- Committed tests must run from the terminal WITHOUT an AI agent — MCP is for
  development/debugging only, never a CI dependency.
- Do not deploy to Azure DevOps or change remote infrastructure without approval.
