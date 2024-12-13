//
//  HalfItemDetailViewController.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/08.
//

import UIKit

class HalfItemDetailViewController: UIViewController,UIScrollViewDelegate{
    var item: Item?
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var category: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let item = item else { return }
        
        scrollView.delegate = self
        name.text = item.name
        price.text = String(item.price)
        descriptionText.text = item.description
        category.text = item.category.rawValue
    }
}
