//
//  LockRemote.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import Foundation

class LockRemote {
    private let authStorage = AuthStorage.shared
    private let session = URLSession.shared
    
    func fetchLocks(forPlace place: Place, completion: @escaping (Result<[Lock], Error>) -> Void) {
        guard let login = authStorage.currentLogin() else { return }
        
        var request = URLRequest(url: URL(string: "https://api.kisi.io/locks?place_id=\(place.id)")!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("KISI-LOGIN \(login.secret)", forHTTPHeaderField: "Authorization")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let data = data, let locks = try? JSONDecoder().decode([Lock].self, from: data) {
                DispatchQueue.main.async {
                    completion(.success(locks))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "b0rk", code: 1337)))
                }
            }
        }
        
        task.resume()
    }
    
    func unlock(_ lock: Lock, proof: Int?) {
        guard let login = authStorage.currentLogin() else { return }
        
        let parameters = [
            "lock": [
                "proximity_proof": proof ?? 0
            ]
        ]
        
        var request = URLRequest(url: URL(string: "https://api.kisi.io/locks/\(lock.id)/unlock")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("KISI-LOGIN \(login.secret)", forHTTPHeaderField: "Authorization")
        request.httpBody = try! JSONEncoder().encode(parameters)
        
        let task = session.dataTask(with: request) { data, response, error in

        }
        
        task.resume()
    }
}
