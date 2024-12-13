//
//  ItemAnnotation.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/08.
//

import MapKit

/// 地図上に表示するアイテムアノテーションの情報を保持するクラス
class ItemAnnotation: MKPointAnnotation {
    var item: Item
    init(item: Item) {
        self.item = item
        super.init()
        self.title = item.name
        self.subtitle = item.category.rawValue
        self.coordinate = CLLocationCoordinate2D(latitude: item.coordinate.latitude, longitude: item.coordinate.longitude)
    }
}
