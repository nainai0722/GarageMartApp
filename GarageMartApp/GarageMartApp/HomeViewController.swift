//
//  HomeViewController.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/07.
//

import UIKit
import MapKit

class HomeViewController: UIViewController,MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        print(mapView.delegate)
        // testItemsをループして、各アイテムの位置にアノテーションを追加
        for item in HomeViewController.testItems {
            let annotation = ItemAnnotation(item: item)
            mapView.addAnnotation(annotation)
        }
//        let visibleAnnotations = mapView.annotations.filter { $0 is MKPointAnnotation }
//        let visibleAnnotationCount = visibleAnnotations.count
//        print("表示されているアノテーションの数: \(visibleAnnotationCount)")

        let region = currentLocation()
        mapView.setRegion(region, animated: true)
    }
    
    // 吹き出しのアクセサリ（詳細ボタンなど）をタップしたとき
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let itemAnnotation = view.annotation as? ItemAnnotation else { return }
        // ItemDetailViewControllerを表示
        showItemDetail(for: itemAnnotation)
    }
    
    private func showItemDetail(for annotation: ItemAnnotation) {
        // 新しいStoryboardをインスタンス化
        let storyboard = UIStoryboard(name: "ItemDetailView", bundle: nil)
        
        // Storyboard IDを使ってViewControllerをインスタンス化
        if let viewController = storyboard.instantiateViewController(withIdentifier: "HalfItemDetailViewController") as? HalfItemDetailViewController, let sheet = viewController.sheetPresentationController {
            // アノテーションに基づいてデータを渡す
            viewController.item = annotation.item
            sheet.detents = [.medium()] // 親ビューの高さに応じたモーダルの高さを設定
            sheet.prefersGrabberVisible = true // 上部のドラッグ用のハンドルを表示
            present(viewController, animated: true, completion: nil)
        }
    }
    
    // アノテーションビューのカスタマイズ
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is ItemAnnotation {
            let identifier = "ItemAnnotationView"
            var view: MKMarkerAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
                view = dequeuedView
            } else {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                
                // 吹き出しにアイテム詳細を表示するカスタムビューを設定
                let detailButton = UIButton(type: .detailDisclosure)
                view.rightCalloutAccessoryView = detailButton
            }
            
            view.annotation = annotation
            return view
        }
        return nil
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
}

extension HomeViewController {
    static var testItems:[Item] = [
                            Item(name: "test1", description: "商品説明内容です", price: 100, category: "食品", imageUrl: "example.com", location: Location(latitude: 34.897987
, longitude: 135.398693), stock: 10, stockCategory: "少しだけ", sellerId: "nana"),
                            Item(name: "test2", description: "商品説明内容です", price: 0, category: "おもちゃ", imageUrl: "example.com", location: Location(latitude: 34.897939
                        , longitude: 135.398639), stock: 1, stockCategory: "一点限定", sellerId: "nana")
                            ]
    
    func currentLocation() -> MKCoordinateRegion {
        // Set the location coordinates for 川西市山原
        let latitude: CLLocationDegrees = 34.897987
        let longitude: CLLocationDegrees = 135.398693

        // Create a coordinate
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        // Set the span (zoom level)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // Adjust values for zoom

        // Create the region with the coordinate and span
        let region = MKCoordinateRegion(center: location, span: span)
        
        return region
    }
}
