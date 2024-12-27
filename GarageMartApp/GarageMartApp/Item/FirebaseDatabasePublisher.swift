//
//  FirebaseDatabasePublisher.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/25.
//

import FirebaseDatabase
import Combine

struct FirebaseDatabasePublisher: Publisher {
    typealias Output = [String: Any]
    typealias Failure = Error

    let path: String

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let reference = Database.database().reference().child(path)
        let subscription = FirebaseDatabaseSubscription(subscriber: subscriber, reference: reference)
        subscriber.receive(subscription: subscription)
    }
}

class FirebaseDatabaseSubscription<S: Subscriber>: Subscription where S.Input == [String: Any], S.Failure == Error {
    private var subscriber: S?
    private let reference: DatabaseReference

    init(subscriber: S, reference: DatabaseReference) {
        self.subscriber = subscriber
        self.reference = reference
        listenForChanges()
    }

    func request(_ demand: Subscribers.Demand) {}

    func cancel() {
        subscriber = nil
    }

    private func listenForChanges() {
        reference.observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            guard let value = snapshot.value as? [String: Any] else {
                self.subscriber?.receive(completion: .failure(NSError(domain: "InvalidData", code: 0, userInfo: nil)))
                return
            }
            _ = self.subscriber?.receive(value)
        }
    }
}
