#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Shared helpers for the Maestro POC scripts.
# Sourced by the other scripts. Not meant to be executed directly.
# ---------------------------------------------------------------------------
set -euo pipefail

# Resolve the project root from this library's own location, so scripts work
# regardless of the caller's current directory.
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${LIB_DIR}/.." && pwd)"
export PROJECT_ROOT

# Ensure Android platform-tools (adb) is on PATH if present in the default SDK.
if ! command -v adb >/dev/null 2>&1; then
  for candidate in "${HOME}/Library/Android/sdk/platform-tools" \
                   "${HOME}/Android/Sdk/platform-tools" \
                   "${ANDROID_HOME:-}/platform-tools" \
                   "${ANDROID_SDK_ROOT:-}/platform-tools"; do
    if [ -n "${candidate}" ] && [ -x "${candidate}/adb" ]; then
      export PATH="${candidate}:${PATH}"
      break
    fi
  done
fi

log()  { printf '\033[0;36m[maestro-poc]\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m[ ok ]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[warn]\033[0m %s\n' "$*"; }
err()  { printf '\033[0;31m[fail]\033[0m %s\n' "$*" >&2; }

die() { err "$*"; exit 1; }

# Load an env file (KEY=VALUE lines) and export the vars WITHOUT echoing values.
# Usage: load_env <path-to-env-file>
load_env() {
  local env_file="$1"
  [ -f "${env_file}" ] || die "Env file not found: ${env_file}"
  # shellcheck disable=SC1090
  set -a
  . "${env_file}"
  set +a
  log "Loaded environment from $(basename "${env_file}") (values hidden)"
}

# Build the -e KEY=VALUE arguments for `maestro test` from the loaded env vars.
# Only forwards the variables the flows actually reference. Prints nothing
# sensitive to stdout (the array is used directly by the caller).
build_maestro_env_args() {
  MAESTRO_ENV_ARGS=()
  local keys=(TEST_USERNAME TEST_PASSWORD INVALID_USERNAME INVALID_PASSWORD \
              SHIP_NAME SHIP_ADDRESS SHIP_CITY SHIP_ZIP SHIP_COUNTRY \
              CARD_NAME CARD_NUMBER CARD_EXPIRY CARD_CVV TARGET_ENV APP_ID)
  local k
  for k in "${keys[@]}"; do
    if [ -n "${!k:-}" ]; then
      MAESTRO_ENV_ARGS+=( -e "${k}=${!k}" )
    fi
  done
}

# A timestamped run id, e.g. 20261027-233145
run_id() { date +%Y%m%d-%H%M%S; }

# Resolve the env file to use. Order: $MAESTRO_ENV_FILE, environments/.env.<env>,
# environments/.env, environments/.env.example (last resort for a dry POC run).
resolve_env_file() {
  local target_env="${1:-poc}"
  local lower
  lower="$(printf '%s' "${target_env}" | tr '[:upper:]' '[:lower:]')"
  if [ -n "${MAESTRO_ENV_FILE:-}" ]; then echo "${MAESTRO_ENV_FILE}"; return; fi
  if [ -f "${PROJECT_ROOT}/environments/.env.${lower}" ]; then
    echo "${PROJECT_ROOT}/environments/.env.${lower}"; return; fi
  if [ -f "${PROJECT_ROOT}/environments/.env" ]; then
    echo "${PROJECT_ROOT}/environments/.env"; return; fi
  echo "${PROJECT_ROOT}/environments/.env.example"
}
