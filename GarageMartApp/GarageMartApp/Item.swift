//
//  Item.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/07.
//

import Foundation

/// アイテムカテゴリー一覧
enum ItemCategory:String,Equatable, Hashable {
    /// 食べ物カテゴリ
    case food = "食べ物"
    case toy = "おもちゃ"
    case dailyGoods = "日用品"
    case others = "その他"
}

enum StockCategory:String,Equatable, Hashable {
    case only = "一点限定"
    case few = "少しだけ"
    case many = "たくさんあります"
    case tooMuch = "多くて困ってます"
}


/// アイテムの構造体
///
/// id,商品名、説明事項、価格、カテゴリ、画像URL、位置情報、在庫数、および売り手のIDを管理します。
struct Item: Codable,Equatable,Hashable {
    var id = UUID()
    var name: String
    var description :String
    var price : Int
    var category :ItemCategory.RawValue
    var imageUrl: String
    var location: Location
    var stock: Int
    var stockCategory: StockCategory.RawValue
    var groupId: String
    var userId :String
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}
