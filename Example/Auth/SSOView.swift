//
//  SSOView.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-04-01.
//

import Foundation
import SwiftUI
import WebKit

struct SSOView: UIViewRepresentable {
    let domain: String
    let ssoURL = "https://api.kisi.io/login/"
    let callbackURL = "https:/catchme.exampledomain.something" // Must be HTTPS and needs to be whitelisted for the org.
    
    class Coordinator: NSObject, WKNavigationDelegate {
        @Environment(\.presentationMode) var presentationMode
        private let parent: SSOView
        private let authRemote = AuthRemote()
        let authStorage = AuthStorage.shared
        
        init(_ parent: SSOView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
            guard let redirectURL = webView.url?.absoluteString else { return }
            guard redirectURL.contains(parent.callbackURL) else { return }
            
            // We have been redirected to our callback our. Extract auth code
            let urlComponents = URLComponents(string: redirectURL)!
            guard let authCode = urlComponents.queryItems?.first(where: { $0.name == "auth_code" })?.value else { return }
            authRemote.resolve(code: authCode) { result in
                switch result {
                case .success(let login):
                    self.authStorage.store(login)
                    print("Signed in!") // We are now signed in...kill the app and start it again and it should show your places. This is an example app after all ;)
                case .failure:
                    print("oh no")
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView  {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let jsonString = "{\"origin\": \"\(callbackURL)\"}"
        print(jsonString)
        // Add domain to path
        var urlComponents = URLComponents(string: ssoURL + domain)!
        
        // URL encode RelayState parameter
        urlComponents.queryItems = [
            URLQueryItem(name: "RelayState", value: jsonString)
        ]
        
        let request = URLRequest(url: urlComponents.url!)
        
        // Load the request!
        uiView.load(request)
    }
    
}

#if DEBUG
struct WebView_Previews : PreviewProvider {
    static var previews: some View {
        SSOView(domain: "kisi")
    }
}
#endif

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
