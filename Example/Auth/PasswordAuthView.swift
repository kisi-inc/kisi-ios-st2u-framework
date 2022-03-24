//
//  PasswordAuthView.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import SwiftUI

struct PasswordAuthView: View {
    @ObservedObject var viewModel = PasswordAuthViewModel()
    
    var body: some View {
        VStack {
            TextField("Domain", text: $viewModel.domain)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            TextField("Email", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            SecureField("Password", text: $viewModel.password)
                .keyboardType(.default)
                .textContentType(.password)
                .textInputAutocapitalization(.never)
            Button("Sign in") {
                viewModel.signIn()
            }
            NavigationLink(destination: PlacesView(), isActive: $viewModel.showPlaces) {
                 EmptyView()
            }
            .hidden()
        }
        .navigationTitle("Password sign in")
        .padding()
    }
}

struct PasswordAuthView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordAuthView()
    }
}
