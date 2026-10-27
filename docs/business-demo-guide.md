# 5-Minute Business Demonstration Guide

A tight running order for showing the POC to stakeholders. Rehearse once; keep the
emulator visible on screen throughout.

## Before you start (2 min prep, off-camera)

```bash
# 1. Emulator running and app installed
./scripts/check-environment.sh            # all [ ok ]

# 2. Pre-generate a full evidence bundle so reports/videos are ready to show
./scripts/run-with-evidence.sh all        # ~5-6 min; do this BEFORE the meeting
```

Note the `reports/<RUN_ID>/` folder it prints — you'll open it live.

## The 5 minutes

| Time | Show | Say |
|---|---|---|
| 0:00–0:45 | `docs/architecture.md` Mermaid diagram | "Maestro-native: plain YAML flows drive a real emulator. No Appium, no heavy framework. Kiro + Maestro MCP help us author tests; the tests then run on their own in CI." |
| 0:45–1:45 | Kiro chat + Maestro Viewer (`http://127.0.0.1:...`) | "Kiro inspects the live screen, reads real UI ids, and writes the test for us." Ask Kiro to inspect the Products screen to show the loop. |
| 1:45–3:00 | A real test executing | Run `./scripts/run-smoke.sh` (fast) or replay `videos/TC007-checkout.mp4`. "This is the full checkout journey, start to confirmation, on the real app." |
| 3:00–3:45 | `reports/<RUN_ID>/html/report.html` | Open in a browser. "Every run produces this report — pass/fail, timing, per-step detail." |
| 3:45–4:15 | `reports/<RUN_ID>/screenshots/` | Flip through TC005/TC007 screenshots. "Visual evidence captured at each checkpoint." |
| 4:15–4:45 | `reports/<RUN_ID>/videos/TC007-checkout.mp4` | Play it. "Shareable MP4 of the exact run — great for stakeholders and bug reports." |
| 4:45–5:00 | `execution-summary.md` + next steps | "A plain-English summary generated from the real results. Next: more journeys, iOS, cloud devices, and the Azure DevOps pipeline." |

## Talking points (business value)

- **Speed:** tests are readable YAML; new journeys take minutes, not days.
- **AI-assisted:** Kiro + MCP remove the slowest part — finding selectors.
- **Evidence by default:** every run yields reports, screenshots and video.
- **CI-ready:** the same flows run unattended in Azure DevOps (no AI needed).
- **Low cost to maintain:** one place to fix a UI change (subflows + resource-ids).

## Do / don't

- DO start from a clean state (scripts do `clearState: true`).
- DO show a real, fresh run if time allows; the pre-generated bundle is the fallback.
- DON'T present an edited video as a test run.
- DON'T show any real credentials — the demo data is synthetic.

## Next steps slide (verbatim)

1. Expand journeys (sorting, quantities, multiple products, logout).
2. Add Android version / device coverage; then iOS.
3. Parallel + cloud device execution (Maestro Cloud).
4. Wire the Azure DevOps pipeline to a self-hosted emulator agent.
5. Publish trends/results into Azure DevOps dashboards.
