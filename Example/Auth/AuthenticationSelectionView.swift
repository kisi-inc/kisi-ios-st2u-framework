//
//  AuthenticationSelectionView.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-04-01.
//

import SwiftUI

struct AuthenticationSelectionView: View {
    var body: some View {
        VStack {
            Spacer()
            NavigationLink("SSO") {
                SSOView(domain: "kisi")
            }
            Spacer()
                .frame(height: 20)
            NavigationLink("Password") {
                PasswordAuthView()
            }
            Spacer()
        }
        Text("Hello, World!")
    }
}

struct AuthenticationSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationSelectionView()
    }
}
