//
//  ExampleApp.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import SwiftUI
import SecureAccess

@main
struct ExampleApp: App {
    private let tapToAccessDataProvider = TapToAccessDataProvider()
    @StateObject private var tapToAccess = TapToAccessObserver()

    init() {
        // Don't do it like this in a production app - show a screen explaining why first.
        TapToAccessManager.shared.requestBluetoothAuthorization()
        ReaderManager.shared.requestLocationAuthorization(.always)

        // In older App delegate style app you should do this in didFinishLaunching.
        // Order against the prompts above doesn't matter - both managers remember what they
        // were asked for.
        TapToAccessManager.shared.dataSource = tapToAccessDataProvider
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
            .alert("Unlock your phone", isPresented: $tapToAccess.needsDeviceOwnerVerification) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This door requires your phone to have a passcode and be unlocked.")
            }
        }
    }
}

// Results are notifications, not callbacks - observe only what you care about.
@MainActor
final class TapToAccessObserver: ObservableObject {
    @Published var needsDeviceOwnerVerification = false

    private var observers: [NSObjectProtocol] = []

    init() {
        // Authentication succeeded. Deliberately drives no UI - this means the phone
        // authenticated with the reader, not that the door opened.
        observers.append(NotificationCenter.default.addObserver(
            forName: .TapToAccessDidAuthenticateNotification,
            object: nil,
            queue: .main
        ) { notification in
            let certificateType = notification.tapToAccessCertificateType
            let duration = notification.tapToAccessDuration ?? 0

            print("Authenticated with the reader in \(duration)s, certificate: \(String(describing: certificateType))")
        })

        // Authentication failed. needsDeviceOwnerVerification is the one worth prompting on -
        // the reader wants a passcode protected, unlocked phone.
        observers.append(NotificationCenter.default.addObserver(
            forName: .TapToAccessDidFailNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard notification.tapToAccessError == .needsDeviceOwnerVerification else { return }

            Task { @MainActor in
                self?.needsDeviceOwnerVerification = true
            }
        })
    }

    isolated deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}

// The login is all the SDK needs from you. Everything that doesn't change while the app
// runs - the client id, for now - lives in KisiSecureAccess.plist instead.
//
// A plain main actor class is enough. Conform an actor instead if you would rather
// keep the login lookup off the main thread.
@MainActor
final class TapToAccessDataProvider: TapToAccessDataSource {
    func tapToAccessLoginForOrganization(_ organization: Int) async -> SecureAccess.Login? {
        // If you app supports being signed in to multiple organization use the id to lookup the corresponding login.
        // otherwise just return the login you have.
        guard let login = AuthStorage.shared.currentLogin() else { return nil }
        
        return .init(id: login.id, token: login.secret, key: login.scram.key, certificate: login.scram.certificate)
    }
}
