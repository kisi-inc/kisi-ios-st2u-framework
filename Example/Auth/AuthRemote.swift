//
//  AuthRemote.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import Foundation

class AuthRemote {
    private let session = URLSession.shared
    
    func authenticate(email: String, password: String, domain: String, completion: @escaping (Result<Login, Error>) -> Void) {
        let parameters = [
            "user": [
                "domain": domain,
                "email": email,
                "password": password
            ]
        ]
        
        var request = URLRequest(url: URL(string: "https://api.kisi.io/logins")!)
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(parameters)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let data = data, let login = try? JSONDecoder().decode(Login.self, from: data) {
                DispatchQueue.main.async {
                    completion(.success(login))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "b0rk", code: 1337)))
                }
            }
        }
        
        task.resume()
    }
    
    func resolve(code: String, completion: @escaping (Result<Login, Error>) -> Void) {
        let parameters = [
            "login": [
                "resolution_token": code
            ]
        ]
        
        var request = URLRequest(url: URL(string: "https://api.kisi.io/logins/resolve")!)
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(parameters)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let data = data, let login = try? JSONDecoder().decode(Login.self, from: data) {
                DispatchQueue.main.async {
                    completion(.success(login))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "b0rk", code: 1337)))
                }
            }
        }
        
        task.resume()
    }
}
