# Kisi Secure Unlock

## Integration

Kisi Secure Unlock is distributed as a swift package.
To integrate it into your app simply add the [repository](https://github.com/kisi-inc/kisi-ios-st2u-framework) as a package dependency in [Xcode](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app).

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
    <string>bluetooth-peripheral</string>
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

In ```didFinishLaunchingWithOptions``` start the secure unlock manager and set the delegate
```swift
SecureUnlockManager.shared.start()
SecureUnlockManager.shared.delegate = self
```

### SecureUnlockDelegate

You need to implemented the SecureUnlockDelegate protocol.

```swift
extension MyClass: SecureUnlockDelegate {
    func secureUnlockSuccess(online: Bool) {
        // Callback when unlock succeeds.
        // Online parameter indicates if it was an online or offline unlock.
    }
    
    func secureUnlockFailure(error: SecureT2UError) {
        // Login id callback. 
        // If you only support 1 login you can ignore the organization property and simply return the login id for the logged in user. Otherwise you must find the login id for the given organization.
    }
    
    func secureUnlockLoginIDForOrganization(_ organization: Int?) -> Int? {
        // Login id callback. 
        // If you only support 1 login you can ignore the organization property and simply return the login id for the logged in user. Otherwise you must find the login id for the given organization.
    }
    
    func secureUnlockPhoneKeyForLogin(_ login: Int) -> String? {
        // Phone key callback. 
        // The phone key is returned when you create a login object. See https://api.kisi.io/docs#tag/Logins/paths/~1logins/post.
    }
    
    func secureUnlockFetchCertificate(login: Int, reader: Int, online: Bool, completion: @escaping (Result<String, SecureT2UError>) -> Void) {
        // If online use certificate that was returned when login was created. See scram credentials property https://api.kisi.io/docs#tag/Logins/paths/~1logins/post.
        // If offline you need to fetch a short lived offline certificate for the given reader (beacon) id. See offline certificate https://api.kisi.io/docs#tag/SCRAM/paths/~1login~1offline_certificate/post.
    }
}
```

### Optional
If you have opted for location permission you can also start the BeaconManager in ```didFinishLaunchingWithOptions```

```swift
BeaconManager.shared.startMonitoring()
```

If you also want access to the TOTP needed for doing in-app unlocks for doors that have this feature enabled you should also start ranging in ```applicationWillEnterForeground```.

```swift
BeaconManager.shared.startRanging()
```

And to avoid excessive battery consumption stop ranging in ```applicationDidEnterBackground```.
```swift
BeaconManager.shared.stopRanging()
```

The beacon manager will post notifications when entering/leaving a nearby reader that you can listen for.
```swift
NotificationCenter.default.addObserver(self, selector: #selector(didEnterNotification), name: .BeaconManagerDidEnterRegionNotification, object: nil)
NotificationCenter.default.addObserver(self, selector: #selector(didExitNotification), name: .BeaconManagerDidExitRegionNotification, object: nil)
```
