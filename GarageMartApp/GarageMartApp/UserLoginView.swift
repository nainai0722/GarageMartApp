//
//  UserLoginView.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/16.
//

import SwiftUI

struct UserLoginView: View {
    // 入力されたメールアドレスとパスワードを保持する変数
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false // パスワード表示切り替えフラグ
    @State private var showAlert: Bool = false // アラートを表示するかのフラグ
    let onLogin: (String) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // タイトル
            Text("ログイン")
                .font(.largeTitle)
                .fontWeight(.bold)

            // メールアドレスの入力フィールド
            HStack {
                TextField("メールアドレス", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none) // 自動で大文字にしない
                    .keyboardType(.emailAddress) // メール用のキーボードを表示
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)

            // パスワードの入力フィールド
            HStack {
                if showPassword {
                    TextField("パスワード", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                } else {
                    SecureField("パスワード", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)

            // ログインボタン
            Button(action: {
                // ログイン処理を呼び出す（例として入力確認）
                if isFormValid() {
                    print("Logging in with email: \(email) and password: \(password)")
                    login()
                    
                } else {
                    showAlert = true
                }
            }) {
                Text("Login")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Invalid Input"), message: Text("Please enter a valid email and password."), dismissButton: .default(Text("OK")))
            }

            Spacer() // 画面下部に余白を追加
        }
        .padding()
    }

    // フォームの入力チェック関数
    private func isFormValid() -> Bool {
        let emailIsValid = !email.isEmpty && email.contains("@")
//        let passwordIsValid = password.count >= 8 && password.rangeOfCharacter(from: .uppercaseLetters) != nil && password.rangeOfCharacter(from: .lowercaseLetters) != nil && password.rangeOfCharacter(from: .decimalDigits) != nil
//        return emailIsValid && passwordIsValid
        return emailIsValid
    }
    private func login() {
        LoginManager.shared.loginWithEmailPassword(email: email, password: password, completion: { result in
            switch result {
            case .success:
                print("Login successful")
                onLogin(email)
            case .failure(let error):
                print("Login failed: \(error)")
            }
            
        })
    }
}

// プレビュー
struct UserLoginView_Previews: PreviewProvider {
    static var previews: some View {
        UserLoginView(onLogin:{ email in
            print("\(email)表示")
            
        })
    }
}

