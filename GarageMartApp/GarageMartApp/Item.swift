//
//  Item.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/07.
//

import Foundation
import UIKit

/// アイテムカテゴリー一覧
enum ItemCategory:String,Codable,Equatable, Hashable,CaseIterable,Categorable {
    /// 食べ物カテゴリ
    case food = "食品"
    case toy = "おもちゃ"
    case dailyGoods = "日用品"
    case others = "その他"
    case all = "すべて"
}

enum StockCategory:String,Codable,Equatable, Hashable,CaseIterable,Categorable {
    case only = "一点限定"
    case few = "少しだけ"
    case many = "たくさんあります"
    case tooMuch = "多くて困ってます"
}


/// アイテムの構造体
///
/// id,商品名、説明事項、価格、カテゴリ、画像URL、位置情報、在庫数、および売り手のIDを管理します。
struct Item: Codable,Equatable,Hashable,Annotatable {
    var id:String = UUID().uuidString
    var name: String
    var description :String
    var price : Int
    var category :ItemCategory
    var imageUrl: String
    var coordinate: Coordinate
    var stock: Int
    var stockCategory: StockCategory
    var groupId: String = "myGroup"
    var userId :String
    var imageData: Data?
    let registeredDate: Date
    let eventID: UUID? // どのイベントに属しているかを関連付け
    
    enum CodingKeys: String, CodingKey,CaseIterable {
        case id
        case name
        case description
        case price
        case category
        case imageUrl
        case coordinate = "location" // 古いデータでは "location" を参照
        case stock
        case stockCategory
        case groupId
        case userId
        case imageData
        case registeredDate
        case eventID
    }
    
    init(
        id: String,
        name: String,
        description: String? = nil,
        price: Int,
        category: ItemCategory,
        imageUrl: String? = nil,
        coordinate: Coordinate,
        stock: Int,
        stockCategory: StockCategory,
        groupId: String = "myGroup",
        userId: String,
        registeredDate: Date = Date(),
        imageData:Data,
        eventID: UUID? = nil
    ) {
        guard price >= 0 else {
            fatalError("Price cannot be negative")
        }
        guard stock >= 0 else {
            fatalError("Stock cannot be negative")
        }
        
        self.id = id
        self.name = name
        self.description = description ?? ""
        self.price = price
        self.category = category
        self.imageUrl = imageUrl ?? ""
        self.coordinate = coordinate
        self.stock = stock
        self.stockCategory = stockCategory
        self.groupId = groupId
        self.userId = userId
        self.registeredDate = registeredDate
        self.eventID = eventID
        self.imageData = imageData
        self.coordinate = coordinate
    }
    
    func toDictionary(url: String) -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "description": description,
            "price": price,
            "category": category.rawValue, // インスタンスに基づく変換
            "imageUrl": url,
            "coordinate": [
                "latitude": coordinate.latitude,
                "longitude": coordinate.longitude
            ],
            "stock": stock,
            "stockCategory": stockCategory.rawValue, // インスタンスに基づく変換
            "groupId": groupId,
            "userId": userId,
            "registeredDate": ISO8601DateFormatter().string(from: registeredDate), // DateをISO8601形式で変換
            "eventID": eventID?.uuidString ?? "" // UUIDを文字列として保存
        ]
    }

    
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}
extension Item {
    init?(from dictionary: [String: Any]) {
        // 必須プロパティの変換と検証
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let description = dictionary["description"] as? String,
              let price = dictionary["price"] as? Int,
              let categoryRawValue = dictionary["category"] as? String,
              let category = ItemCategory(rawValue: categoryRawValue),
              let imageUrl = dictionary["imageUrl"] as? String,
              let coordinateDict = dictionary["coordinate"] as? [String: Any],
              let coordinate = Coordinate(from: coordinateDict),
              let stock = dictionary["stock"] as? Int,
              let stockCategoryRawValue = dictionary["stockCategory"] as? String,
              let stockCategory = StockCategory(rawValue: stockCategoryRawValue),
              let groupId = dictionary["groupId"] as? String,
              let userId = dictionary["userId"] as? String,
              let registeredDateString = dictionary["registeredDate"] as? String,
              let registeredDate = ISO8601DateFormatter().date(from: registeredDateString) else {
            return nil // 必須プロパティのどれかが変換に失敗した場合
        }

        // オプションプロパティの変換
        let imageData = dictionary["imageData"] as? Data
        let eventIDString = dictionary["eventID"] as? String
        let eventID = eventIDString != nil ? UUID(uuidString: eventIDString!) : nil

        // プロパティの設定
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.category = category
        self.imageUrl = imageUrl
        self.coordinate = coordinate
        self.stock = stock
        self.stockCategory = stockCategory
        self.groupId = groupId
        self.userId = userId
        self.imageData = imageData
        self.registeredDate = registeredDate
        self.eventID = eventID
    }
}
