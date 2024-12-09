//
//  GroupLoginViewController.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/08.
//

import UIKit
import FirebaseAuth

enum inputError:Error {
    case nameBlank
    case passwordBlank
}

class GroupLoginViewController: UIViewController {

    @IBOutlet weak var groupName: UITextField!
    @IBOutlet weak var groupPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // グループID/PWでログインする
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        
        do {
            let (name, password) = try validateFields()
            
            Auth.auth().createUser(withEmail: name, password: password) { authResult, error in
                if let error = error {
                    print("Error signing up: \(error.localizedDescription)")
                    return
                }
                print("User signed up successfully!")
            }
        }catch inputError.nameBlank{
            showErrorAlert(message: "名前が空です")
        }catch  inputError.passwordBlank {
            showErrorAlert(message: "パスワードが空です")
        }catch {
            showErrorAlert(message: "予測不明なエラーです。")
        }
    }
    
    func validateFields() throws -> (String, String) {
        guard let currentName = groupName.text,!currentName.isEmpty
        else {
            throw inputError.nameBlank
        }
        guard let currentPassword = groupPassword.text,!currentPassword.isEmpty
        else {
            throw inputError.passwordBlank
        }
        return (currentName, currentPassword)
    }
    
    @IBAction func toUserRegistrationView(_ sender: Any) {
        // 新しいStoryboardをインスタンス化
        let storyboard = UIStoryboard(name: "UserRegistrationView", bundle: nil)
        
        // Storyboard IDを使ってViewControllerをインスタンス化
        if let viewController = storyboard.instantiateViewController(withIdentifier: "UserRegistrationViewController") as? UserRegistrationViewController {
            // ViewControllerを表示
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
