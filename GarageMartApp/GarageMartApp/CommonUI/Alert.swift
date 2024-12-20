//
//  Alert.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/09.
//

import UIKit

extension UIViewController {
    /// 汎用的なエラーアラート表示メソッド
    func showErrorAlert(title: String = "エラー", message: String, buttonTitle: String = "OK") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default))
        self.present(alert, animated: true)
    }
    
    // アラートの表示とアクションを処理するメソッド
    func showAlertWithAction(
        title: String,
        message: String,
        buttonTitle: String = "OK",
        actionHandler: @escaping (UIAlertAction) -> Void,
        cancelActionHandler:((UIAlertAction) -> Void)? = nil
    ) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            // ボタンのアクションを設定
            let action = UIAlertAction(title: buttonTitle, style: .default) { action in
                // アクションが押されたときにクロージャを実行
                actionHandler(action)
            }
            // ボタンのアクションを設定
            if let cancelActionHandler = cancelActionHandler {
                let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: cancelActionHandler)
                alert.addAction(cancelAction)
            }
            
            // アラートにアクションを追加
            alert.addAction(action)
            
            // アラートを表示
            self.present(alert, animated: true, completion: nil)
    }
}

