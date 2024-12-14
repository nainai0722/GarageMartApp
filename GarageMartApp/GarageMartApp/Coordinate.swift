//
//  Location.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/07.
//

import Foundation

struct Coordinate:Codable,Equatable, Hashable{
    var latitude: Double
    var longitude: Double
}
extension Coordinate {
    init?(from dictionary: [String: Any]) {
        guard let latitude = dictionary["latitude"] as? Double,
              let longitude = dictionary["longitude"] as? Double else {
            return nil
        }
        self.latitude = latitude
        self.longitude = longitude
    }
}

