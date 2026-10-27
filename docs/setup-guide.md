# Setup Guide

Get from a fresh clone to a passing test. Verified on macOS (darwin) with zsh,
Maestro 2.12.0, Android emulator `Pixel_10_Pro` (Android 17 / API 37).

## Prerequisites

| Tool | Version used | Notes |
|---|---|---|
| Java (JDK) | 17 (OpenJDK 17.0.21) | Required by Maestro. |
| Maestro CLI | 2.12.0 | `curl -fsSL https://get.maestro.mobile.dev \| bash` |
| Android Studio + SDK | any recent | Provides the emulator and `adb`. |
| adb (platform-tools) | 1.0.41 | Usually `~/Library/Android/sdk/platform-tools`. |
| Android emulator (AVD) | API 31+ | App targets API 31; API 37 verified. |
| Sauce Labs My Demo App | 2.3.0 | `com.saucelabs.mydemoapp.android`, preinstalled. |

## Steps

1. **Clone & enter the repo**
   ```bash
   git clone <repo-url>
   cd Maestro-Mobile-Automation-Framework
   ```

2. **Make sure `adb` is on PATH** (scripts auto-detect the default SDK path, but
   for manual commands):
   ```bash
   export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
   ```

3. **Start the Android emulator** from Android Studio → Device Manager, or:
   ```bash
   $HOME/Library/Android/sdk/emulator/emulator -list-avds
   $HOME/Library/Android/sdk/emulator/emulator -avd <AVD_NAME> &
   adb wait-for-device
   ```

4. **Verify the app is installed**
   ```bash
   adb shell pm list packages | grep saucelabs
   # expect: package:com.saucelabs.mydemoapp.android
   ```
   If missing, install its APK: `adb install -r <path-to>.apk`.

5. **Create your environment file**
   ```bash
   cp environments/.env.example environments/.env.poc
   ```
   The defaults use the app's own synthetic demo credentials and work as-is.

6. **Check the environment**
   ```bash
   ./scripts/check-environment.sh
   ```
   All lines should read `[ ok ]`.

7. **Run your first test (smoke)**
   ```bash
   ./scripts/run-smoke.sh
   ```

8. **Run regression**
   ```bash
   ./scripts/run-regression.sh
   ```

9. **Produce a full evidence bundle**
   ```bash
   ./scripts/run-with-evidence.sh all          # reports + screenshots + videos
   ./scripts/run-with-evidence.sh smoke        # fast: smoke only
   ./scripts/run-with-evidence.sh regression --no-video
   ```

10. **View results**
    ```bash
    open reports/<RUN_ID>/html/report.html
    open reports/<RUN_ID>/execution-summary.md
    open reports/<RUN_ID>/videos/
    ```

## Running Maestro directly (without the scripts)

```bash
# Run the whole suite against the WORKSPACE dir (.maestro), not .maestro/flows:
maestro test -e TEST_USERNAME=bod@example.com -e TEST_PASSWORD=10203040 .maestro

# A single flow:
maestro test .maestro/flows/smoke/TC001-launch-app.yaml
```

## Common pitfall

Running `maestro test .maestro/flows` fails with
"Top-level directories do not contain any Flows". Pass the workspace directory
`.maestro` so Maestro reads `config.yaml` and discovers flows recursively.
