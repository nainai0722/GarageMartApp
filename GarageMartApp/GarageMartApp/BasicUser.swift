//
//  BasicUser.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/18.
//

struct BasicUser {
    var id :String? //サーバ側で連携するid
    var userId :String //wishListと紐づくuserId
    var userName :String
    var wishList:[String]
    
    init (userId: String,userName:String, wishList:[String]){
        self.userId = userId
        self.userName = userName
        self.wishList = wishList
    }
    
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let userId = dictionary["userId"] as? String,
              let userName = dictionary["userName"] as? String,
              let wishList = dictionary["wishList"] as? [String] else {
            return nil
        }
        self.id = id
        self.userId = userId
        self.userName = userName
        self.wishList = wishList
    }

    func toDictionary(for id:String) -> [String: Any] {
        return [
            "id": id,
            "userId" : userId,
            "userName": userName,
            "wishList": wishList
        ]
    }
}

