//
//  Cat.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/22.
//

import Foundation

/// 猫の構造体
///
/// id,商品名、説明事項、価格、カテゴリ、画像URL、位置情報、在庫数、および売り手のIDを管理します。
struct Cat: Identifiable,Codable,Equatable,Hashable,Annotatable {
    var id:String = UUID().uuidString
    var name: String
    var description: String
    var pattern: Pattern
    var colorCategory:ColorCategory
    var healthStatus: HealthStatus
    var ageCategory: AgeCategory
    var imageUrl: String
    var coordinate: Coordinate
    var userId: String
    var imageData: Data?
    let registeredDate: Date
    
    enum CodingKeys: String, CodingKey,CaseIterable {
        case id
        case name
        case description
        case pattern
        case colorCategory
        case healthStatus
        case ageCategory
        case imageUrl
        case coordinate = "location" // 古いデータでは "location" を参照
        case userId
        case registeredDate
        case imageData
    }
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        pattern: Pattern = .bicolor,
        colorCategory: ColorCategory = .black,
        healthStatus: HealthStatus = .good,
        ageCategory: AgeCategory = .adult,
        imageUrl: String? = nil,
        coordinate: Coordinate = Coordinate(latitude: 0.0, longitude: 0.0),
        userId: String = "TestUser",
        registeredDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description ?? ""
        self.pattern = pattern
        self.colorCategory = colorCategory
        self.healthStatus = healthStatus
        self.ageCategory = ageCategory
        self.imageUrl = imageUrl ?? ""
        self.coordinate = coordinate
        self.userId = userId
        self.registeredDate = registeredDate
    }
    
    init(
        id: String,
        name: String,
        description: String? = nil,
        pattern: Pattern,
        colorCategory: ColorCategory,
        healthStatus: HealthStatus,
        ageCategory: AgeCategory,
        imageUrl: String? = nil,
        coordinate: Coordinate,
        userId: String,
        registeredDate: Date = Date(),
        imageData:Data? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description ?? ""
        self.pattern = pattern
        self.colorCategory = colorCategory
        self.healthStatus = healthStatus
        self.ageCategory = ageCategory
        self.imageUrl = imageUrl ?? ""
        self.coordinate = coordinate
        self.userId = userId
        self.registeredDate = registeredDate
        self.imageData = imageData
    }
    
    func toDictionary(url: String) -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "description": description,
            "pattern": pattern.rawValue,
            "colorCategory": colorCategory.rawValue,
            "healthStatus": healthStatus.rawValue,
            "ageCategory": ageCategory.rawValue,
            "imageUrl": url,
            "coordinate": [
                "latitude": coordinate.latitude,
                "longitude": coordinate.longitude
            ],
            "userId": userId,
            "registeredDate": ISO8601DateFormatter().string(from: registeredDate), // DateをISO8601形式で変換
        ]
    }

    
    static func == (lhs: Cat, rhs: Cat) -> Bool {
        lhs.id == rhs.id
    }
}
extension Cat {
    init?(from dictionary: [String: Any]) {
        // 必須プロパティの変換と検証
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let description = dictionary["description"] as? String,
              let patternRawValue = dictionary["pattern"] as? String,
              let pattern = Pattern(rawValue: patternRawValue),
              let colorCategoryRawValue = dictionary["colorCategory"] as? String,
              let colorCategory = ColorCategory(rawValue: colorCategoryRawValue),
              let healthStatusRawValue = dictionary["healthStatus"] as? String,
              let healthStatus = HealthStatus(rawValue: healthStatusRawValue),
              let ageCategoryRawValue = dictionary["ageCategory"] as? String,
              let ageCategory = AgeCategory(rawValue: ageCategoryRawValue),
              let imageUrl = dictionary["imageUrl"] as? String,
              let coordinateDict = dictionary["coordinate"] as? [String: Any],
              let coordinate = Coordinate(from: coordinateDict),
              let userId = dictionary["userId"] as? String,
              let registeredDateString = dictionary["registeredDate"] as? String,
              let registeredDate = ISO8601DateFormatter().date(from: registeredDateString) else {
            return nil // 必須プロパティのどれかが変換に失敗した場合
        }

        // オプションプロパティの変換
        let imageData = dictionary["imageData"] as? Data

        // プロパティの設定
        self.id = id
        self.name = name
        self.description = description
        self.pattern = pattern
        self.colorCategory = colorCategory
        self.healthStatus = healthStatus
        self.ageCategory = ageCategory
        self.imageUrl = imageUrl
        self.coordinate = coordinate
        self.userId = userId
        self.imageData = imageData
        self.registeredDate = registeredDate
    }
}

/// 猫の模様
enum Pattern:String,Codable,Equatable, Hashable,CaseIterable,Categorable {
    case solid = "無地"
    case tabby = "トラ猫"
    case spotted = "まだら模様"
    case tuxedo = "ハチワレ"
    case calico = "三毛猫"
    case bicolor = "二毛猫"
    case mackerelTabby = "縞模様のトラ猫"
    case pointed = "シャム猫"
}

enum ColorCategory:String,Codable,Equatable, Hashable,CaseIterable,Categorable {
    case black = "黒色"
    case white = "白色"
    case gray = "灰色"
    case yellow = "黄色"
    case brown = "茶色"
    case orange = "オレンジ色"     // オレンジ色の猫（例：アメリカンショートヘアのオレンジ色）
    case other = "その他"
}

enum HealthStatus: String,Codable,Equatable, Hashable,CaseIterable,Categorable {
    case good = "健康"
    case bad = "病気"
    case notGood = "良くない"
    case usual = "問題ない"
}

enum AgeCategory:String,Codable,Equatable, Hashable,CaseIterable,Categorable {
    case kitten = "子猫"
    case adult = "成猫"
    case senior = "老猫"
}


