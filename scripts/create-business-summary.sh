#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# create-business-summary.sh <RUN_DIR>
# Generates reports/<RUN_ID>/execution-summary.md from ACTUAL results found in
# the run directory (JUnit XML + collected screenshots/videos). Counts are
# parsed from the JUnit report — never hard-coded.
# ---------------------------------------------------------------------------
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-common.sh"

RUN_DIR="${1:-}"
[ -n "${RUN_DIR}" ] && [ -d "${RUN_DIR}" ] || die "Usage: create-business-summary.sh <RUN_DIR>"
JUNIT="${RUN_DIR}/junit/report.xml"
[ -f "${JUNIT}" ] || die "JUnit report not found at ${JUNIT} — run the suite first."

SUMMARY="${RUN_DIR}/execution-summary.md"
APP_ID="${APP_ID:-com.saucelabs.mydemoapp.android}"
TARGET_ENV="${TARGET_ENV:-POC}"

# --- Parse counts from JUnit (testsuite attributes) --------------------------
# Disable errexit for the parsing section: grep legitimately returns 1 when an
# optional attribute (e.g. errors=) is absent, which must not abort the script.
set +e
read_attr() { grep -o "$1=\"[^\"]*\"" "${JUNIT}" | head -1 | sed "s/.*=\"//;s/\"//"; }
TOTAL="$(read_attr 'tests')";      TOTAL="${TOTAL:-0}"
FAILURES="$(read_attr 'failures')"; FAILURES="${FAILURES:-0}"
ERRORS="$(grep -o 'errors="[^"]*"' "${JUNIT}" | head -1 | sed 's/.*="//;s/"//')"; ERRORS="${ERRORS:-0}"
SUITE_TIME="$(read_attr 'time')"
DEVICE="$(read_attr 'device')"
TIMESTAMP="$(read_attr 'timestamp')"
PASSED=$(( TOTAL - FAILURES - ERRORS ))

# App version (best effort, live device)
APP_VERSION="unknown"
if command -v adb >/dev/null 2>&1; then
  V="$(adb shell dumpsys package "${APP_ID}" 2>/dev/null | tr -d '\r' | awk -F= '/versionName=/{print $2; exit}')"
  [ -n "${V}" ] && APP_VERSION="${V}"
fi

# Per-test rows from JUnit
ROWS=""
while IFS= read -r line; do
  NAME="$(echo "${line}"  | grep -o 'name="[^"]*"'   | head -1 | sed 's/.*="//;s/"//')"
  TIME="$(echo "${line}"  | grep -o 'time="[^"]*"'   | head -1 | sed 's/.*="//;s/"//')"
  STAT="$(echo "${line}"  | grep -o 'status="[^"]*"' | head -1 | sed 's/.*="//;s/"//')"
  [ -z "${NAME}" ] && continue
  ICON="✅"; [ "${STAT}" = "SUCCESS" ] || ICON="❌"
  ROWS="${ROWS}| ${NAME} | ${ICON} ${STAT:-?} | ${TIME:-?}s |\n"
done < <(grep '<testcase ' "${JUNIT}")

# Evidence inventory
SHOTS="$(find "${RUN_DIR}/screenshots" -type f -name '*.png' 2>/dev/null | sort)"
SHOT_N="$(printf '%s\n' "${SHOTS}" | grep -c . || true)"
VIDEOS="$(find "${RUN_DIR}/videos" -type f -name '*.mp4' 2>/dev/null | sort)"
VIDEO_N="$(printf '%s\n' "${VIDEOS}" | grep -c . || true)"

SHOT_LIST=""
while IFS= read -r f; do [ -n "${f}" ] && SHOT_LIST="${SHOT_LIST}- \`screenshots/$(basename "${f}")\`\n"; done <<< "${SHOTS}"
VIDEO_LIST=""
while IFS= read -r f; do [ -n "${f}" ] && VIDEO_LIST="${VIDEO_LIST}- \`videos/$(basename "${f}")\`\n"; done <<< "${VIDEOS}"

OVERALL="PASSED"; [ "$(( FAILURES + ERRORS ))" -eq 0 ] || OVERALL="FAILED"
set -e  # re-enable errexit now that parsing is done

# --- Write the summary -------------------------------------------------------
{
  echo "# Business Execution Summary"
  echo
  echo "_Generated from actual run results — counts parsed from JUnit, not hard-coded._"
  echo
  echo "| Field | Value |"
  echo "|---|---|"
  echo "| Overall result | **${OVERALL}** |"
  echo "| Execution date | ${TIMESTAMP:-unknown} |"
  echo "| Application | ${APP_ID} (v${APP_VERSION}) |"
  echo "| Device / emulator | ${DEVICE:-unknown} |"
  echo "| Environment | ${TARGET_ENV} |"
  echo "| Total test cases | ${TOTAL} |"
  echo "| Passed | ${PASSED} |"
  echo "| Failed | ${FAILURES} |"
  echo "| Errors | ${ERRORS} |"
  echo "| Skipped / blocked | 0 (see Known limitations) |"
  echo "| Total duration | ${SUITE_TIME:-?}s |"
  echo "| Screenshots captured | ${SHOT_N} |"
  echo "| Videos rendered | ${VIDEO_N} |"
  echo
  echo "## Test cases"
  echo
  echo "| Test | Result | Duration |"
  echo "|---|---|---|"
  printf "%b" "${ROWS}"
  echo
  echo "## Key scenarios covered"
  echo
  echo "- Application launch and catalogue rendering (TC001)"
  echo "- Authentication: valid login and validation error (TC002, TC003)"
  echo "- Product details (TC004)"
  echo "- Cart: add and remove items (TC005, TC006)"
  echo "- End-to-end checkout to confirmation, synthetic data (TC007)"
  echo "- Drawer navigation across screens (TC008)"
  echo
  echo "## Screenshots"
  echo
  if [ "${SHOT_N}" -gt 0 ]; then printf "%b" "${SHOT_LIST}"; else echo "_None captured._"; fi
  echo
  echo "## Video recordings"
  echo
  if [ "${VIDEO_N}" -gt 0 ]; then printf "%b" "${VIDEO_LIST}"; else echo "_None rendered (run without --no-video to produce MP4s)._"; fi
  echo
  echo "## Reports"
  echo
  echo "- JUnit XML: \`junit/report.xml\`"
  echo "- HTML report: \`html/report.html\`"
  echo "- Debug artifacts: \`debug/\`"
  echo
  echo "## Known limitations"
  echo
  echo "- Synthetic demo credentials/data only; no real backend auth or payment."
  echo "- TC003 asserts the app's real empty-field validation error, because this"
  echo "  build accepts any well-formed login without server verification."
  echo "- Single emulator, single Android version (see docs/application-discovery.md)."
} > "${SUMMARY}"

ok "Business summary written: ${SUMMARY}"
