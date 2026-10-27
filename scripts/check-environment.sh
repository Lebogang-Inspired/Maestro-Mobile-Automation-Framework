#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# check-environment.sh
# Verifies the local machine can run the Maestro POC: Java, Maestro CLI, adb,
# a connected emulator, the installed app, required runtime variables and that
# the reports directory is writable. Exits non-zero on the first hard failure.
# ---------------------------------------------------------------------------
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-common.sh"

APP_ID="${APP_ID:-com.saucelabs.mydemoapp.android}"
FAILED=0

log "Checking prerequisites for the Maestro POC..."

# --- Java ---
if command -v java >/dev/null 2>&1; then
  ok "Java present: $(java -version 2>&1 | head -1)"
else
  err "Java not found on PATH (required by Maestro)."; FAILED=1
fi

# --- Maestro CLI ---
if command -v maestro >/dev/null 2>&1; then
  ok "Maestro CLI present: $(maestro --version 2>/dev/null)"
else
  err "Maestro CLI not found. Install: curl -fsSL https://get.maestro.mobile.dev | bash"
  FAILED=1
fi

# --- adb ---
if command -v adb >/dev/null 2>&1; then
  ok "adb present: $(adb --version 2>/dev/null | head -1)"
else
  err "adb not found. Add Android platform-tools to PATH."; FAILED=1
fi

# --- Connected emulator/device ---
DEVICE_COUNT=0
if command -v adb >/dev/null 2>&1; then
  DEVICE_COUNT="$(adb devices | awk 'NR>1 && $2=="device"' | wc -l | tr -d ' ')"
  if [ "${DEVICE_COUNT}" -ge 1 ]; then
    ok "Connected device(s): ${DEVICE_COUNT}"
    adb devices -l | awk 'NR>1 && $0!=""{print "       - "$0}'
  else
    err "No running emulator/device. Start one in Android Studio (Device Manager)."
    FAILED=1
  fi
fi

# --- App installed ---
if command -v adb >/dev/null 2>&1 && [ "${DEVICE_COUNT}" -ge 1 ]; then
  if adb shell pm list packages 2>/dev/null | tr -d '\r' | grep -q "package:${APP_ID}"; then
    VERSION="$(adb shell dumpsys package "${APP_ID}" 2>/dev/null | tr -d '\r' | awk -F= '/versionName=/{print $2; exit}')"
    ok "App installed: ${APP_ID} (versionName=${VERSION:-unknown})"
  else
    err "App '${APP_ID}' is not installed on the device."
    FAILED=1
  fi
fi

# --- Runtime variables (presence only, values never printed) ---
ENV_FILE="$(resolve_env_file "${TARGET_ENV:-poc}")"
if [ -f "${ENV_FILE}" ]; then
  ok "Env file available: $(basename "${ENV_FILE}")"
  load_env "${ENV_FILE}" >/dev/null
  for v in TEST_USERNAME TEST_PASSWORD; do
    if [ -n "${!v:-}" ]; then ok "Variable ${v} is set"; else warn "Variable ${v} is not set"; fi
  done
else
  warn "No env file found; copy environments/.env.example to environments/.env.poc"
fi

# --- reports/ writable ---
REPORTS_DIR="${PROJECT_ROOT}/reports"
mkdir -p "${REPORTS_DIR}" 2>/dev/null || true
if [ -w "${REPORTS_DIR}" ]; then
  ok "Reports directory writable: ${REPORTS_DIR}"
else
  err "Reports directory not writable: ${REPORTS_DIR}"; FAILED=1
fi

echo
if [ "${FAILED}" -eq 0 ]; then
  ok "Environment looks good. You can run ./scripts/run-smoke.sh"
  exit 0
else
  die "One or more prerequisites failed. Fix the items marked [fail] above."
fi
