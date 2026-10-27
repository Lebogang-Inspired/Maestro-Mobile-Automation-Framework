# Test Design Guidance

How to design tests and decide on abstractions in this framework.

## What makes a good flow here

1. Represents a meaningful user journey, not a UI micro-interaction.
2. Has a descriptive `name:` and a unique TC id (TC001, TC002, ...).
3. Starts from a predictable state (`clearState: true`).
4. Uses verified, reliable selectors (resource-id first).
5. Contains meaningful `assertVisible` / `assertNotVisible` checks.
6. Is independently executable (no dependence on another test running first).
7. Produces a clear pass/fail and captures a screenshot at key points.
8. Is readable by another QA engineer with no framework-specific knowledge.

## When to create a subflow vs inline commands

Create a `subflows/` file when the same sequence is needed by **two or more**
tests AND encapsulating it improves maintainability (one place to fix a UI change).

Current subflows and why they exist:
- `authentication/login.yaml` — needed by TC002 and TC007 (checkout).
- `cart/add-product.yaml` — needed by TC005, TC006, TC007.
- `navigation/open-menu.yaml` — shared drawer entry point (TC008, extensible).
- `navigation/reset-state.yaml` — predictable-state helper.

Keep commands inline when they are used once or are specific to a single journey.
Do not create a subflow purely for "architecture"; a one-line indirection that
only has one caller adds cost without benefit.

## Negative tests

Assert the app's **real** behaviour. On this build the login screen only does
client-side validation (it accepts any well-formed submission without server
checks), so the genuine negative path is the empty-field validation error
("Username is required"), which is what TC003 asserts. Do not invent a
"wrong password rejection" the app does not actually perform.

## Data

- All credentials and checkout data come from `env`, never hard-coded in flows.
- Use synthetic data only. Never complete a real financial transaction.
