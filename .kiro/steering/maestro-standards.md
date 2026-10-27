# Maestro Framework Standards

These standards apply to all automation work in this repository. They are
Maestro-native by design — do not introduce Appium/WebDriver/Selenium patterns.

## Architecture rules

- Tests are **YAML flows** only. No Page Object classes, no Java/TS runners, no
  Cucumber, no custom execution engine, no abstraction layers over simple commands.
- Compose repeated steps with native `runFlow` referencing files under `subflows/`.
- Pass data with `env` (`-e KEY=VALUE` on the CLI, `runFlow.env` between flows).
- Use Maestro JavaScript only when a native command genuinely cannot express it.

## Running the suite (critical)

- Flows live under `.maestro/flows/**`. The workspace config is `.maestro/config.yaml`.
- Run against the **workspace directory**: `maestro test .maestro` — NOT
  `.maestro/flows`. Maestro reads `config.yaml` from the directory you pass and
  uses its inclusion patterns for recursive discovery. Passing `.maestro/flows`
  directly yields "Top-level directories do not contain any Flows".
- Reusable subflows live in `subflows/` (outside `.maestro/`) so they are never
  collected as standalone tests.

## Selector rules

- Prefer Android resource-ids: `id: "com.saucelabs.mydemoapp.android:id/<name>"`.
- Use visible text (`text:`) when stable. Remember `text:` is full-string,
  case-insensitive **regex** — anchor with `$` to avoid prefix collisions
  (e.g. `"Sauce Labs Backpack$"` vs the coloured variants).
- Avoid coordinate taps. For repeated ids (product cards) use `index:` or a
  relative matcher (`below:`, `above:`).
- Never author selector text from a screenshot. Copy real values from
  `inspect_screen`. See `docs/application-discovery.md` for the verified map.

## Reliability rules

- Every test starts from a predictable state: `launchApp: { clearState: true }`
  or the `reset-state` subflow.
- Assert meaningfully at verification points; never suppress a failed assertion.
- Avoid fixed waits; rely on Maestro's implicit waiting and `assertVisible`.
- After each `inputText` on the checkout forms, `hideKeyboard`; the keyboard
  overlaps lower fields. Use `scrollUntilVisible` for off-screen fields.
- Never change an expected result just to make a test pass.

## Test metadata

- Each flow has a `name:` ("TCxxx - ...") and `tags:` including `smoke` or
  `regression` plus a feature tag (authentication, products, cart, checkout,
  navigation).
- Screenshots use descriptive, TC-prefixed names (e.g. `TC005-product-added-to-cart`).
