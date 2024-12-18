//
//  BasicUserPersistenceManager.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/18.
//

import Foundation
import FirebaseDatabase

/// ブックを扱うマネージャー構造体
class BasicUserPersistenceManager {
    private let storageKey = "BasicUser"
    
    // 保存
    func save(basicUser: BasicUser) {
        let databaseRef = Database.database().reference()
            // データを保存する
            let newItemRef = databaseRef.child(storageKey).childByAutoId()
            guard let autoId = newItemRef.key  else { return } // 自動生成されたIDを取得
            let basicUserData = basicUser.toDictionary(for: autoId) // BasicUser型を辞書に変換
        
            // 保存処理
            newItemRef.setValue(basicUserData)  { error, ref in
               if let error = error {
                   print("Error saving basicUser: \(error.localizedDescription)")
               } else {
                   print("BasicUser saved successfully!")
               }
           }
    }
    
    // 更新
    func update(basicUser: BasicUser) {
        let databaseRef = Database.database().reference()
        guard let id = basicUser.id else { return }
        let basicUserData = basicUser.toDictionary(for: id) // BasicUser型を辞書に変換
        // 既存データの更新
            databaseRef.child(storageKey).child(id).updateChildValues(basicUserData){ error, ref in
               if let error = error {
                   print("Error saving basicUser: \(error.localizedDescription)")
               } else {
                   print("BasicUser saved successfully!")
               }
           }
    }
    
    // 読み込み
    func loadBasicUsers(completion: @escaping ([BasicUser]) -> Void) {
        let databaseRef = Database.database().reference()
        databaseRef.child(storageKey).observeSingleEvent(of: .value) { snapshot in
            var basicUsers: [BasicUser] = []

            guard let value = snapshot.value as? [String: [String: Any]] else {
                completion([])
                return
            }

            for (_, data) in value {
                if let basicUser = BasicUser(from: data) {
                    basicUsers.append(basicUser)
                }
            }

            completion(basicUsers)
        }
    }

    
    // 削除
    func deleteBasicUser(withId id: String) {
        let databaseRef = Database.database().reference()
        databaseRef.child(storageKey).observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else { return }
            
            for (key, data) in value {
                if let basicUserData = data as? [String: Any],
                   let basicUserId = basicUserData["id"] as? String,
                   basicUserId == id {
                    databaseRef.child("basicUsers").child(key).removeValue()
                    print("BasicUser with id \(id) deleted.")
                    return
                }
            }
        }
    }

    func delete(named title: String) {
//        var basicUsers = load()
//        basicUsers.removeAll { $0.title.contains(title) }
//        for basicUser in basicUsers {
//            save(basicUser: basicUser)
//        }
    }
}
