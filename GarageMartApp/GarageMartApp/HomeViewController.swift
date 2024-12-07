//
//  HomeViewController.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/07.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func toItemRegistrationView(_ sender: Any) {
        // 新しいStoryboardをインスタンス化
        let storyboard = UIStoryboard(name: "ShoppingItemRegistrationView", bundle: nil)
        
        // Storyboard IDを使ってViewControllerをインスタンス化
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ShoppingItemRegistrationViewController") as? ShoppingItemRegistrationViewController {
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
