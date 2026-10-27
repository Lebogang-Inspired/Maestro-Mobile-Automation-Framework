# Application Discovery & Analysis

> Phase 1 output. Every fact below was observed live on the running emulator via
> Maestro MCP (`list_devices`, `inspect_screen`, `run`) and ADB. Nothing here is
> assumed or copied from an internet example.

## Environment

| Item | Observed value | Source |
|---|---|---|
| Device ID | `emulator-5554` | `maestro list_devices`, `adb devices -l` |
| AVD name | `Pixel_10_Pro` | `adb emu avd name` |
| Platform | Android | `list_devices` |
| Android release | 17 | `getprop ro.build.version.release` |
| API level (SDK) | 37 | `getprop ro.build.version.sdk` |
| Model | `sdk_gphone64_arm64` | `getprop ro.product.model` |
| Maestro CLI | 2.12.0 | `maestro --version` |
| ADB path | `~/Library/Android/sdk/platform-tools/adb` | filesystem |

## Application under test

| Item | Observed value | Source |
|---|---|---|
| Variant | Sauce Labs **My Demo App** (not the SwagLabs/Sample app) | `inspect_screen` resource-ids |
| Application ID (APP_ID) | `com.saucelabs.mydemoapp.android` | `pm list packages`, hierarchy rids |
| Launch activity | `com.saucelabs.mydemoapp.android.view.activities.MainActivity` | `dumpsys window` |
| versionName | `2.3.0` | `dumpsys package` |
| versionCode | `27` | `dumpsys package` |
| minSdk / targetSdk | 21 / 31 | `dumpsys package` |

## Identified screens & verified selectors

All selectors are Android resource-ids unless noted. Prefix every id with
`com.saucelabs.mydemoapp.android:id/`. These were confirmed by driving the app.

### Global header (present on catalog/cart screens)
| Element | Selector | Notes |
|---|---|---|
| Open nav drawer | `menuIV` | content-desc "View menu" |
| Sort products | `sortIV` | catalog only |
| Open cart | `cartRL` | tap target; badge count in `cartTV` |
| Cart item count | `cartTV` | text is the number of items |

### Navigation drawer (`menuRV`)
Menu items, each a `itemTV` TextView matched by its text:
`Catalog`, `WebView`, `QR Code Scanner`, `Geo Location`, `Drawing`, `About`,
`Reset App State`, `FingerPrint`, `Virtual USB`, `Crash app (debug)`, `Log In`.
After logging in, the `Log In` item becomes `Log Out`.

### Products / Catalog (landing screen)
| Element | Selector | Notes |
|---|---|---|
| Screen title | `productTV` (text "Products") | |
| Product list | `productRV` (RecyclerView), inside scrollable `scrollView` | |
| Product image | `productIV` (clickable) | **repeats per card** — tap by `index` |
| Product title | `titleTV` | e.g. "Sauce Labs Backpack" |
| Product price | `priceTV` | "$ 29.99" (identical across cards) |
| Rating stars | `start1IV`..`start5IV` | repeats per card |

> **Observed quirk:** the product `titleTV` is **not** the clickable target;
> tapping the title text does not navigate. The clickable element is the card
> `productIV`. Open the first product with `tapOn: { id: productIV, index: 0 }`.

### Login screen (drawer → "Log In")
| Element | Selector | Notes |
|---|---|---|
| Title | `loginTV` (text "Login") | |
| Username field | `nameET` (EditText) | |
| Password field | `passwordET` (EditText) | |
| Login button | `loginBtn` (text "Login") | |

**Credentials shown on-screen by the app itself (synthetic test data):**

| Username | Password | Meaning |
|---|---|---|
| `bod@example.com` | `10203040` | Standard valid user |
| `alice@example.com` | `10203040` | Locked-out user (`(locked out)` suffix on screen) |
| `visual@example.com` | `10203040` | Visual-testing user |

Invalid-login error text is rendered under the fields when bad credentials are
submitted (verified behaviour: login does not navigate away and an error label
appears). See TC003 for the asserted string.

