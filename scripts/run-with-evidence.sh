#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run-with-evidence.sh
# Runs a suite and collects a complete, timestamped evidence bundle under
# reports/<RUN_ID>/ :
#   junit/report.xml        - machine-readable results
#   html/report.html        - Maestro HTML-DETAILED report
#   screenshots/            - all takeScreenshot PNGs (flattened, prefixed by TC)
#   videos/                 - MP4 recordings of selected journeys
#   debug/                  - per-flow commands.json / manifest.json / logs
#   execution-summary.md    - business-readable summary (generated from results)
#
# Usage:
#   ./scripts/run-with-evidence.sh [smoke|regression|all] [--no-video]
#
# Preserves the test exit code. Never overwrites a previous run (unique RUN_ID).
# ---------------------------------------------------------------------------
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-common.sh"

SUITE="${1:-all}"
RECORD_VIDEO=1
[ "${2:-}" = "--no-video" ] && RECORD_VIDEO=0

case "${SUITE}" in
  smoke)      TAG_ARGS=(--include-tags smoke) ;;
  regression) TAG_ARGS=(--include-tags regression) ;;
  all)        TAG_ARGS=() ;;
  *) die "Unknown suite '${SUITE}'. Use: smoke | regression | all" ;;
esac

ENV_FILE="$(resolve_env_file "${TARGET_ENV:-poc}")"
load_env "${ENV_FILE}"
build_maestro_env_args

RID="$(run_id)"
RUN_DIR="${PROJECT_ROOT}/reports/${RID}"
mkdir -p "${RUN_DIR}/junit" "${RUN_DIR}/html" "${RUN_DIR}/screenshots" \
         "${RUN_DIR}/videos" "${RUN_DIR}/debug"
log "Evidence run id: ${RID}"
log "Output: ${RUN_DIR}"

# --- 1. JUnit + per-flow artifacts (screenshots, commands, manifests) --------
# --test-output-dir keeps this run's raw artifacts isolated under debug/raw.
RAW_DIR="${RUN_DIR}/debug/raw"
log "Running ${SUITE} suite with JUnit + artifact capture..."
set +e
maestro test "${MAESTRO_ENV_ARGS[@]}" "${TAG_ARGS[@]}" \
  --format JUNIT --output "${RUN_DIR}/junit/report.xml" \
  --test-output-dir "${RAW_DIR}" \
  "${PROJECT_ROOT}/.maestro"
TEST_EXIT=$?
set -e
log "Test run finished (exit ${TEST_EXIT})."

# --- 2. HTML-DETAILED report -------------------------------------------------
# Maestro needs a separate invocation to emit HTML; reuse the same tags so the
# report matches. This re-runs the suite (Maestro has no "report-only" mode).
if [ "${GENERATE_HTML:-1}" = "1" ]; then
  log "Generating HTML-DETAILED report..."
  set +e
  maestro test "${MAESTRO_ENV_ARGS[@]}" "${TAG_ARGS[@]}" \
    --format HTML-DETAILED --output "${RUN_DIR}/html/report.html" \
    "${PROJECT_ROOT}/.maestro" >/dev/null 2>&1
  HTML_EXIT=$?
  set -e
  if [ -f "${RUN_DIR}/html/report.html" ]; then
    ok "HTML report: ${RUN_DIR}/html/report.html"
  else
    warn "HTML report not produced (exit ${HTML_EXIT})."
  fi
fi

# --- 3. Collect screenshots (flatten, keep TC-prefixed names) ----------------
log "Collecting screenshots..."
SHOT_COUNT=0
if [ -d "${RAW_DIR}" ]; then
  while IFS= read -r -d '' png; do
    cp "${png}" "${RUN_DIR}/screenshots/" 2>/dev/null && SHOT_COUNT=$((SHOT_COUNT+1))
  done < <(find "${RAW_DIR}" -type f -name '*.png' -print0)
fi
ok "Collected ${SHOT_COUNT} screenshot(s)."

# --- 4. Collect debug artifacts (commands/manifests/logs) --------------------
log "Collecting debug artifacts..."
if [ -d "${RAW_DIR}" ]; then
  find "${RAW_DIR}" -type f \( -name 'commands.json' -o -name 'manifest.json' -o -name '*.log' \) \
    -exec sh -c 'd="$1"; shift; for f; do rel=$(echo "$f" | sed "s#$d/##"); mkdir -p "$(dirname "$2/$rel")"; cp "$f" "$2/$rel"; done' \
    sh "${RAW_DIR}" {} "${RUN_DIR}/debug/collected" + 2>/dev/null || true
fi

# --- 5. Record MP4 videos of the business-priority journeys ------------------
if [ "${RECORD_VIDEO}" -eq 1 ]; then
  log "Rendering MP4 recordings (local)..."
  # Scope the recordings to the selected suite so a smoke run doesn't render
  # regression journeys (and vice versa).
  case "${SUITE}" in
    smoke)
      declare -a VIDEO_FLOWS=(
        "TC001-launch:.maestro/flows/smoke/TC001-launch-app.yaml"
      ) ;;
    *)  # regression | all : the business-priority journeys
      declare -a VIDEO_FLOWS=(
        "TC001-launch:.maestro/flows/smoke/TC001-launch-app.yaml"
        "TC002-valid-login:.maestro/flows/regression/authentication/TC002-valid-login.yaml"
        "TC005-add-to-cart:.maestro/flows/regression/cart/TC005-add-to-cart.yaml"
        "TC007-checkout:.maestro/flows/regression/checkout/TC007-checkout.yaml"
      ) ;;
  esac
  for entry in "${VIDEO_FLOWS[@]}"; do
    name="${entry%%:*}"; flow="${entry#*:}"
    log "  recording ${name}..."
    set +e
    maestro record --local "${MAESTRO_ENV_ARGS[@]}" \
      "${PROJECT_ROOT}/${flow}" "${RUN_DIR}/videos/${name}.mp4" >/dev/null 2>&1
    set -e
    if [ -f "${RUN_DIR}/videos/${name}.mp4" ]; then ok "  video: ${name}.mp4"; else warn "  video failed: ${name}"; fi
  done
else
  log "Video recording skipped (--no-video)."
fi

# --- 6. Business summary -----------------------------------------------------
TARGET_ENV="${TARGET_ENV:-POC}" APP_ID="${APP_ID:-com.saucelabs.mydemoapp.android}" \
  "${PROJECT_ROOT}/scripts/create-business-summary.sh" "${RUN_DIR}"

echo
log "Evidence bundle ready: ${RUN_DIR}"
log "Open the HTML report:  open '${RUN_DIR}/html/report.html'"
log "Open the summary:      open '${RUN_DIR}/execution-summary.md'"

exit "${TEST_EXIT}"
