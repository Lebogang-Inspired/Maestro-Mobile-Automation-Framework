#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run-regression.sh
# Runs the regression-tagged flows (TC002-TC008). Preserves Maestro's exit code.
# ---------------------------------------------------------------------------
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-common.sh"

ENV_FILE="$(resolve_env_file "${TARGET_ENV:-poc}")"
load_env "${ENV_FILE}"
build_maestro_env_args

log "Running REGRESSION suite (tag: regression)..."
maestro test "${MAESTRO_ENV_ARGS[@]}" \
  --include-tags regression \
  "${PROJECT_ROOT}/.maestro"
EXIT=$?

if [ "${EXIT}" -eq 0 ]; then ok "Regression suite passed."; else err "Regression suite failed (exit ${EXIT})."; fi
exit "${EXIT}"
