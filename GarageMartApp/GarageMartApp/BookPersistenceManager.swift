//
//  BookPersistenceManager.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/13.
//

import Foundation
import FirebaseDatabase

/// ブックを扱うマネージャー構造体
class BookPersistenceManager {
    private let storageKey = "books"
    
    // 保存
    func save(book: Book) {
        do {
            let databaseRef = Database.database().reference()
               let bookData = book.toDictionary() // Book型を辞書に変換
               databaseRef.child(storageKey).childByAutoId().setValue(bookData) { error, ref in
                   if let error = error {
                       print("Error saving book: \(error.localizedDescription)")
                   } else {
                       print("Book saved successfully!")
                   }
               }
        } catch {
            print("Bookの保存に失敗しました: \(error)")
        }
    }
    
    // 読み込み
    func loadBooks(completion: @escaping ([Book]) -> Void) {
        let databaseRef = Database.database().reference()
        databaseRef.child(storageKey).observeSingleEvent(of: .value) { snapshot in
            var books: [Book] = []

            guard let value = snapshot.value as? [String: [String: Any]] else {
                completion([])
                return
            }

            for (_, data) in value {
                if let book = Book(from: data) {
                    books.append(book)
                }
            }

            completion(books)
        }
    }

    
    // 削除
    func deleteBook(withId id: String) {
        let databaseRef = Database.database().reference()
        databaseRef.child(storageKey).observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else { return }
            
            for (key, data) in value {
                if let bookData = data as? [String: Any],
                   let bookId = bookData["id"] as? String,
                   bookId == id {
                    databaseRef.child("books").child(key).removeValue()
                    print("Book with id \(id) deleted.")
                    return
                }
            }
        }
    }

    func delete(named title: String) {
//        var books = load()
//        books.removeAll { $0.title.contains(title) }
//        for book in books {
//            save(book: book)
//        }
    }
}
