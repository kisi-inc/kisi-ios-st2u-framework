//
//  PasswordAuthViewModel.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import Foundation
import SwiftUI

class PasswordAuthViewModel: ObservableObject {
    private let authStorage = AuthStorage.shared
    private let authRemote = AuthRemote()
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var domain: String = ""
    @Published var showPlaces: Bool = false
    
    func signIn() {
        authRemote.authenticate(email: email, password: password, domain: domain) { result in
            switch result {
            case .success(let login):
                self.authStorage.store(login)
                self.showPlaces = true
            case .failure:
                // No error handling in example app
                print("oooops")
            }
        }
    }
}
