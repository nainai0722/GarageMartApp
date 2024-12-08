//
//  HomeViewController.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/07.
//

import UIKit
import MapKit
import CoreLocation

class HomeViewController: UIViewController,UISearchBarDelegate,CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    let searchBar = UISearchBar()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        searchBar.placeholder = "アイテム検索"
        navigationItem.titleView = searchBar
        
        mapView?.delegate = self
        // デバッグ用のグループ情報を設定する
        checkDebugUserGroup()
        // testItemsをループして、各アイテムの位置にアノテーションを追加
        for item in HomeViewController.testItems {
            let annotation = ItemAnnotation(item: item)
            mapView.addAnnotation(annotation)
        }
//        let visibleAnnotations = mapView.annotations.filter { $0 is MKPointAnnotation }
//        let visibleAnnotationCount = visibleAnnotations.count
//        print("表示されているアノテーションの数: \(visibleAnnotationCount)")

//        let region = currentLocation()
//        mapView.setRegion(region, animated: true)
        // 位置情報マネージャの設定
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // ユーザーに位置情報の使用許可をリクエスト
        locationManager.requestWhenInUseAuthorization()
        
        // 位置情報の取得開始
        locationManager.startUpdatingLocation()
        
        // ユーザーの現在位置を表示する設定
        mapView.showsUserLocation = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 入力されたテキストに基づいて検索結果を更新
        filterItems(searchText: searchText)
    }
    
    func checkLoginState() {
        let groupID = UserDefaults.standard.string(forKey: "groupID")
        let userID = UserDefaults.standard.string(forKey: "userID")
        
        if let groupID = groupID, let userID = userID {
            // マップ画面に進む
            navigateToMap(groupID: groupID)
        } else {
            // 新規登録画面を表示
            showRegistrationButton()
        }
    }
    
    func filterItems(searchText:String) {
        let filteredByContainingNamed = ItemManager().items(containingNamed: searchText)
        let filteredByContainingDescribed = ItemManager().items(containingDescribed:searchText)
        // 配列同士の論理積を求める
        let commonItems = Set(filteredByContainingNamed).intersection(filteredByContainingDescribed)

        // アノテーションを追加
        mapView.removeAnnotations(mapView.annotations) // 既存アノテーションを削除
        for item in commonItems {
            let annotation = ItemAnnotation(item: item)
            mapView.addAnnotation(annotation)
        }
    }
    
    // 位置情報が更新されたときに呼び出される
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        
        // 現在位置を地図に表示
        let region = MKCoordinateRegion(center: userLocation.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
    }
    
    // 位置情報取得に失敗した場合
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error while updating location: \(error.localizedDescription)")
    }
    
    /// グループIDを指定してマップ上にアノテーションを載せて表示する
    /// - Parameter groupID: 指定するグループID
    func navigateToMap(groupID: String){
        let filteredByGroupID = ItemManager().items(where: { $0.groupId == groupID })
        for item in filteredByGroupID {
            let annotation = ItemAnnotation(item: item)
            mapView.addAnnotation(annotation)
        }
    }
    
    func showRegistrationButton() {
        // 新しいStoryboardをインスタンス化
        let storyboard = UIStoryboard(name: "GroupLoginView", bundle: nil)
        
        // Storyboard IDを使ってViewControllerをインスタンス化
        if let viewController = storyboard.instantiateViewController(withIdentifier: "GroupLoginViewController") as? GroupLoginViewController {
            // ViewControllerを表示
            self.navigationController?.pushViewController(viewController, animated: true)
        }
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
// MARK: アノテーション関連の処理
extension HomeViewController :MKMapViewDelegate {
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
}
// MARK: デバッグ用のデータ置き場
extension HomeViewController {
    static var testItems:[Item] = [
                            Item(name: "test1", description: "商品説明内容です", price: 100, category: "食品", imageUrl: "example.com", location: Location(latitude: 34.897987
                                                                                                                                                 , longitude: 135.398693), stock: 10, stockCategory: "少しだけ", groupId: "myGroup",userId: "nana"),
                            Item(name: "test2", description: "商品説明内容です", price: 0, category: "おもちゃ", imageUrl: "example.com", location: Location(latitude: 34.897939
                        , longitude: 135.398639), stock: 1, stockCategory: "一点限定", groupId: "myGroup",userId: "nana")
                            ]
    
    static var user = User(name: "nana", email: "test@email.com", additionalInfo: [:])
    
    static var group = Group(name: "myGroup", password: "123456", createdBy: "2024-12-07 21:46:30", members: [])
    
    func checkDebugUserGroup() {
        if UserDefaults.standard.string(forKey: "groupID") == nil {
            let groupID = HomeViewController.group.id.uuidString
            UserDefaults.standard.set(groupID, forKey: "groupID")
        }
        if UserDefaults.standard.string(forKey: "userID") == nil {
            let userID = HomeViewController.user.id.uuidString
            UserDefaults.standard.set(userID, forKey: "userID")
        }
    }

    
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
