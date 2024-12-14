//
//  Book.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/13.
//

import Foundation

struct Book: Codable, Equatable {
    var id: String = UUID().uuidString
    var title:String
    var price :Int
    
    init(title:String, price:Int) {
        self.title = title
        self.price = price
    }
    
    init?(from dictionary: [String: Any]) {
            guard let id = dictionary["id"] as? String,
                  let title = dictionary["title"] as? String,
                  let price = dictionary["price"] as? Int else {
                return nil
            }
            self.id = id
            self.title = title
            self.price = price
        }
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "price": price
        ]
    }
}
