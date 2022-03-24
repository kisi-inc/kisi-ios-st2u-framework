//
//  PlacesView.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import SwiftUI

struct PlacesView: View {
    @ObservedObject var viewModel = PlacesViewModel()
    
    var body: some View {
        List(viewModel.places) { place in
            NavigationLink(destination: LocksView(viewModel: LocksViewModel(place: place))) {
                Text(place.name)
            }
        }
        .navigationTitle("Places")
        .navigationBarBackButtonHidden(true)
    }
}

struct PlacesView_Previews: PreviewProvider {
    static var previews: some View {
        PlacesView()
    }
}
