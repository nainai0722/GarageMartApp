//
//  ItemManager.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/07.
//

import Foundation

/// アイテムを扱うマネージャー構造体
class ItemPersistenceManager {
    private let storageKey = "items"
    
    // 保存
    func save(items: [Item]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save items: \(error)")
        }
    }
    
    // 読み込み
    func load() -> [Item] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        do {
            return try JSONDecoder().decode([Item].self, from: data)
        } catch {
            print("Failed to load items: \(error)")
            return []
        }
    }
    
    // 削除
    func delete(item: Item) {
        var items = load()
        items.removeAll { $0.id == item.id }
        save(items: items)
    }
}
