//
//  ExampleApp.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import SwiftUI
import CoreBluetooth
import CoreLocation
import SecureAccess

@main
struct ExampleApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    private let peripheralManager = CBPeripheralManager(delegate: nil, queue: .main, options: nil) // This will prompt bluetooth permission dialog. Don't do it like this in production app. Show a screen explaining why you need it first.
    private let locationManager = CLLocationManager()
    private let tapToAccessDataProvider = TapToAccessDataProvider()
    
    init() {
        // As with bluetooth permission. Don't just request it without explaining why
        locationManager.requestAlwaysAuthorization()
        
        // In older App delegate style app you should do this in didFinishLaunching
        TapToAccessManager.shared.delegate = tapToAccessDataProvider
        TapToAccessManager.shared.start()
        ReaderManager.shared.startMonitoring()
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
                ReaderManager.shared.startRanging()
            } else if newPhase == .background {
                // And stop ranging when app leaves foreground to conserve battery
                ReaderManager.shared.stopRanging()
            }
        }
    }
}

class TapToAccessDataProvider: TapToAccessDelegate {
    func tapToAccessSuccess(online: Bool, duration: TimeInterval) {
        
    }
    
    func tapToAccessFailure(error: TapToAccessError, duration: TimeInterval) {
        if error == .needsDeviceOwnerVerification {
            // This means that the reader has a setting turned on which requires that the phone has a passcode and is unlocked
            // So prompt user to unlock device or setup passcode.
            // Can be done via a notification if you have notification permission
            // Otherwise show some in-app banner/screen explaining it.
            print("User needs to unlock their device")
        }
    }
    
    func tapToAccessClientID() -> Int {
        return 0 // Request proper id by emailing sdks@kisi.io. This is so we can better help you debug any issues you might run into.
    }
    
    func tapToAccessLoginForOrganization(_ organization: Int?) -> SecureAccess.Login? {
        // If you app supports being signed in to multiple organization use the id to lookup the corresponding login.
        // otherwise just return the login you have.
        guard let login = AuthStorage.shared.currentLogin() else { return nil }
        
        return .init(id: login.id, token: login.secret, key: login.scram.key, certificate: login.scram.certificate)
    }
}
