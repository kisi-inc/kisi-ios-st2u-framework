//
//  ExampleApp.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import SwiftUI
import CoreBluetooth
import CoreLocation
import SecureUnlock

@main
struct ExampleApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    private let peripheralManager = CBPeripheralManager(delegate: nil, queue: .main, options: nil) // This will prompt bluetooth permission dialog. Don't do it like this in production app. Show a screen explaining why you need it first.
    private let locationManager = CLLocationManager()
    private let secureUnlockDataProvider = SecureUnlockDataProvider()
    
    init() {
        // As with bluetooth permission. Don't just request it without explaining why
        locationManager.requestAlwaysAuthorization()
        
        // In older App delegate style app you should do this in didFinishLaunching
        SecureUnlockManager.shared.delegate = secureUnlockDataProvider
        SecureUnlockManager.shared.start()
        BeaconManager.shared.startMonitoring()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                if AuthStorage.shared.currentLogin() != nil {
                    PlacesView()
                } else {
                    AuthenticationSelectionView()
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Start ranging should only be done when app is in foreground. didBecomeActive if you are using the older app delegate.
                // Ranging is needed to be able to do in-app unlocks with reader proof. Which you get by calling timeBasedOneTimePasswordForLock on BeaconManager.
                BeaconManager.shared.startRanging()
            } else if newPhase == .background {
                // And stop ranging when app leaves foreground to conserve battery
                BeaconManager.shared.stopRanging()
            }
        }
    }
}

class SecureUnlockDataProvider: SecureUnlockDelegate {
    func secureUnlockSuccess(online: Bool, duration: TimeInterval) {
        
    }
    
    func secureUnlockFailure(error: SecureT2UError, duration: TimeInterval) {
        if error == SecureT2UError.needsDeviceOwnerVerification {
            // This means that the reader has a setting turned on which requires that the phone has a passcode and is unlocked
            // So prompt user to unlock device or setup passcode.
            // Can be done via a notification if you have notification permission
            // Otherwise show some in-app banner/screen explaining it.
            print("User needs to unlock their device")
        }
    }
    
    func secureUnlockLoginIDForOrganization(_ organization: Int?) -> Int? {
        return AuthStorage.shared.currentLogin()?.id
    }
    
    func secureUnlockPhoneKeyForLogin(_ login: Int) -> String? {
        return AuthStorage.shared.currentLogin()?.scram.key
    }
    
    func secureUnlockFetchCertificate(login: Int, reader: Int, online: Bool, completion: @escaping (Result<String, SecureT2UError>) -> Void) {
        // NOTE: We aren't handling the offline case. But a future version of the secure unlock package will handle that for you.
        completion(.success(AuthStorage.shared.currentLogin()?.scram.certificate ?? ""))
    }
}
