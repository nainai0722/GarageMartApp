//
//  UserManager.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/08.
//

import Foundation

/// ユーザーを扱うマネージャー
class UserManager {
    private var users: [User] = []
    private var groups: [Group] = []
    
    func createUser(name: String) -> User {
        let user = User(name:name , email: "", additionalInfo: [:])
        users.append(user)
        return user
    }
    
    func addUserToGroup(userId: String, groupId: String) {
        guard let groupIndex = groups.firstIndex(where: { $0.id.uuidString == groupId }),
              let userIndex = users.firstIndex(where: { $0.id.uuidString == userId }) else {
            print("User or Group not found")
            return
        }
        
        groups[groupIndex].addMember(userId: userId)
        users[userIndex].groupId = groupId
    }
    
    func removeUserFromGroup(userId: String, groupId: String) {
        guard let groupIndex = groups.firstIndex(where: { $0.id.uuidString == groupId }),
              let userIndex = users.firstIndex(where: { $0.id.uuidString == userId }) else {
            print("User or Group not found")
            return
        }
        
        groups[groupIndex].removeMember(userId: userId)
        users[userIndex].groupId = nil
    }
}

