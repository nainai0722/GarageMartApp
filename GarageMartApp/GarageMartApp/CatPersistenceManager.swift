//
//  CatPersistenceManager.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/22.
//

import Foundation
import FirebaseDatabase
import FirebaseStorage
import UIKit


/// アイテムを扱うマネージャークラス
class CatPersistenceManager {
    private let storageKey = "cats"
    
    // 保存
    func save(cat: Cat,completion: @escaping (Result<Cat, Error>)  -> Void) {
        let databaseRef = Database.database().reference()
        let storageKey = "cats"

        guard let imageData = cat.imageData else {
            print("Error: No image data found.")
            completion(.failure(ImageError.notFoundImageData))
            return
        }
        
        
        // 1. 画像データをアップロード
        uploadImage(cat,imageData) { result in
            switch result {
            case .success(let url):
                // 2. URLを取得してcat.imageUrlに設定
                let catData = cat.toDictionary(url: url)
                
                // 3. Firebase Realtime Databaseに保存
                databaseRef.child(storageKey).child(cat.id).setValue(catData) { error, ref in
                    if let error = error {
                        print("Error saving cat: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        print("Cat saved successfully!")
                        // このcatだとImageUrlが格納されていない
                        var savedCat = cat
                        savedCat.imageUrl = url
                        completion(.success(savedCat))
                    }
                }
                
            case .failure(let error):
                print("Error uploading image: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func uploadImage(_ cat: Cat,_ imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference().child("images/\(cat.id).jpg")
        
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

    func fetchImage(from cat:Cat, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // idをキーにして紐づいているローカルデータがあれば取得して返す
        if UserDefaults.standard.data(forKey: cat.id) != nil {
            guard let data = UserDefaults.standard.data(forKey: cat.id) else {
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
        let storageRef = Storage.storage().reference(forURL: cat.imageUrl)
        
        storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let data = data, let image = UIImage(data: data) {
                UserDefaults.standard.set(data, forKey: cat.id)
                completion(.success(image))
            }
        }
    }

    // 読み込み
    func loadCats(completion: @escaping ([Cat]) -> Void) {
        let databaseRef = Database.database().reference()
        databaseRef.child(storageKey).observeSingleEvent(of: .value) { snapshot in
            var cats: [Cat] = []

            guard let value = snapshot.value as? [String: [String: Any]] else {
                completion([])
                return
            }

            for (_, data) in value {
                if let cat = Cat(from: data) {
                    cats.append(cat)
                }
            }

            completion(cats)
        }
    }
    
    // 読み込み
    func load() -> [Cat] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        do {
            return try JSONDecoder().decode([Cat].self, from: data)
        } catch {
            print("Failed to load cats: \(error)")
            return []
        }
    }
    
    // 削除
    func delete(cat: Cat,completion: @escaping (Result<Cat, Error>)  -> Void) {
        let databaseRef = Database.database().reference()
        databaseRef.child(storageKey).child(cat.id).removeValue{ error, _ in
            if let error = error {
                print("delete Error.\(error)")
            }else {
                print("delete success!")
            }
        }
    }
}
