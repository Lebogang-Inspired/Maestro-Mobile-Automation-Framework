#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run-smoke.sh
# Runs the smoke-tagged flows (TC001). Fast confidence check that the app and
# environment are healthy. Preserves Maestro's exit code.
# ---------------------------------------------------------------------------
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-common.sh"

ENV_FILE="$(resolve_env_file "${TARGET_ENV:-poc}")"
load_env "${ENV_FILE}"
build_maestro_env_args

log "Running SMOKE suite (tag: smoke)..."
# NB: pass the WORKSPACE dir (.maestro), not .maestro/flows — Maestro reads
# config.yaml from the directory passed and uses its inclusion patterns to
# discover flows recursively.
maestro test "${MAESTRO_ENV_ARGS[@]}" \
  --include-tags smoke \
  "${PROJECT_ROOT}/.maestro"
EXIT=$?

if [ "${EXIT}" -eq 0 ]; then ok "Smoke suite passed."; else err "Smoke suite failed (exit ${EXIT})."; fi
exit "${EXIT}"
