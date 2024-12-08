//
//  Group.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/08.
//

import Foundation

struct Group {
    var id = UUID()
    var name: String
    var password:String
    var createdBy:String
    var members:[String]
    
    init(name: String, password: String, createdBy: String, members: [String]) {
        self.name = name
        self.password = password
        self.createdBy = createdBy
        self.members = members
    }
    
    mutating func addMember(userId: String) {
        if !members.contains(userId) {
            members.append(userId)
        }
    }
    
    mutating func removeMember(userId: String) {
        members.removeAll { $0 == userId }
    }
}
