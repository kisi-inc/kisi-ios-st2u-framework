# Kisi Tap to Unlock SDK for iOS

Tap to Unlock at a Kisi Reader, plus the proximity proof some doors require for in-app unlocks.

## What the SDK does

There are two ways a user can unlock a door, and the SDK's role differs between them.

> [!NOTE]
> **Tap to Unlock** — the user holds their phone against a Kisi Reader. Your app does not have to be open. The SDK handles the BLE conversation with the reader and authenticates them.
>
> **In-app unlock** — the user taps a button in your app, which calls the Kisi API. The SDK is only involved when the door has a [reader proximity restriction](https://docs.kisi.io/concepts/restrictions), where it supplies a one time password from the nearest reader, proving the user is standing at it.

**MotionSense** — waving at the reader with the phone still in a pocket — is Tap to Unlock as far as your integration is concerned, and needs nothing extra.

The SDK does not sign users in, perform in-app unlocks, or provide any UI. Those are yours, through [log in on behalf of managed users](https://docs.kisi.io/api/how_to_guides/manage_users/#log-in-on-behalf-of-managed-users) and the [Kisi API](https://docs.kisi.io/api/).

## Which integration do you need?

Not every integration needs every permission. Pick the one that matches your app.

| Integration | Bluetooth | Location | Background mode |
| --- | --- | --- | --- |
| [Tap to Unlock and in-app unlock](#set-up-tap-to-unlock-and-in-app-unlock) | required | Always | `bluetooth-peripheral` |
| [Tap to Unlock, foreground only](#tap-to-unlock-foreground-only) | required | optional | none |
| [In-app unlock only](#in-app-unlock-only) | not needed | When In Use | none |

If you are not sure, start with the first row.

## Before you start

- iOS 15 or later
- A Kisi Reader to test against — [installed](https://docs.kisi.io/get_started/install_your_kisi_hardware/), powered up and on the network
- A **client ID** — [request SDK access](https://docs.kisi.io/platform/sdks/integration_process/), or email [sdks@kisi.io](mailto:sdks@kisi.io). Kisi uses it to identify your integration in support logs, and it collects no personal data.

## Add the SDK

In Xcode, go to _File › Add Package Dependencies…_ and enter:

```
https://github.com/kisi-inc/kisi-ios-st2u-framework
```

Add the `SecureAccess` library to your app target, then:

```swift
import SecureAccess
```

## Configure the SDK

> Skip this if you are only doing in-app unlocks.

Add a property list named `KisiSecureAccess.plist` to your app target with your client ID in it, and check that it appears under _Target › Build Phases › Copy Bundle Resources_:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <!-- REPLACE THIS with the client ID Kisi issued you -->
    <key>ClientID</key>
    <integer>0</integer>
</dict>
</plist>
```

## Sign your users in

Your users sign in to your app, not to Kisi, so your app fetches a Kisi login on their behalf. Add a Kisi API call to your sign-in flow as described in [log in on behalf of managed users](https://docs.kisi.io/api/how_to_guides/manage_users/#log-in-on-behalf-of-managed-users), and store the login object it returns. You need it for your own API calls, and on the Tap to Unlock paths to build the `Login` the SDK asks for.

## Set up Tap to Unlock and in-app unlock

Users get both Tap to Unlock and in-app unlock. Location is not strictly required for Tap to Unlock, but it is what lets the SDK notice a nearby reader and get ready for it — without it, Tap to Unlock is noticeably slower.

The [Example app](Example/ExampleApp.swift) implements this path end to end.

> [!WARNING]
> Tell your users to remove the Kisi app. With both installed, which one answers the reader is undefined.

**1 · Add your Info.plist keys**

iOS wants both location keys before it will grant Always authorization. The same string works for each.

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Explain why your app needs Bluetooth.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Explain why your app needs location. Kisi does not store or share location data.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Explain why your app needs location. Kisi does not store or share location data.</string>
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-peripheral</string>
</array>
```

**2 · Request the permissions**

During onboarding, after a screen explaining why you need them.

```swift
TapToAccessManager.shared.requestBluetoothAuthorization()
ReaderManager.shared.requestLocationAuthorization(.always)
```

Requesting does nothing once a permission has been refused, so read `bluetoothAuthorization` or `locationAuthorization` if you need to send the user to Settings instead:

```swift
switch ReaderManager.shared.locationAuthorization {
case .notDetermined:
    break               // requesting will show the prompt
case .denied:
    break               // only Settings can change it now
case .whenInUse:
    break               // see below
case .authorized:
    break               // everything Tap to Unlock needs
@unknown default:
    break               // a later SDK may add cases
}
```

`locationAuthorization.isAuthorized` covers "did I get it at all" if you don't need the individual cases.

`.whenInUse` matters on this path: in-app unlocks work, but iOS will not wake your app for a nearby reader. iOS allows the upgrade to always to be requested **once** — after that only Settings can change it.

**3 · Start the SDK on launch**

In `didFinishLaunchingWithOptions`, or your `App` initializer. Set the data source before starting, because Tap to Unlock can begin as soon as you do. Both managers are main actor isolated, so call them from the main thread.

```swift
TapToAccessManager.shared.dataSource = self
TapToAccessManager.shared.start()
ReaderManager.shared.startMonitoring()
```

Order against the permission prompts does not matter — starting before the user has granted is fine.

**4 · Range only while you need a proximity proof**

Ranging is what reads proximity proofs, and it uses battery — so scope it to your in-app unlock screen, not to your whole foreground session. Call `ReaderManager.shared.startRanging()` when that screen appears and `stopRanging()` when it goes away. Stop on backgrounding too, since a view is not told it disappeared when the app leaves the foreground. [`LocksView.swift`](Example/Locks/LocksView.swift) does both.

**5 · Provide a login**

Implement `TapToAccessDataSource` so the SDK can authenticate against a reader. `token`, `key` and `certificate` are `secret`, `scram_credentials.phone_key` and `scram_credentials.online_certificate` from the login response.

```swift
extension MyClass: TapToAccessDataSource {
    func tapToAccessLoginForOrganization(_ organization: Int) async -> Login? {
        // Look up the login for this organization. If you only support one, return that.
        return Login(id: ..., token: ..., key: ..., certificate: ...)
    }
}
```

**6 · Pass the proximity proof with your in-app unlock calls**

`ReaderManager.shared.proximityProofForLock(lock.id)` returns the proof, or `nil` when that door's reader is not nearby. Send it with your in-app unlock call so doors with a reader proximity restriction accept it.

That completes the setup. All that is left is reacting to the outcome.

## Handle the result

Tap to Unlock reports results as notifications. Observe the ones you care about; there is nothing you have to implement.

| Notification | Read with |
| --- | --- |
| `TapToAccessDidAuthenticateNotification` | `tapToAccessCertificateType`, `tapToAccessDuration` |
| `TapToAccessDidFailNotification` | `tapToAccessError`, `tapToAccessDuration` |

> [!TIP]
> Keep success UI off this notification. It means the phone authenticated with the reader, not that the door opened — that is decided separately, so an "Unlocked!" banner here will sometimes be wrong.

The one result worth acting on is `needsDeviceOwnerVerification`. The reader requires a passcode-protected, unlocked phone, and without a prompt the user has no idea why nothing happened:

```swift
NotificationCenter.default.addObserver(
    forName: .TapToAccessDidFailNotification,
    object: nil,
    queue: .main
) { notification in
    guard notification.tapToAccessError == .needsDeviceOwnerVerification else { return }

    // Ask the user to unlock their device or set a passcode.
}
```

**That is the whole integration.** Everything below is either a different setup or reference material.

---

## Other integrations

Alternatives to the integration above, not additions to it. Skip this section unless the [table at the top](#which-integration-do-you-need) sent you here.

### Tap to Unlock, foreground only

Users get Tap to Unlock, but only while the screen you tie it to is open. No location, and no background mode. As with the full integration, tell your users to remove the Kisi app.

<details>
<summary><b>Show the steps</b></summary>

**1 · Add your Info.plist key**

The only one this path needs — no location keys, and no `bluetooth-peripheral` background mode.

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Explain why your app needs Bluetooth.</string>
```

**2 · Turn off state restoration**

In `KisiSecureAccess.plist`, alongside your client ID:

```xml
<key>StateRestoration</key>
<false/>
```

**3 · Request Bluetooth permission**

During onboarding, after a screen explaining why: `TapToAccessManager.shared.requestBluetoothAuthorization()`. Read `bluetoothAuthorization` if you need to tell a user who refused to change it in Settings.

**4 · Start only while your unlock screen is open**

Tie this to the screen a user would unlock from, not to app launch — outside it there is nothing to serve.

Set the data source once, at launch:

```swift
TapToAccessManager.shared.dataSource = self
```

Then call `TapToAccessManager.shared.start()` when that screen is presented — or when the user taps an unlock button, whichever fits your app — and `stop()` when they leave it. Cover backgrounding too, since a screen is not always told it went away when the app does.

**5 · Provide a login**

Implement `TapToAccessDataSource` as in [the full integration](#set-up-tap-to-unlock-and-in-app-unlock), then observe [the results](#handle-the-result).

</details>

### In-app unlock only

For doors with a reader proximity restriction. The SDK scans for nearby readers and hands you the proof that the user is standing at one; your app passes it with its own in-app unlock call. No Bluetooth, no background mode, no `KisiSecureAccess.plist`.

Kisi uses iBeacon for this, which Apple put under Core Location. The SDK never reads GPS coordinates.

<details>
<summary><b>Show the steps</b></summary>

**1 · Add your Info.plist key**

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Explain why your app needs location. Kisi does not store or share location data.</string>
```

**2 · Request location permission**

During onboarding, after a screen explaining why. `.whenInUse` is enough for this path, since your app is open whenever it needs a proof.

```swift
ReaderManager.shared.requestLocationAuthorization(.whenInUse)
```

`locationAuthorization.isAuthorized` tells you whether you got it — `.whenInUse` is the success case here, not a partial one. Read `locationAuthorization` itself if you need to tell a user who refused to change it in Settings.

**3 · Range only while you need a proximity proof**

Ranging is what reads proximity proofs, and it uses battery — so scope it to your in-app unlock screen, not to your whole foreground session. Call `ReaderManager.shared.startRanging()` when that screen appears and `stopRanging()` when it goes away. Stop on backgrounding too, since a view is not told it disappeared when the app leaves the foreground. [`LocksView.swift`](Example/Locks/LocksView.swift) does both.

**4 · Pass the proximity proof with your in-app unlock calls**

`ReaderManager.shared.proximityProofForLock(lock.id)` returns the proof, or `nil` when that door's reader is not nearby.

`ReaderManager` also offers `isNearbyLock(_:)` and `nearbyLocks` if you want to show which doors are in reach, and posts `ReaderManagerDidEnterNotification` and `ReaderManagerDidExitNotification` as that changes.

</details>

## Reference

<details>
<summary><b>Logging</b></summary>

Set either handler to receive the SDK's log lines:

```swift
SecureAccessLogger.shared.info = { message, file, function in
    // NSLog, print, or your own logging backend
}

SecureAccessLogger.shared.error = { message, file, function in
    // NSLog, print, or your own logging backend
}
```

Your handler is not called on the main thread, so hop to the main actor yourself if it touches UI.

The lines carry ids and connection states, never tokens, keys or certificates, so they can go in logs your users send to support.

</details>

<details>
<summary><b>Suppressing the Apple Pay dialog</b></summary>

If Apple Pay is enabled on the device, it will sometimes trigger when the user holds their phone to a Kisi Reader. You can suppress it while your app is in the foreground, but not from the background.

Call [`requestAutomaticPassPresentationSuppression`](https://developer.apple.com/documentation/passkit/pkpasslibrary/1617078-requestautomaticpasspresentation) when your app enters the foreground. It needs a special entitlement from Apple.

To request the entitlement, email [apple-pay-provisioning@apple.com](mailto:apple-pay-provisioning@apple.com) with information about your company and the use case requiring suppression. Apple's process may have changed since this was written.

</details>

<details>
<summary><b>Keeping the SDK up to date</b></summary>

Update regularly. Versions before 0.6 support neither [offline cache](https://docs.kisi.io/concepts/offline_support) nor reader proximity proofs, so those features simply won't work.

- [Release change log](https://github.com/kisi-inc/kisi-ios-st2u-framework/releases)
- [Report a bug](https://github.com/kisi-inc/kisi-ios-st2u-framework/issues)
- [Kisi API guides](https://docs.kisi.io/api/) and [API reference](https://api.kisi.io/docs)
- [Kisi product documentation](https://docs.kisi.io/)

</details>

## Example app

This repository includes a sample app covering signing in, Tap to Unlock, and in-app unlocks with a proximity proof. See [`Example/ExampleApp.swift`](Example/ExampleApp.swift) for the start-up sequence, data source and result handling.
