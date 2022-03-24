//
//  LocksView.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import SwiftUI

struct LocksView: View {
    @ObservedObject var viewModel: LocksViewModel
    
    var body: some View {
        List(viewModel.locks) { lock in
            Button(lock.name) {
                viewModel.unlock(lock)
            }
        }
        .navigationTitle("Locks")
    }
}

struct LocksView_Previews: PreviewProvider {
    static var previews: some View {
        LocksView(viewModel: LocksViewModel(place: Place(id: 0, name: "b0rk")))
    }
}
