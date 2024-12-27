//
//  ItemsListener.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/25.
//

import FirebaseDatabase
import Combine

class ItemsListener: ObservableObject {
    @Published var items: [Item] = []
    private var cancellables: Set<AnyCancellable> = []

    init() {
        fetchItems()
    }

    func fetchItems() {
        FirebaseDatabasePublisher(path: "items")
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("エラー: \(error)")
                    }
                },
                receiveValue: { [weak self] snapshot in
                    self?.items = snapshot.compactMap { key, value -> Item? in
                        guard let dict = value as? [String: Any] else { return nil }
                        return Item(from: dict)
                    }
                }
            )
            .store(in: &cancellables)
    }
}
