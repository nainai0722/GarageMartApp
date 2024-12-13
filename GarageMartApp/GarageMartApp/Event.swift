//
//  Event.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/11.
//

import Foundation

struct Event:Codable,Annotatable {
    var id: UUID = UUID() // 一意の識別子
    var title: String // イベント名
    var description: String // イベントの説明
    var startDate: Date // イベントの開始日
    var endDate: Date // イベントの終了日
    var coordinate: Coordinate
    var imageData: Data?
    var createdAt: Date = Date() // 登録日時
    
    // 初期化メソッド
    init(title: String, description: String, startDate: Date, endDate: Date, coordinate: Coordinate, image: Data? = nil) {
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.coordinate = coordinate
        self.imageData = image
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case title
        case description
        case startDate
        case endDate
        case coordinate
        case imageData
        case createdAt
    }

    // 開催中かどうかを判定するメソッド
    func isActive(at date: Date = Date()) -> Bool {
        return date >= startDate && date <= endDate
    }
}
