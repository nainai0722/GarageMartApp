//
//  HomeViewModel.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/25.
//

import FirebaseDatabase
import Combine

class HomeViewModel: ObservableObject {
    private var itemsListener = ItemsListener()
    @Published var items: [Item] = []
    @Published var events: [Event] = []
    @Published var cats: [Cat] = []
    private var cancellables: Set<AnyCancellable> = []
    private let persistenceManager = ItemPersistenceManager()
    
    init() {
        // Firebase リスナーの登録
        itemsListener.$items
            .sink { [weak self] items in
                self?.items = items
            }
            .store(in: &cancellables)
        itemsListener.$events
            .sink { [weak self] events in
                self?.events = events
            }
            .store(in: &cancellables)
        itemsListener.$cats
            .sink { [weak self] cats in
                self?.cats = cats
            }
            .store(in: &cancellables)
    }
    
    // アイテムを保存する
    func saveItem(item: Item,completion: @escaping (Result<Item, Error>)  -> Void) {
        persistenceManager.save(item: item) { [weak self] result in
            switch result {
            case .success(let savedItem):
                // 保存成功後の処理（例えば、リストに追加）
                self?.items.append(savedItem)
                completion(.success(savedItem))
            case .failure(let error):
                // エラー処理
                print("Error saving item: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    // アイテムを削除する
    func deleteItem(item: Item) {
        persistenceManager.delete(item: item) { [weak self] result in
            switch result {
            case .success:
                // 削除成功後の処理
                self?.items.removeAll { $0.id == item.id }
            case .failure(let error):
                // エラー処理
                print("Error deleting item: \(error)")
            }
        }
    }

    func replaceAnnotations(to items: [Item], createAnnotation: (Item) -> ItemAnnotation) {
        // アノテーションを置き換える処理
        
    }
}
