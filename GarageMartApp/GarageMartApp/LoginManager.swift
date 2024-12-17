//
//  LoginManager.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/16.
//

import Combine
import Foundation
import FirebaseAuth

struct LoginManager {
    static let shared = LoginManager()
    
    func getUserID() -> String? {
        return getUserIDFromKeychain()
    }
    
    mutating func updateUserID(_ id: String) {
        saveUserIDToKeychain(id)
    }
    
    mutating func logout() {
        deleteUserIDFromKeychain()
    }
    
    func loginWithEmailPassword(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = authResult?.user {
                user.getIDToken { token, error in
                    if let token = token {
                        saveTokenToKeychain(token)
                        saveUserIDToKeychain(user.uid)
                        completion(.success(()))
                    } else {
                        completion(.failure(error ?? NSError(domain: "TokenError", code: -1, userInfo: nil)))
                    }
                }
            }
        }
    }
    
    func saveTokenToKeychain(_ token: String) {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "authToken",
            kSecValueData as String: token.data(using: .utf8)!
        ]
        

        SecItemDelete(keychainQuery as CFDictionary) // 既存の値を削除
        SecItemAdd(keychainQuery as CFDictionary, nil) // 新しい値を追加
    }
    
    private func saveUserIDToKeychain(_ userID: String) {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userID",
            kSecValueData as String: userID.data(using: .utf8)!
        ]
        SecItemDelete(keychainQuery as CFDictionary)
        SecItemAdd(keychainQuery as CFDictionary, nil)
    }
    private func deleteUserIDFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userID"
        ]
        SecItemDelete(query as CFDictionary)
    }

    
    func checkToken() -> Bool {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "authToken",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject? = nil
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let tokenData = dataTypeRef as? Data, let token = String(data: tokenData, encoding: .utf8) {
            print("Token exists: \(token)")
            return true
        } else {
            print("Token not found")
            return false
        }
    }
    
    mutating func checkUserID() -> Bool {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userID",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject? = nil
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let userIdData = dataTypeRef as? Data, let userId = String(data: userIdData, encoding: .utf8) {
            print("UserID exists: \(userId)")
            return true
        } else {
            print("UserID not found")
            return false
        }
    }
    
    private func getUserIDFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userID",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess {
            if let data = item as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }

    
    func retryAccessToken(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }

        user.getIDToken { token, error in
            if let token = token {
                saveTokenToKeychain(token)
                saveUserIDToKeychain(user.uid)
                completion(.success(()))
            } else {
                completion(.failure(error ?? NSError(domain: "TokenError", code: -1, userInfo: nil)))
            }
        }
    }
    
}
