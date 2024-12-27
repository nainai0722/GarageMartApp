//
//  CatAnnotation.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/27.
//

import MapKit

/// 地図上に表示するアイテムアノテーションの情報を保持するクラス
class CatAnnotation: MKPointAnnotation {
    var cat: Cat
    init(cat: Cat) {
        self.cat = cat
        super.init()
        self.title = cat.name
        self.subtitle = cat.pattern.rawValue
        self.coordinate = CLLocationCoordinate2D(latitude: cat.coordinate.latitude, longitude: cat.coordinate.longitude)
    }
}
