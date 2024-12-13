//
//  EventPersistenceManager.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/12.
//

import Foundation

/// イベントを扱うマネージャー構造体
class EventPersistenceManager {
    private let storageKey = "events"
    
    // 保存
    func save(events: [Event]) {
        do {
            let data = try JSONEncoder().encode(events)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save events: \(error)")
        }
    }
    
    // 読み込み
    func load() -> [Event] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        do {
            return try JSONDecoder().decode([Event].self, from: data)
        } catch {
            print("Failed to load events: \(error)")
            return []
        }
    }
    
    // 削除
    func delete(event: Event) {
        var events = load()
        events.removeAll { $0.id == event.id }
        save(events: events)
    }
}
