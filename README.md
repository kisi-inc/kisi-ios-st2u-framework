# Kisi Secure Access

The Kisi Secure Access SDK allows your app to interact with Kisi Readers.
Either via [tap to unlock](https://docs.kisi.io/concepts/tap_to_unlock_tap_to_access) or by retrieving the proof for doors with [reader restriction](https://docs.kisi.io/concepts/restrictions) enabled.

## Permissions

Depending on what feature set you want to support you need to request the appropriate permissions from the user

|               | Bluetooth | Location |
|---------------|-----------|----------|
| Tap To Access | yes       | yes*     |
| Reader Restriction  | no        | yes      |

_*not strictly necessary but will improve the performance of tap to unlock (i.e allowing for faster unlocks)._

### Bluetooth

Add the following to your Info.plist

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Some string explaining to your users why you need bluetooth permission.</string>
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-peripheral</string>
</array>
```

You prompt the bluetooth permission dialog by simply initializing an CBCentralManager instance:
```swift
CBCentralManager(delegate: self, queue: .main, options: nil)
```

### Location

We don't use the device's GPS coordinates. But we are using iBeacon which Apple has put under the Core Location framework despite being BLE.

Info.plist

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Unlocking by tapping your phone against a Kisi reader will work better with always permission. Kisi doesn&apos;t store or share your location data.</string>
```

You can then prompt the user for location permission
```swift
let locationManager = CLLocationManager()
locationManager.delegate = self
locationManager.requestAlwaysAuthorization()
```

## Tap to access

Tap To Unlock allows you to open a door only by holding your device up to a Kisi Reader. [Read more on our documentation page](https://docs.kisi.io/concepts/tap_to_unlock_tap_to_access)

Import the package

```swift
import SecureAccess
```

In ```didFinishLaunchingWithOptions``` start the secure unlock manager and set the delegate
```swift
TapToAccessManager.shared.start()
TapToAccessManager.shared.delegate = self
```

If you have opted for always location permission you can also monitor for Kisi readers to ensure that the app is running and ready to unlock when holding it up to a reader.
When app launches (didFinishLaunchingWithOptions) start monitoring
```swift
ReaderManager.shared.startMonitoring()
```

### TapToAccessDelegate

You need to implement the SecureUnlockDelegate protocol.

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

## Reader Restriction

The Kisi Reader restriction feature ensures that users may only unlock when standing in front of a door.
This SDK will allow you to fetch the necessary reader proof used to verify that you are standing at the door.
[Read more on our documentation page](https://docs.kisi.io/concepts/restrictions)

When app launches (didFinishLaunchingWithOptions) start monitoring
```swift
ReaderManager.shared.startMonitoring()
```

To get access to the reader proximity proof needed for doing in-app unlocks for doors that have this feature enabled you should also start ranging in ```applicationWillEnterForeground```.

```swift
ReaderManager.shared.startRanging()
```

And to avoid excessive battery consumption stop ranging in ```applicationDidEnterBackground```.
```swift
ReaderManager.shared.stopRanging()
```

Get the reader proof for a given lock
```swift
let readerProof = BeaconManager.shared.proximityProofForLock(lock.id)
```

The ReaderManager will post notifications when entering/leaving a nearby reader that you can listen for.
```swift
NotificationCenter.default.addObserver(self, selector: #selector(didEnterNotification), name: .ReaderManagerDidEnterNotification, object: nil)
NotificationCenter.default.addObserver(self, selector: #selector(didExitNotification), name: .ReaderManagerDidExitNotification, object: nil)
```

## Logging

You can enable logging from the SDK. Note that this will return access tokens/key/certificates in clear text.
So while useful during development/debugging it should be used with care in a production app.

```swift
SecureAccessLogger.info = { message, file, function in
    // Pass the info on to whichever logging backend you prefer. NSLog, print, etc
}

SecureAccessLogger.error = { message, file, function in
    // Pass the info on to whichever logging backend you prefer. NSLog, print, etc
}
```

## Apple Pay

If Apple Pay is enabled on the device, it will be triggered when you hold it up against the Kisi Reader.
Currently you can suppress that only when the app is in foreground but not in background.

### Requesting Entitlement

It can be a bit tricky to find in the documentation how to request those entitlements. So I'm adding it here, but note that Apples process for requesting them might have changed since this was written.

```
To request the special entitlement email apple-pay-provisioning@apple.com . Be sure to include information about your company and describe the use case requiring suppression of the Apple Pay dialog
```

### Suppressing Dialog

When app enters foreground call [requestAutomaticPassPresentationSuppression](https://developer.apple.com/documentation/passkit/pkpasslibrary/1617078-requestautomaticpasspresentation)


## Kisi App

If you have implemented Tap To Unlock in your own app. Make sure to uninstall the Kisi App.
Otherwise it's undefined which of the apps that will get asked to handle the BLE requests.

## Example

In this repository you can find an example app showing how to sign in and unlock both with tap to unlock and in-app with reader proof.
