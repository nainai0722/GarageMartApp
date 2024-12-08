//
//  GroupManager.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/08.
//

import Foundation

class GroupManager {
    func fetchGroups() {
        // Firebaseからグループ一覧を取得
        
    }
    func addGroup(group: GroupEntity) {
        // グループをFirebaseに追加
    }
}

struct GroupEntity {
    let id: String
    let name: String
    let password: String
    let members: [String]
}
