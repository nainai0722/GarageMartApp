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
    var items:[Item] = []
    
    @IBOutlet weak var groupLoginButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        searchBar.placeholder = "アイテム検索"
        navigationItem.titleView = searchBar
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressRecognizer.minimumPressDuration = 0.5 // 長押し判定の時間（秒）
        mapView.addGestureRecognizer(longPressRecognizer)
        
        mapView?.delegate = self
        // デバッグ用のグループ情報を設定する
        checkDebugUserGroup()
        checkLoginState()
        var itemManager = ItemManager()
        items = itemManager.debugItems()
        // 各アイテムの位置にアノテーションを追加
        for item in items {
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
        
        generateCategoryButton()
        
    }
    
    func generateCategoryButton() {
        let categories = ["食品", "おもちゃ", "その他","すべて"] // ItemCategoryのデータ
        var buttons: [UIButton] = []
        // ボタン生成
        for (index, category) in categories.enumerated() {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: view.frame.width - 80, y: view.frame.height - 150 - CGFloat(index * 70), width: 60, height: 60)
            button.backgroundColor = .systemBlue
            button.layer.cornerRadius = 30
            button.setTitle(category, for: .normal)
            button.tag = index // ボタン識別用
            if category == "すべて" {
                button.addTarget(self, action: #selector(allCategoriesButtonTapped), for: .touchUpInside)
            }else{
                button.addTarget(self, action: #selector(categoryButtonTapped(_:)), for: .touchUpInside)
            }
            // 配列に追加
            buttons.append(button)
            view.addSubview(button) // 画面に追加
        }
    }
    
    @objc func categoryButtonTapped(_ sender: UIButton) {
        let categories = ["食品", "おもちゃ", "その他"] // ItemCategoryのデータ
        let selectedCategory = categories[sender.tag]
        print("\(selectedCategory) ボタンがタップされました！")

        // 選択されたカテゴリに基づいて地図を操作する関数を呼び出す
        focusOnCategory(category: selectedCategory)
    }
    
    func focusOnCategory(category: String) {
        let filteredItems = items.filter { $0.category == category }
        guard !filteredItems.isEmpty else { return }

        var coordinates: [CLLocationCoordinate2D] = []
        for item in filteredItems {
            let coordinate = CLLocationCoordinate2D(latitude: item.location.latitude, longitude: item.location.longitude)
            coordinates.append(coordinate)
        }

        let annotations = coordinates.map { coordinate -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            return annotation
        }
        mapView.addAnnotations(annotations)

        // 中心座標を計算
        let centerLatitude = coordinates.map { $0.latitude }.reduce(0, +) / Double(coordinates.count)
        let centerLongitude = coordinates.map { $0.longitude }.reduce(0, +) / Double(coordinates.count)
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)

        // 中心点を基にMKCoordinateRegionを作成
        let region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: 500, longitudinalMeters: 500)

        mapView.setRegion(region, animated: true)
    }
    
    @objc func allCategoriesButtonTapped() {
        // 全ての座標を取得
        var allCoordinates: [CLLocationCoordinate2D] = []
        for item in items {
            let coordinate = CLLocationCoordinate2D(latitude: item.location.latitude, longitude: item.location.longitude)
            allCoordinates.append(coordinate)
        }
        
        // 地図の表示範囲を全ての座標に合わせる
        fitMapToCoordinates(allCoordinates)
    }

    // 地図を全座標に合わせるメソッド
    func fitMapToCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else { return }
        
        // 座標の最小・最大値を計算
        var minLat = coordinates.first!.latitude
        var maxLat = coordinates.first!.latitude
        var minLon = coordinates.first!.longitude
        var maxLon = coordinates.first!.longitude
        
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        // 緯度・経度の中心を計算
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        
        // 緯度・経度の範囲を計算
        let spanLat = (maxLat - minLat) * 1.2 // 少し余裕を持たせる
        let spanLon = (maxLon - minLon) * 1.2
        
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon))
        mapView.setRegion(region, animated: true)
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
            groupLoginButton.isHidden = true
            navigateToMap(groupID: groupID)
        } else {
            // 新規登録画面を表示
            showRegistrationButton()
        }
    }
    
    func filterItems(searchText:String) {
        if searchText.isEmpty {
            for item in items {
                let annotation = ItemAnnotation(item: item)
                mapView.addAnnotation(annotation)
            }
            return
        }
        let matchedItems = items.filter { $0.name.contains(searchText) || $0.category.contains(searchText) }
        if let firstItem = matchedItems.first {
            let coordinate = CLLocationCoordinate2D(latitude: firstItem.location.latitude, longitude: firstItem.location.longitude)
            mapView.setCenter(coordinate, animated: true)
        } else {
            print("該当するアイテムがありません")
        }

        // アノテーションを追加
        mapView.removeAnnotations(mapView.annotations) // 既存アノテーションを削除
        for item in matchedItems {
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
    
    @IBAction func toGroupLoginView(_ sender: Any) {
        showRegistrationButton()
    }
    
    func showCreationForm(at coordinate:CLLocationCoordinate2D){
        // 新しいStoryboardをインスタンス化
        let storyboard = UIStoryboard(name: "ShoppingItemRegistrationView", bundle: nil)
        
        // Storyboard IDを使ってViewControllerをインスタンス化
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ShoppingItemRegistrationViewController") as? ShoppingItemRegistrationViewController {
            viewController.coordinate = coordinate
            self.navigationController?.pushViewController(viewController, animated: true)
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
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return } // 長押しの開始時のみ処理

        let touchPoint = gestureRecognizer.location(in: mapView) // マップビュー内のタップ位置を取得
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView) // 緯度経度に変換

        // 一時的なアノテーションを追加
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "新規作成ポイント"
        mapView.addAnnotation(annotation)

        // ダイアログを表示
        let alert = UIAlertController(title: "新規作成", message: "この場所で新規作成しますか？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "作成", style: .default, handler: { _ in
            // 作成フォームを表示する処理
            self.showCreationForm(at: coordinate)
        }))
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: { _ in
            // キャンセル時にアノテーションを削除
            self.mapView.removeAnnotation(annotation)
        }))
        present(alert, animated: true)
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
}
// MARK: デバッグ用のデータ置き場
extension HomeViewController {
    
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
