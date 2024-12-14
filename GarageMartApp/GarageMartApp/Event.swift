//
//  Event.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/11.
//

import Foundation

struct Event:Codable,Annotatable {
    var id: String = UUID().uuidString // 一意の識別子
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
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "description": description,
            "startDate": ISO8601DateFormatter().string(from: startDate), // DateをISO8601形式に変換
            "endDate": ISO8601DateFormatter().string(from: endDate), // DateをISO8601形式に変換
            "coordinate": [
                "latitude": coordinate.latitude,
                "longitude": coordinate.longitude
            ],
            "imageData": imageData?.base64EncodedString() ?? "", // DataをBase64文字列に変換
            "createdAt": ISO8601DateFormatter().string(from: createdAt) // 登録日時
        ]
    }
    

    
    init?(from dictionary: [String: Any]) {
        guard
            let id = dictionary["id"] as? String,
            let title = dictionary["title"] as? String,
            let description = dictionary["description"] as? String,
            let coordinateDict = dictionary["coordinate"] as? [String: Double],
            let latitude = coordinateDict["latitude"],
            let longitude = coordinateDict["longitude"],
            let startDateString = dictionary["startDate"] as? String,
            let startDate = ISO8601DateFormatter().date(from: startDateString),
            let endDateString = dictionary["endDate"] as? String,
            let endDate = ISO8601DateFormatter().date(from: endDateString),
            let createdAtString = dictionary["createdAt"] as? String,
            let createdAt = ISO8601DateFormatter().date(from: createdAtString)
        else {
            return nil
        }
        
        let imageData = dictionary["imageData"] as? Data

        self.id = id
        self.title = title
        self.description = description
        self.coordinate = Coordinate(latitude: latitude, longitude: longitude)
        self.startDate = startDate
        self.endDate = endDate
        self.imageData = (dictionary["imageData"] as? String)?.data(using: .utf8)?.base64EncodedData()
        self.createdAt = createdAt
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
