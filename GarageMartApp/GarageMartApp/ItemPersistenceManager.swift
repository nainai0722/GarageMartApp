//
//  ItemManager.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/07.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import UIKit
//import AppIntents
//import CoreTransferable

enum ImageError:Error {
    case notFoundImageData
}

/// アイテムを扱うマネージャークラス
class ItemPersistenceManager {
    private let storageKey = "items"
    
    // 保存
    func save(item: Item,completion: @escaping (Result<Item, Error>)  -> Void) {
        let databaseRef = Database.database().reference()
        let storageKey = "items"

        guard let imageData = item.imageData else {
            print("Error: No image data found.")
            completion(.failure(ImageError.notFoundImageData))
            return
        }

        // 1. 画像データをアップロード
        uploadImage(imageData) { result in
            switch result {
            case .success(let url):
                // 2. URLを取得してitem.imageUrlに設定
                let itemData = item.toDictionary(url: url)
                
                // 3. Firebase Realtime Databaseに保存
                databaseRef.child(storageKey).childByAutoId().setValue(itemData) { error, ref in
                    if let error = error {
                        print("Error saving item: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        print("Item saved successfully!")
                        // このitemだとImageUrlが格納されていない
                        var savedItem = item
                        savedItem.imageUrl = url
                        completion(.success(savedItem))
                    }
                }
                
            case .failure(let error):
                print("Error uploading image: \(error.localizedDescription)")
                completion(.failure(error))
            }
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
    
    enum UserDefaultsError:Error{
        case notFoundDataById
        case failedImageFromData
    }

    func fetchImage(from item:Item, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // idをキーにして紐づいているローカルデータがあれば取得して返す
        if UserDefaults.standard.data(forKey: item.id) != nil {
            guard let data = UserDefaults.standard.data(forKey: item.id) else {
                completion(.failure(UserDefaultsError.notFoundDataById))
                return
            }
            guard let image = UIImage(data: data) else {
                completion(.failure(UserDefaultsError.failedImageFromData))
                return
            }
            completion(.success(image))
            return
        }
        let storageRef = Storage.storage().reference(forURL: item.imageUrl)
        
        storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let data = data, let image = UIImage(data: data) {
                UserDefaults.standard.set(data, forKey: item.id)
                completion(.success(image))
            }
        }
    }

    // 読み込み
    func loadItems(completion: @escaping ([Item]) -> Void) {
        let databaseRef = Database.database().reference()
        databaseRef.child(storageKey).observeSingleEvent(of: .value) { snapshot in
            var items: [Item] = []

            guard let value = snapshot.value as? [String: [String: Any]] else {
                completion([])
                return
            }

            for (_, data) in value {
                if let item = Item(from: data) {
                    items.append(item)
                }
            }

            completion(items)
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
        for item in items {
            save(item: item){ result in
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
