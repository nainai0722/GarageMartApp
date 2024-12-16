//
//  EventPersistenceManager.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/12.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import UIKit

/// イベントを扱うマネージャー構造体
class EventPersistenceManager {
    private let storageKey = "events"
    
    // 保存
    func save(event: Event,completion: @escaping (Result<Event, Error>) -> Void) {
        do {
            let databaseRef = Database.database().reference()
            
            guard let imageData = event.imageData else {
                print("Error: No image data found.")
                completion(.failure(ImageError.notFoundImageData))
                return
            }
            
            uploadImage(imageData) { result in
                switch result {
                    case .success(let url):
                    // 2. URLを取得してitem.imageUrlに設定
                    let eventData = event.toDictionary(url: url)
                    
                    // 3. Firebase Realtime Databaseに保存
                    databaseRef.child(self.storageKey).childByAutoId().setValue(eventData) { error, ref in
                        if let error = error {
                            print("Error saving item: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else {
                            print("Item saved successfully!")
                            // このitemだとImageUrlが格納されていない
                            var savedEvent = event
                            savedEvent.imageUrl = url
                            completion(.success(savedEvent))
                        }
                    }
                    case .failure(let error):
                    print("Error uploading image: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        } catch {
            print("Failed to save events: \(error)")
        }
    }
    
    func uploadImage(_ imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference().child("images/\(UUID().uuidString).jpg")
        
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                if let downloadURL = url?.absoluteString {
                    completion(.success(downloadURL))
                }
            }
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
            save(event: event){ result in
                if case .success = result {
                    return
                }
                if case .failure(let error) = result {
                    print("Failed to delete item: \(error)")
                }
            }
        }
    }
}
