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
}

