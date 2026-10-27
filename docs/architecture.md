# Architecture

A lightweight, Maestro-native architecture. No Appium, WebDriver, Selenium, Page
Objects, or custom runner — just YAML flows, subflow composition, env config, and
the Maestro CLI.

## Runtime flow

```mermaid
flowchart LR
    subgraph Dev["Development & Debugging (local only)"]
        Kiro["Kiro AI Agent"] -->|MCP tools| MCP["Maestro MCP Server"]
    end

    MCP --> CLI["Maestro CLI 2.12.0"]
    Scripts["scripts/*.sh"] --> CLI
    CI["Azure DevOps\n(azure-pipelines.yml)"] --> CLI

    CLI -->|drives| Emu["Android Emulator\n(emulator-5554)"]
    Emu --> App["Sauce Labs My Demo App\ncom.saucelabs.mydemoapp.android"]

    CLI --> Reports["Evidence\nJUnit · HTML · PNG · MP4"]
    Reports --> RepoReports["reports/<RUN_ID>/"]
```

## Composition model

```mermaid
flowchart TD
    Config[".maestro/config.yaml\n(inclusion patterns)"] --> Flows[".maestro/flows/**"]

    TC007["TC007 Checkout"] -->|runFlow| Login["subflows/authentication/login.yaml"]
    TC007 -->|runFlow| AddProduct["subflows/cart/add-product.yaml"]
    TC002["TC002 Valid Login"] -->|runFlow| Login
    TC005["TC005 Add to Cart"] -->|runFlow| AddProduct
    TC006["TC006 Remove from Cart"] -->|runFlow| AddProduct
    TC008["TC008 Navigation"] -->|runFlow| OpenMenu["subflows/navigation/open-menu.yaml"]

    Login -->|env| Creds["TEST_USERNAME / TEST_PASSWORD"]
```

## Key design decisions

| Decision | Why |
|---|---|
| YAML flows, no POM | Maestro's model; readable by any QA engineer, less code to maintain. |
| `runFlow` subflows | DRY for login / add-product / menu; one place to fix UI changes. |
| `env` for all data | No secrets in flows; same flows run across POC/SIT/UAT. |
| Run `maestro test .maestro` | Workspace `config.yaml` drives recursive discovery (verified requirement). |
| Subflows outside `.maestro/` | They are composition targets, never collected as standalone tests. |
| MCP only for dev/debug | CI runs the committed flows via the CLI with no agent dependency. |
| resource-id-first selectors | Stable across language/layout; see `application-discovery.md`. |

## Execution paths

- **Local dev:** Kiro + Maestro MCP to inspect screens and author/validate flows.
- **Local CLI:** `scripts/run-smoke.sh`, `run-regression.sh`, `run-with-evidence.sh`.
- **CI:** `azure-pipelines.yml` runs `maestro test .maestro` and publishes results
  (template; needs an emulator-capable agent).
