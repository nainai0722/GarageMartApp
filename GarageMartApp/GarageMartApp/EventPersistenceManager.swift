//
//  EventPersistenceManager.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/12.
//

import Foundation
import FirebaseDatabase

/// イベントを扱うマネージャー構造体
class EventPersistenceManager {
    private let storageKey = "events"
    
    // 保存
    func save(event: Event) {
        do {
            let databaseRef = Database.database().reference()
            let eventData = event.toDictionary() //
               databaseRef.child(storageKey).childByAutoId().setValue(eventData) { error, ref in
                   if let error = error {
                       print("Error saving event: \(error.localizedDescription)")
                   } else {
                       print("Event saved successfully!")
                   }
               }
        } catch {
            print("Failed to save events: \(error)")
        }
    }
    
    // 読み込み
    func loadEvents(completion: @escaping ([Event]) -> Void) {
        let databaseRef = Database.database().reference()
        databaseRef.child(storageKey).observeSingleEvent(of: .value) { snapshot  in
            var events: [Event] = []

            guard let value = snapshot.value as? [String: [String: Any]] else {
                completion([])
                return
            }

            for (_, data) in value {
                if let event = Event(from: data) {
                    events.append(event)
                }
            }

            completion(events)
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
        for event in events {
            save(event: event)
        }
    }
}
