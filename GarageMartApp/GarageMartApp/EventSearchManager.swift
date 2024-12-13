//
//  EventSearchManager.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/12.
//

import Foundation

/// アイテムを条件絞り込んで検索する
class EventSearchManager {
    var events:[Event] = []
    
    init(events: [Event]) {
        self.events = events
    }

    /// 指定した条件に一致するアイテムの配列を返します。
    /// - Parameter predicate: アイテムをフィルタリングする条件
    /// - Returns: 条件に一致するアイテムの配列
    func events(where predicate: (Event) -> Bool) -> [Event] {
        return events.filter(predicate)
        // 使用例
//        let filteredByName = events(where: { $0.name == "Sample Event" })
//        let filteredByDescription = events(where: { $0.description == "Sample Description" })
    }

    /// 指定した名前と一致するアイテムの配列を返します。
    /// - Parameter title: 取得対象の名前
    /// - Returns: 指定された名前と一致するアイテムの配列
    func events(title:String) -> [Event] {
        return events.filter(){ $0.title == title }
    }
    
    /// 指定した名前を部分的に含むアイテムの配列を返します（大文字小文字を無視）。
    /// - Parameter name: 部分一致で検索する名前の文字列
    /// - Returns: 指定された名前を部分的に含むアイテムの配列
    func events(containingTitle title: String) -> [Event] {
        let lowercaseTitle = title.lowercased()
        return events.filter { $0.title.lowercased().contains(lowercaseTitle) }
    }

    /// 指定した説明事項と一致するアイテムの配列を返します。
    /// - Parameter name: 取得対象の説明事項
    /// - Returns: 指定された説明事項と一致するアイテムの配列
    func events(describedAs description:String) -> [Event] {
        return events.filter(){ $0.description == description }
    }
    
    func events(in coordinate:Coordinate) -> [Event] {
        return events.filter(){ $0.coordinate.latitude == coordinate.latitude && $0.coordinate.longitude == coordinate.longitude }
    }
    
    /// 指定した範囲内にあるアイテムを返す関数
    /// - Parameters:
    ///   - coordinate: 検索の基準となる位置情報
    ///   - rangeKm: 検索範囲（キロメートル）
    /// - Returns: 指定範囲内のアイテム配列
    func events(near coordinate: Coordinate, within rangeKm: Double) -> [Event] {
        return events.filter { event in
            let distance = haversineDistance(
                lat1: coordinate.latitude,
                lon1: coordinate.longitude,
                lat2: event.coordinate.latitude,
                lon2: event.coordinate.longitude
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
