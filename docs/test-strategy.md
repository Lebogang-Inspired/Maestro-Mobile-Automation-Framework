# Test Strategy

## Scope

Automate the primary customer journeys of the Sauce Labs My Demo App to prove
AI-assisted, Maestro-native mobile automation is viable for the team. Eight test
cases across five feature areas, organised into smoke and regression suites.

## Test pyramid position

These are **end-to-end UI flows** on a real emulator — the top of the pyramid.
They are intentionally few and high-value. Unit/integration coverage is the app
team's responsibility; this suite validates user-facing journeys.

## Suites & tags

| Suite | Tag | Flows | Purpose |
|---|---|---|---|
| Smoke | `smoke` | TC001 | Fast health check: app launches, catalogue renders. |
| Regression | `regression` | TC002–TC008 | Full journey coverage before release. |

Feature tags: `authentication`, `products`, `cart`, `checkout`, `navigation`,
plus `negative` and `e2e` where relevant.

Run examples:
```bash
maestro test --include-tags smoke .maestro
maestro test --include-tags regression .maestro
maestro test --include-tags cart .maestro
maestro test --include-tags regression --exclude-tags e2e .maestro
```

## Test cases

| TC | Title | Feature | Key assertion |
|---|---|---|---|
| TC001 | Application Launch | launch | "Products" + product content visible |
| TC002 | Valid Login | authentication | Drawer shows "Log Out" after login |
| TC003 | Invalid Login (validation) | authentication | "Username is required" shown; stays on login |
| TC004 | Product Details | products | Title/price/colours/add-to-cart visible |
| TC005 | Add Product to Cart | cart | Cart badge = 1; "1 Items", "$ 29.99" |
| TC006 | Remove Product from Cart | cart | Item + badge gone |
| TC007 | Checkout Journey | checkout | "Checkout Complete" confirmation |
| TC008 | Application Navigation | navigation | Navigate screens & return to Catalog |

## Principles

- **Independence:** each test does its own `launchApp: { clearState: true }`.
- **Real selectors:** resource-id first, verified via Maestro MCP `inspect_screen`.
- **Meaningful assertions:** no screenshot-only "passes"; assertions gate success.
- **No fixed waits:** rely on Maestro's implicit waiting.
- **Honest negatives:** TC003 asserts the app's genuine validation behaviour
  (see docs/application-discovery.md — the login accepts any well-formed submit).
- **Synthetic data only:** no real accounts or payments.

## Entry / exit criteria

- **Entry:** emulator running, app installed, `check-environment.sh` all green.
- **Exit (POC pass):** ≥ 5 meaningful scenarios pass; JUnit + HTML generated;
  screenshots for key steps; ≥ 1 playable MP4; business summary matches results.

## Maintenance

- UI changes: re-inspect with Maestro MCP, update the selector in the single
  owning flow/subflow, re-run.
- New journeys: add a `TCxxx-*.yaml` under the right feature folder with proper
  `name:`/`tags:`; reuse subflows where it helps.
