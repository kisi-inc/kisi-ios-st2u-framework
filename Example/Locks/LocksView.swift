//
//  LocksView.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import SwiftUI
import SecureAccess

struct LocksView: View {
    @ObservedObject var viewModel: LocksViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        List(viewModel.locks) { lock in
            Button(lock.name) {
                viewModel.unlock(lock)
            }
        }
        .navigationTitle("Locks")
        // Ranging costs battery, so only do it where a proximity proof is actually needed.
        // This is the only screen that unlocks, so it owns the ranging lifecycle.
        .onAppear {
            ReaderManager.shared.startRanging()
        }
        .onDisappear {
            ReaderManager.shared.stopRanging()
        }
        .onChange(of: scenePhase) { newPhase in
            // onDisappear isn't called when the app is backgrounded, so cover that here.
            // This also picks up ranging again if the user granted location in Settings.
            //
            // .background rather than any non-.active phase: .inactive is usually transient -
            // Control Center, a notification banner - and ranging needs a moment to rediscover
            // beacons, so stopping there risks a nil proof for someone who taps unlock right after.
            if newPhase == .active {
                ReaderManager.shared.startRanging()
            } else if newPhase == .background {
                ReaderManager.shared.stopRanging()
            }
        }
    }
}

struct LocksView_Previews: PreviewProvider {
    static var previews: some View {
        LocksView(viewModel: LocksViewModel(place: Place(id: 0, name: "b0rk")))
    }
}
