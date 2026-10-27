# Kiro + Maestro MCP Guide

How to use Kiro with the Maestro MCP server to develop and debug tests. MCP is a
**development/debugging aid only** — committed tests run from the terminal (and in
CI) via the Maestro CLI with no AI agent involved.

## MCP setup

Configured in `.kiro/settings/mcp.json` (do not overwrite a working config):

```json
{
  "mcpServers": {
    "maestro": { "command": "maestro", "args": ["mcp"], "disabled": false, "autoApprove": [] }
  }
}
```

If the tools don't appear in Kiro, reconnect from the MCP Server view (or command
palette → "MCP"), or reload the window. Verify the server independently with:
`maestro mcp --no-viewer` (it should start and wait for messages).

## Tools used in this POC

| Tool | Use |
|---|---|
| `list_devices` | Find the emulator id (`emulator-5554`). |
| `inspect_screen` | Read the live view hierarchy to get **real** selectors. |
| `take_screenshot` | Visual confirmation while exploring. |
| `run` | Execute inline YAML / flow files to validate steps. |
| `cheat_sheet` | Confirm command syntax for the installed version. |
| `open_maestro_viewer` | Share the live Viewer URL with the user. |

## The development lifecycle (what we actually did)

1. `list_devices` → pick `emulator-5554`.
2. `inspect_screen` → read the hierarchy for the current screen.
3. Identify real elements (resource-ids, exact text). Never guess from a screenshot.
4. Author the YAML flow using those selectors.
5. Validate syntax + behaviour by running it via `run` (MCP) or the CLI.
6. Inspect the result; if an element isn't found, re-`inspect_screen`.
7. Fix unstable selectors (e.g. product cards reuse ids → use `index:`).
8. Re-run until green.
9. Save the verified flow under `.maestro/flows/...`.
10. Capture evidence (`takeScreenshot`, `maestro record --local`).
11. Update docs (`application-discovery.md`).

Real examples of findings that came from this loop:
- Product title TextView is not clickable → tap `productIV` by `index`.
- Checkout keyboard overlaps fields → `hideKeyboard` + `scrollUntilVisible`.
- Login accepts any well-formed submit → TC003 asserts the empty-field error.

## How another QA engineer uses Kiro here

- **Create a new test:** "Inspect the current screen and write a flow that …".
  Kiro uses `inspect_screen`, drafts YAML, runs it, and saves it on green.
- **Inspect selectors:** "What's the resource-id of the sort button?" → Kiro reads
  the hierarchy and tells you (`sortIV`).
- **Debug a failing test:** paste the failure; Kiro re-inspects the screen at the
  failing step and proposes a corrected selector.
- **Extend a journey:** "Add a step that changes quantity to 2 before checkout" →
  Kiro finds `plusIV`/`noTV` and edits the flow.
- **Run regression / generate evidence:** Kiro runs the scripts and points you to
  `reports/<RUN_ID>/`.

## Guardrails

- MCP must never be a CI dependency. CI runs `maestro test .maestro`.
- Always surface the Maestro Viewer URL before running flows for the user.
- Trust `inspect_screen` output over screenshots for selector text.
