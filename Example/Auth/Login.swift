//
//  Login.swift
//  Example
//
//  Created by Joakim Gyllström on 2022-03-24.
//

import Foundation

struct Login: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case secret = "secret"
        case scram = "scram_credentials"
    }
    
    struct SCRAM: Codable {
        enum CodingKeys: String, CodingKey {
            case key = "phone_key"
            case certificate = "online_certificate"
        }
        
        var key: String
        var certificate: String
    }
    
    var id: Int
    var secret: String
    var scram: SCRAM
}
