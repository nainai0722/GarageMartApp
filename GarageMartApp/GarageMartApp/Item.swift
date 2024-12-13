//
//  Item.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/07.
//

import Foundation
import UIKit

/// アイテムカテゴリー一覧
enum ItemCategory:String,Codable,Equatable, Hashable,CaseIterable {
    /// 食べ物カテゴリ
    case food = "食品"
    case toy = "おもちゃ"
    case dailyGoods = "日用品"
    case others = "その他"
    case all = "すべて"
}

enum StockCategory:String,Codable,Equatable, Hashable,CaseIterable {
    case only = "一点限定"
    case few = "少しだけ"
    case many = "たくさんあります"
    case tooMuch = "多くて困ってます"
}


/// アイテムの構造体
///
/// id,商品名、説明事項、価格、カテゴリ、画像URL、位置情報、在庫数、および売り手のIDを管理します。
struct Item: Codable,Equatable,Hashable,Annotatable {
    var id:UUID
    var name: String
    var description :String
    var price : Int
    var category :ItemCategory
    var imageUrl: String
    var coordinate: Coordinate
    var stock: Int
    var stockCategory: StockCategory
    var groupId: String = "myGroup"
    var userId :String = "testUser"
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
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        price: Int,
        category: ItemCategory,
        imageUrl: String? = nil,
        coordinate: Coordinate,
        stock: Int,
        stockCategory: StockCategory,
        groupId: String = "myGroup",
        userId: String = "testUser",
        registeredDate: Date = Date(),
        eventID: UUID? = nil,
        image: UIImage? = nil
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
        self.coordinate = coordinate
        self.imageData = image?.jpegData(compressionQuality: 0.8)
    }

    
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
    func getImage() -> UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }
}
