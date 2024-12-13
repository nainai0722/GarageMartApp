//
//  EventAnnotation.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/12.
//

import MapKit

/// 地図上に表示するアイテムアノテーションの情報を保持するクラス
class EventAnnotation: MKPointAnnotation {
    var event: Event
    init(event: Event) {
        self.event = event
        super.init()
        self.title = event.title
        let startDay = formatDateToJapaneseString(event.startDate)
        let endDay = formatDateToJapaneseString(event.endDate)
        self.subtitle = "\(startDay)から\(endDay)まで"
        self.coordinate = CLLocationCoordinate2D(latitude: event.coordinate.latitude, longitude: event.coordinate.longitude)
    }
    
    func formatDateToJapaneseString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return formatter.string(from: date)
    }
}
