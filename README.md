# Kisi secure unlock

## Permissions

### Required
Secure unlock needs bluetooth permission and be able to act as a bluetooth peripheral while in background.
So you need to add these to your Info.plist

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Some string explaining to your users why you need bluetooth permission.</string>
```

```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-peripheral</string>
</array>
```

You prompt the bluetooth permission dialog by simply initialising an CBCentralManager instance:
```swift
CBCentralManager(delegate: self, queue: .main, options: nil)
```

### Optional
You can also optionally get permission to use location in background. This will improve the performance of tap to unlock under certain conditions.

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Unlocking by tapping your phone against a Kisi reader will work better with always permission. Kisi doesn&apos;t store or share your location data.</string>
```

```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

You can then prompt the user for location permission
```swift
let locationManager = CLLocationManager()
locationManager.delegate = self
locationManager.requestAlwaysAuthorization()
```

## Usage
Import the package

```swift
import SecureUnlock
```

In didFinishLaunchingWithOptions start the secure unlock manager and set the delegate
```swift
SecureUnlockManager.shared.start()
SecureUnlockManager.shared.delegate = self
```

### Optional
If you have opted for location permission you can also start the BeaconManager in didFinishLaunchingWithOptions

```swift
BeaconManager.shared.startMonitoring()
```

If you also want access to the TOTP needed for doing in-app unlocks for doors that have this feature enabled you should also start ranging in applicationWillEnterForeground.

```swift
BeaconManager.shared.startRanging()
```

And to avoid excessive battery consumption stop ranging in applicationDidEnterBackground
```swift
BeaconManager.shared.stopRanging()
```
