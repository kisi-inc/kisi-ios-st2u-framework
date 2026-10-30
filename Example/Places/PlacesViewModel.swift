//
//  PlacesViewModel.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import Foundation
import SwiftUI

@MainActor
class PlacesViewModel: ObservableObject {
    private let placeRemote = PlaceRemote()
    @Published var places: [Place] = []
    
    init() {
        fetchPlaces()
    }
    
    func fetchPlaces() {
        placeRemote.fetchPlaces() { result in
            switch result {
            case .success(let places):
                self.places = places
            case .failure:
                print("error fetching places")
            }
        }
    }
}
