//
//  AuthStorage.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import Foundation

// Insecure auth storage...don't use UserDefaults for storing tokens in a production app!
class AuthStorage {
    static let shared = AuthStorage()
    
    struct Keys {
        static let id = "de.kisi.example.id"
        static let secret = "de.kisi.example.secret"
        static let scramKey = "de.kisi.example.scramKey"
        static let scramCertificate = "de.kisi.example.scramCertificate"
    }
    
    private let defaults = UserDefaults.standard
    private var login: Login?
    
    init() {
        login = fetch()
    }
    
    func store(_ login: Login) {
        self.login = login
        defaults.set(login.id, forKey: Keys.id)
        defaults.set(login.secret, forKey: Keys.secret)
        defaults.set(login.scram.key, forKey: Keys.scramKey)
        defaults.set(login.scram.certificate, forKey: Keys.scramCertificate)
    }
    
    func currentLogin() -> Login? {
        return login
    }
    
    func clear() {
        login = nil
        defaults.removeObject(forKey: Keys.id)
        defaults.removeObject(forKey: Keys.secret)
        defaults.removeObject(forKey: Keys.scramKey)
        defaults.removeObject(forKey: Keys.scramCertificate)
    }
    
    private func fetch() -> Login? {
        let id = defaults.integer(forKey: Keys.id)
        guard let secret = defaults.string(forKey: Keys.secret) else { return nil }
        guard let scramKey = defaults.string(forKey: Keys.scramKey) else { return nil }
        guard let scramCertificate = defaults.string(forKey: Keys.scramCertificate) else { return nil }
        
        return Login(id: id, secret: secret, scram: .init(key: scramKey, certificate: scramCertificate))
    }
}
