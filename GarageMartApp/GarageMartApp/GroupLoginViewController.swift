//
//  GroupLoginViewController.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/08.
//

import UIKit

class GroupLoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // グループID/PWでログインする
        
        // Do any additional setup after loading the view.
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
