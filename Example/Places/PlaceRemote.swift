//
//  PlaceRemote.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import Foundation

class PlaceRemote {
    private let authStorage = AuthStorage.shared
    private let session = URLSession.shared
    
    func fetchPlaces(completion: @escaping (Result<[Place], Error>) -> Void) {
        guard let login = authStorage.currentLogin() else { return }
        
        var request = URLRequest(url: URL(string: "https://api.kisi.io/places")!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("KISI-LOGIN \(login.secret)", forHTTPHeaderField: "Authorization")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let data = data, let places = try? JSONDecoder().decode([Place].self, from: data) {
                DispatchQueue.main.async {
                    completion(.success(places))
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
