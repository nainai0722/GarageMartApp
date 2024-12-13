//
//  ItemDetalViewController.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/07.
//

import UIKit

class ItemDetailViewController: UIViewController {
    var item: Item?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var category: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let item = item else { return }
        
        name.text = item.name
        price.text = String(item.price)
        descriptionText.text = item.description
        category.text = item.category.rawValue
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
