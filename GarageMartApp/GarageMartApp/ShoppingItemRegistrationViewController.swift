//
//  ShoppingItemRegistrationViewController.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/07.
//

import UIKit
import MapKit
enum ItemInputError:Error {
    case nameBlank
    case descriptionBlank
    case priceBlank
}
class ShoppingItemRegistrationViewController: UIViewController {
    var coordinate:CLLocationCoordinate2D?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var itemName: UITextField!
    @IBOutlet weak var itemDescription: UITextView!
    @IBOutlet weak var itemPrice: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func photoLibrarySelectTapped(_ sender: Any) {
    }
    
    @IBAction func registrationButtonTapped(_ sender: Any) {
        do {
            let (name, description,price) = try validateFields()
            var itemManager = ItemManager()
            guard let coordinate = coordinate else { return }
            let location = Location(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let newItem = Item(name: name, description: description, price: price, category: "おもちゃ", imageUrl: "", location:location, stock: 1, stockCategory: "1点限定", groupId: "myGroup", userId: "nana")
            itemManager.addItem(item:newItem)
        }catch ItemInputError.nameBlank{
            showErrorAlert(message: "商品名が空です")
        }catch  ItemInputError.descriptionBlank {
            showErrorAlert(message: "説明事項が空です")
        }catch ItemInputError.priceBlank {
            showErrorAlert(message: "価格が空です")
        }catch {
            showErrorAlert(message: "予測不明なエラーです。")
        }
    }
    
    func validateFields() throws -> (String, String, Int) {
        guard let name = itemName.text,!name.isEmpty
        else {
            throw ItemInputError.nameBlank
        }
        guard let description = itemDescription.text,!description.isEmpty
        else {
            throw ItemInputError.descriptionBlank
        }
        guard let priceString = itemPrice.text,!priceString.isEmpty, let price = Int(priceString), price >= 0
        else {
            throw ItemInputError.priceBlank
        }
        return (name, description,price)
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
