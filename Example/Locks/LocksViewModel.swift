//
//  LocksViewModel.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import Foundation
import SwiftUI
import SecureAccess

class LocksViewModel: ObservableObject {
    private var lockRemote = LockRemote()
    private var readerManager = ReaderManager.shared
    
    @Published var locks: [Lock] = []
    private let place: Place
    
    init(place: Place) {
        self.place = place
        fetchLocks()
    }
    
    func fetchLocks() {
        lockRemote.fetchLocks(forPlace: place) { result in
            switch result {
            case .success(let locks):
                self.locks = locks
            case .failure(_):
                print("noooooooo")
            }
        }
    }
    
    func unlock(_ lock: Lock) {
        // A reader can be configured to require a proof that the phone is nearby the reader
        // You can get this from the beacon manager
        let proof = readerManager.proximityProofForLock(lock.id)
        lockRemote.unlock(lock, proof: proof)
    }
}
