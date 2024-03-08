# Kisi Tap to Unlock SDK for iOS

## Who is this SDK for?

This SDK is for all Kisi partners and customers who want to integrate seamless access control into their mobile app. Using the SDK, they can provide Kisi-powered mobile credentials for their end users, such as:

- Tap to unlock: allowing users to open a door only by holding their mobile device up to a Kisi Reader
- Tap in-app: allowing users to unlock doors by tapping within their app.

## What does this SDK include?

- Tap to unlock functionality (also referred to as ‘Tap to access’)
- Kisi's BLE beacon scanner functionality. This is needed to satisfy the requirements of [reader restrictions](https://docs.kisi.io/concepts/restrictions#kisi-reader-restriction) for in-app unlocks. The reader restriction feature ensures that users may only unlock when standing in front of a door.

## What this SDK doesn’t include

- Signing in ([described here](https://docs.kisi.io/api/how_to_guides/manage_users/#log-in-on-behalf-of-managed-users))
- In-app unlock calls
- UI

## Update the SDK

Make sure you regularly update the SDK. Versions earlier than 0.6 don’t support [offline cache](https://docs.kisi.io/concepts/offline_support#offline-cache-on-the-reader) and [BLE beacon scanners](https://docs.kisi.io/concepts/restrictions#kisi-reader-restriction). This means, you won't be able to use these features unless you update the SDK.

For the list of changes, please see the [release change log](https://github.com/kisi-inc/kisi-ios-st2u-framework/releases). Get further help under the following links:

- If it turns out that you may have found a bug, please [open an issue](https://github.com/kisi-inc/kisi-ios-st2u-framework/issues)
- For questions related to the Kisi API, check out our [API integration guides](https://docs.kisi.io/api/) and [API reference](https://api.getkisi.com/docs#/)
- To understand basic Kisi concepts, visit our [product documentation](https://docs.kisi.io/)

### Prerequisites

- iOS 13 at minimum
- Kisi organization administrator rights
- Kisi hardware setup: To use the SDK, you must have a Kisi controller and reader set up, powered up and connected to the network. If you don’t have this yet, please follow our articles on [how to install the Kisi hardware](https://docs.kisi.io/get_started/install_your_kisi_hardware/).
- A Kisi partner ID: This is used by Kisi to collect information on how different integrations perform and to offer help based on the integration partner-specific logs. The information collected does not include any personal data. You can request a partner ID by sending an email to [sdks@kisi.io](mailto:sdks@kisi.io).

### Create an account and sign in

If you don’t have one yet, [create a Kisi account and sign in](https://docs.kisi.io/api/get_started/create_account_and_sign_in). Make sure you have organization administrator rights, since this will be needed in the following steps.

### Create an admin login

Next, [create an admin login](https://docs.kisi.io/api/get_started/create_login) to obtain an API key. This will allow you to make requests to the Kisi API without having to enter your user credentials each time.

## Get started with Tap to unlock (Tap to Access)

Tap to unlock allows users to unlock doors by tapping their iOS mobile device against the Kisi Reader, without having to actively use your app. The communication is based on NFC technology, transmitting the information to the controller and the cloud. Communication with the controller can also be through a local network. If the local network is offline, the phone will request offline credentials from the cloud. In this case, the reader will talk to the controller without any intermediaries. (Note: We only support [offline cache](https://docs.kisi.io/concepts/offline_support) on versions later than 0.6).

## Log in on behalf of your users

Since your users won’t be able to log in to Kisi themselves, your app will need to do this automatically, on their behalf. To achieve this, you need to add a Kisi API call to your sign-in flow, as [shown in our API guide](https://docs.kisi.io/api/how_to_guides/manage_users/#log-in-on-behalf-of-managed-users).

You need to store this login object in your app's local cache and provide it to our SDK as a part of its initialization code. This login can then be used subsequently to make requests to the Kisi API on behalf of the user.

**Note**: If you intend to support multiple organization accounts for the same user, you will need to create a separate login for each of these accounts. It is not possible to fetch all organization accounts associated with a specific email address due to security reasons. Therefore, you must store the list of their organization IDs yourself.

## Request the necessary permissions from users

Depending on which feature set you want to support, you need to request the appropriate permissions from the user. Please refer to the table below to determine the required permission for each feature.

|                    | Bluetooth | Location |
| ------------------ | --------- | -------- |
| Tap To Access      | yes       | yes\*    |
| Reader Restriction | no        | yes      |

_\*not strictly necessary but will improve the performance of tap to unlock (i.e. allowing for faster unlocks)._

### Bluetooth

1. Add the following to your `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Some string explaining to your users why you need bluetooth permission.</string>
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-peripheral</string>
</array>
```

2. Prompt the Bluetooth permission dialog by simply initializing a `CBCentralManager` instance:

```swift
CBCentralManager(delegate: self, queue: .main, options: nil)
```

### Location

We don't use the device's GPS coordinates. But we are using iBeacon which Apple has put under the Core Location framework despite being BLE.

1. Add the following to your `Info.plist`:

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Unlocking by tapping your phone against a Kisi reader will work better with always permission. Kisi doesn&apos;t store or share your location data.</string>
```

2. Prompt the user for location permission:

```swift
let locationManager = CLLocationManager()
locationManager.delegate = self
locationManager.requestAlwaysAuthorization()
```

## Integrate the SDK

### Import the `SecureAccess` package

```swift
import SecureAccess
```

In `didFinishLaunchingWithOptions` start the secure unlock manager and set the delegate

```swift
TapToAccessManager.shared.start()
TapToAccessManager.shared.delegate = self
```

If you have opted for _Location permission_: _Always_, you can also monitor for Kisi readers to ensure that the app is running and ready to unlock when holding it up to a reader. When the app launches (`didFinishLaunchingWithOptions`) start monitoring:

```swift
ReaderManager.shared.startMonitoring()
```

Implement the `SecureUnlockDelegate` protocol

```swift
extension MyClass: TapToAccessDelegate {
    func tapToAccessSuccess(online: Bool, duration: TimeInterval) {
        // Callback when unlock succeeds.
        // Online parameter indicates if it was an online or offline unlock.
        // Duration parameter tells how long the unlock took
    }

    func tapToAccessFailure(error: TapToAccessError, duration: TimeInterval) {
        // Unlock failed
        // Note that if needsDeviceOwnerVerification you should prompt the user to unlock the phone or set up a passcode.
        // Duration parameter tells how long the unlock took
    }

    func tapToAccessClientID() -> Int {
        // Request your client id on sdks@kisi.io and return it here
    }

    func tapToAccessLoginForOrganization(_ organization: Int?) -> Login? {
        // Return a Login object for the given organization.
        // See https://api.kisi.io/docs#/operations/createLogin on how to create logins
    }
}
```

## Satisfy reader restrictions in in-app unlocks

The Kisi Reader restriction feature ensures that users may only unlock when standing in front of a door. This SDK will allow you to fetch the necessary reader proof used to verify that you are standing at the door. [Read more on our documentation page](https://docs.kisi.io/concepts/restrictions)

Note: If you have implemented the Tap to Unlock scenario discussed above, you can skip the bullets below and jump directly to 9.1. If not, please follow the steps below.

1. When the app launches (`didFinishLaunchingWithOptions`) start monitoring

```swift
ReaderManager.shared.startMonitoring()
```

2. To obtain access to the reader proximity proof required for in-app unlocks on doors with this feature enabled, it is advised to initiate ranging in the `applicationWillEnterForeground`.

```swift
ReaderManager.shared.startRanging()
```

3. To avoid excessive battery consumption, stop ranging in `applicationDidEnterBackground`.

```swift
ReaderManager.shared.stopRanging()
```

4. Get the reader proof for a given lock

```swift
let readerProof = BeaconManager.shared.proximityProofForLock(lock.id)
```

The `ReaderManager` will post notifications when entering/leaving a nearby reader that you can listen for.

```swift
NotificationCenter.default.addObserver(self, selector: #selector(didEnterNotification), name: .ReaderManagerDidEnterNotification, object: nil)
NotificationCenter.default.addObserver(self, selector: #selector(didExitNotification), name: .ReaderManagerDidExitNotification, object: nil)
```

## Logging

You can enable logging from the SDK.

Note: this will return access tokens/keys/certificates in clear text. So while useful during development/debugging, it should be used with care in a production app.

```swift
SecureAccessLogger.info = { message, file, function in
    // Pass the info on to whichever logging backend you prefer. NSLog, print, etc
}

SecureAccessLogger.error = { message, file, function in
    // Pass the info on to whichever logging backend you prefer. NSLog, print, etc
}
```

## Apple Pay

If Apple Pay is enabled on the device, it will be triggered when you hold it up against the Kisi Reader. Currently, you can only suppress it when the app is in the foreground but not when it is in the background.

## Requesting entitlement

Locating the procedure for requesting these entitlements in the documentation may be challenging. Therefore, we are including the information here; however, it is essential to acknowledge that Apple's process for requesting these entitlements may have changed since the composition of this document.

To request the special entitlement email [apple-pay-provisioning@apple.com](mailto:apple-pay-provisioning@apple.com). Be sure to include information about your company and describe the use case requiring suppression of the Apple Pay dialog

### Suppressing dialog

When the app enters the foreground, call [requestAutomaticPassPresentationSuppression](https://developer.apple.com/documentation/passkit/pkpasslibrary/1617078-requestautomaticpasspresentation)

## Kisi App

If you have implemented the Tap To Unlock SDK in your application, make sure to remove the Kisi app. Otherwise, the determination of which application will be prompted to manage BLE requests remains unspecified.

## Example

Within this repository, you'll find a sample application that demonstrates the process of signing in and unlocking using both the tap-to-unlock feature and in-app functionality with reader proof.
