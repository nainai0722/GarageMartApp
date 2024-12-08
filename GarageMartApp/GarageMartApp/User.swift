//
//  User.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/08.
//

import Foundation

struct User: Codable {
    var id = UUID()
    var name :String
    var email:String
    var groupId :String?
    var additionalInfo:[String: String]
    
    init(name: String, email: String, groupId: String? = nil, additionalInfo: [String : String]) {
        self.name = name
        self.email = email
        self.groupId = groupId
        self.additionalInfo = additionalInfo
    }
}
