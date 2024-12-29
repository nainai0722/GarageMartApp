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
        let databaseRef = Database.database().reference()
        
        guard let imageData = event.imageData else {
            print("Error: No image data found.")
            completion(.failure(ImageError.notFoundImageData))
            return
        }
        
        uploadImage(event,imageData) { result in
            switch result {
                case .success(let url):
                // 2. URLを取得してitem.imageUrlに設定
                let eventData = event.toDictionary(url: url)
                
                // 3. Firebase Realtime Databaseに保存
                databaseRef.child(self.storageKey).child(event.id).setValue(eventData) { error, ref in
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
    }
    
    func uploadImage(_ event: Event,_ imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference().child("images/\(event.id).jpg")
        
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
    
    // 削除TODO: 削除のUI実装していない
    func delete(event: Event,completion: @escaping (Result<Event, Error>) -> Void) {
        let databaseRef = Database.database().reference()
        databaseRef.child(storageKey).child(event.id).removeValue{
            error, _ in
            if let error = error {
                print("delete Error.\(error)")
            }else {
                print("delete success!")
            }
        }
    }
}
