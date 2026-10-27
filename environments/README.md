# Environments

Configuration for running the suite against different targets. The framework is
designed to scale from the current POC to SIT and UAT.

## Files

| File | Tracked in git? | Purpose |
|---|---|---|
| `.env.example` | yes | Safe template with synthetic POC values. Never contains real secrets. |
| `.env.poc` | no (git-ignored) | Local POC config. Create by copying `.env.example`. |
| `.env.sit` | no | SIT config (supply SIT test accounts). |
| `.env.uat` | no | UAT config (supply UAT test accounts). |

## Quick setup

```bash
cp environments/.env.example environments/.env.poc
# edit environments/.env.poc if needed (the defaults work for the demo app)
```

## How an env file is selected

The scripts resolve the env file in this order:

1. `$MAESTRO_ENV_FILE` if set (explicit override).
2. `environments/.env.<TARGET_ENV>` (e.g. `.env.sit` when `TARGET_ENV=SIT`).
3. `environments/.env`.
4. `environments/.env.example` (last-resort fallback for a dry POC run).

Example: run against SIT

```bash
TARGET_ENV=SIT ./scripts/run-regression.sh
```

## Variables

See `.env.example` for the full list. Key ones:

- `APP_ID` — package under test.
- `TARGET_ENV` — POC | SIT | UAT.
- `TEST_USERNAME` / `TEST_PASSWORD` — login credentials.
- `SHIP_*` / `CARD_*` — synthetic checkout data (TC007).

## Security notes

- Real `.env.*` files are git-ignored (`.gitignore`); only `.env.example` is tracked.
- Scripts load env files with values hidden from logs; they are never echoed.
- For CI, supply these as Azure DevOps **secret** variables/variable groups, not
  as a committed file.