### Product details (tap a product image)
| Element | Selector | Notes |
|---|---|---|
| Title | `productTV` | e.g. "Sauce Labs Backpack" |
| Image | `productIV` | |
| Price | `priceTV` | |
| Colour swatches | `colorRV` / `colorIV` | content-desc "Black/Blue/Gray/Green color" |
| Decrease qty | `minusIV` | |
| Quantity value | `noTV` | text "1" |
| Increase qty | `plusIV` | |
| Add to cart | `cartBt` (text "Add to cart") | |
| Highlights header | `productHeightLightsTV` | |

### Cart (`cartCL`)
| Element | Selector | Notes |
|---|---|---|
| Title | `productTV` (text "My Cart") | |
| Item title | `titleTV` | |
| Item price | `priceTV` | |
| Decrease / qty / increase | `minusIV` / `noTV` / `plusIV` | |
| Remove item | `removeBt` (text "Remove Item") | |
| Items total | `itemsTV` (e.g. "1 Items") | |
| Total price | `totalPriceTV` | |
| Proceed to checkout | `cartBt` (text "Proceed To Checkout") | |

### Checkout — shipping (`checkoutSV`)
| Element | Selector | Required |
|---|---|---|
| Title | `checkoutTitleTV` (text "Checkout") | |
| Full name | `fullNameET` | yes |
| Address line 1 | `address1ET` | yes |
| Address line 2 | `address2ET` | no |
| City | `cityET` | yes |
| Zip code | `zipET` | yes |
| State/Region | `stateET` | no |
| Country | `countryET` | yes |
| To payment | `paymentBtn` (text "To Payment") | |

> **Observed quirk:** the shipping form scrolls, and the soft keyboard covers the
> lower fields. Flows must `hideKeyboard` after each `inputText` and
> `scrollUntilVisible` for `zipET` / `countryET`.

### Checkout — payment
| Element | Selector | Notes |
|---|---|---|
| Title | `enterPaymentTitleTV` (text "Checkout") | |
| Full name | `nameET` | |
| Card number | `cardNumberET` | synthetic only |
| Expiration | `expirationDateET` | format MM/YY |
| Security code | `securityCodeET` | |
| Billing same as shipping | `billingAddressCB` (checkbox, checked by default) | |
| Review order | `paymentBtn` (text "Review Order") | |

### Checkout — confirmation
| Element | Selector | Notes |
|---|---|---|
| Heading | `completeTV` (text "Checkout Complete") | |
| Thank you | `thankYouTV` (text "Thank you for your order") | |
| Swag line | `swagTV` ("Your new swag is on its way") | |
| Order line | `orderTV` (dispatch message) | |
| Continue shopping | `shoopingBt` (text "Continue Shopping") | **note the app's id is spelled `shoopingBt`** |

## Available test scenarios (verified feasible on this build)

| TC | Journey | Status |
|---|---|---|
| TC001 | App launch → Products visible | Supported |
| TC002 | Valid login (`bod@example.com`) → returns authenticated | Supported |
| TC003 | Invalid login → error shown | Supported |
| TC004 | Product details for "Sauce Labs Backpack" | Supported |
| TC005 | Add product to cart → badge shows 1 | Supported |
| TC006 | Remove product from cart → empty cart | Supported |
| TC007 | Full checkout → "Checkout Complete" | Supported |
| TC008 | Drawer navigation (Catalog / WebView / About / back) | Supported |

## Known limitations

- The app ships synthetic demo credentials on the login screen; no real backend
  auth is involved. No real transaction occurs at checkout — it is a local demo.
- Product cards reuse the same resource-ids (`productIV`, `priceTV`, star ids),
  so positional (`index`) or relative (`below:`) matching is required.
- The soft keyboard overlaps checkout fields; flows handle this with
  `hideKeyboard` + `scrollUntilVisible`.
- Login is **not** required to browse products or build a cart; it is required to
  complete checkout on this build. TC002/TC003 exercise the login screen directly.
- Emulator clock/network icons belong to SystemUI, never to the app — never
  assert on them.

## Test data requirements

| Variable | POC value | Source |
|---|---|---|
| `APP_ID` | `com.saucelabs.mydemoapp.android` | discovery |
| `TEST_USERNAME` | `bod@example.com` | on-screen demo data |
| `TEST_PASSWORD` | `10203040` | on-screen demo data |
| `INVALID_USERNAME` | `invalid@example.com` | synthetic |
| `INVALID_PASSWORD` | `wrongpass` | synthetic |

Credentials are injected via environment variables, never hard-coded in flows.
