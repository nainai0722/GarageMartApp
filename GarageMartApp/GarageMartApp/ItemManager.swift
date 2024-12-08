//
//  ItemManager.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/07.
//

import Foundation

/// アイテムを扱うマネージャー構造体
struct ItemManager {
    var items:[Item] = []
    
    /// アイテムの数を返却する
    ///
    /// - Returns: アイテムの数
    func getItemNum() -> Int {
        return items.count
    }
    
    func getAllItems() -> [Item] {
        return items
    }

    /// 指定した条件に一致するアイテムの配列を返します。
    /// - Parameter predicate: アイテムをフィルタリングする条件
    /// - Returns: 条件に一致するアイテムの配列
    func items(where predicate: (Item) -> Bool) -> [Item] {
        return items.filter(predicate)
        // 使用例
//        let filteredByName = items(where: { $0.name == "Sample Item" })
//        let filteredByDescription = items(where: { $0.description == "Sample Description" })
    }



    
    /// 指定した名前と一致するアイテムの配列を返します。
    /// - Parameter name: 取得対象の名前
    /// - Returns: 指定された名前と一致するアイテムの配列
    func items(named name:String) -> [Item] {
        return items.filter(){ $0.name == name }
    }
    
    /// 指定した名前を部分的に含むアイテムの配列を返します（大文字小文字を無視）。
    /// - Parameter name: 部分一致で検索する名前の文字列
    /// - Returns: 指定された名前を部分的に含むアイテムの配列
    func items(containingNamed name: String) -> [Item] {
        let lowercaseName = name.lowercased()
        return items.filter { $0.name.lowercased().contains(lowercaseName) }
    }

    /// 指定した説明事項と一致するアイテムの配列を返します。
    /// - Parameter name: 取得対象の説明事項
    /// - Returns: 指定された説明事項と一致するアイテムの配列
    func items(describedAs description:String) -> [Item] {
        return items.filter(){ $0.description == description }
    }
    
    /// 指定した説明事項を部分的に含むアイテムの配列を返します（大文字小文字を無視）。
    /// - Parameter description: 部分一致で検索する説明事項の文字列
    /// - Returns: 指定された説明事項を部分的に含むアイテムの配列
    func items(containingDescribed description: String) -> [Item] {
        let lowercaseName = description.lowercased()
        return items.filter { $0.description.lowercased().contains(lowercaseName) }
    }
    
    /// 無料（price が 0）のアイテムを返します。
    /// - Returns: 無料アイテムの配列
    func freeItems() -> [Item] {
        return items.filter {$0.price == 0 }
    }

    /// 指定した金額以下のアイテムの配列を返します。
    /// - Parameter price: 取得対象の金額
    /// - Returns: 指定された金額以下のアイテムの配列
    func items(underPrice price: Int) -> [Item] {
        return items.filter {$0.price < price }
    }
    
    /// 指定した金額以上のアイテムの配列を返します。
    /// - Parameter price: 取得対象の金額
    /// - Returns: 指定された金額以上のアイテムの配列
    func items(upperPrice price: Int) -> [Item] {
        return items.filter {$0.price > price }
    }
    
    
    /// 指定した金額の範囲内のアイテムの配列を返します。
    /// - Parameters:
    ///   - underPrice: 取得対象の最低金額
    ///   - upperPrice: 取得対象の最高金額
    /// - Returns: 指定された範囲の金額のアイテムの配列
    func items(underPrice: Int, upperPrice: Int) -> [Item] {
        return items.filter { $0.price > underPrice && $0.price < upperPrice }
    }
    
    /// 指定したカテゴリに属するアイテムの配列を返します。
    ///
    /// - Parameter category: 取得対象のカテゴリ（`ItemCategory`）
    /// - Returns: 指定されたカテゴリに属するアイテムの配列
    func items(in category: ItemCategory)  -> [Item] {
        return items.filter(){ $0.category == category.rawValue }
    }
    
    func items(in location:Location) -> [Item] {
        return items.filter(){ $0.location.latitude == location.latitude && $0.location.longitude == location.longitude }
    }
    
    /// 指定した範囲内にあるアイテムを返す関数
    /// - Parameters:
    ///   - location: 検索の基準となる位置情報
    ///   - rangeKm: 検索範囲（キロメートル）
    /// - Returns: 指定範囲内のアイテム配列
    func items(near location: Location, within rangeKm: Double) -> [Item] {
        return items.filter { item in
            let distance = haversineDistance(
                lat1: location.latitude,
                lon1: location.longitude,
                lat2: item.location.latitude,
                lon2: item.location.longitude
            )
            return distance <= rangeKm
        }
    }
    

    /// 地球の半径（単位: キロメートル）
    let earthRadiusKm: Double = 6371.0

    /// 緯度経度間の距離を計算する関数
    /// - Parameters:
    ///   - lat1: 第1地点の緯度（度）
    ///   - lon1: 第1地点の経度（度）
    ///   - lat2: 第2地点の緯度（度）
    ///   - lon2: 第2地点の経度（度）
    /// - Returns: 2地点間の距離（キロメートル）
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let lat1Rad = lat1 * .pi / 180
        let lon1Rad = lon1 * .pi / 180
        let lat2Rad = lat2 * .pi / 180
        let lon2Rad = lon2 * .pi / 180

        let dlat = lat2Rad - lat1Rad
        let dlon = lon2Rad - lon1Rad

        let a = sin(dlat / 2) * sin(dlat / 2) +
                cos(lat1Rad) * cos(lat2Rad) * sin(dlon / 2) * sin(dlon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadiusKm * c
    }

}
