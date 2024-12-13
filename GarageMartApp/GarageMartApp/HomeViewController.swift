//
//  HomeViewController.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/07.
//

import UIKit
import MapKit
import CoreLocation
import SwiftUI

class HomeViewController: UIViewController,UISearchBarDelegate,CLLocationManagerDelegate, UIActionSheetDelegate {
    @IBOutlet weak var mapView: MKMapView!
    let searchBar = UISearchBar()
    private var categories: [ItemCategory] = ItemCategory.allCases
    private var stocks: [StockCategory] = StockCategory.allCases
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        return stackView
    }()
    let locationManager = CLLocationManager()
    var items:[Item] = []
    var events:[Event] = []
    private var isItemDetailPresented = false
    
    @IBOutlet weak var groupLoginButton: UIButton!
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        UserDefaults.standard.removeObject(forKey:  "items")
//        UserDefaults.standard.removeObject(forKey:  "events")
        
        items = ItemPersistenceManager().load()
        events = EventPersistenceManager().load()
        addAnnotationsToMap(to: items){ item in
            return ItemAnnotation(item: item)
        }
        addAnnotationsToMap(to: events){ event in
            return EventAnnotation(event: event)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        searchBar.placeholder = "住所検索"
        navigationItem.titleView = searchBar
        setupCategoryButtons()
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressRecognizer.minimumPressDuration = 0.5 // 長押し判定の時間（秒）
        mapView.addGestureRecognizer(longPressRecognizer)
        
        mapView?.delegate = self
        // デバッグ用のグループ情報を設定する
        checkDebugUserGroup()
        checkLoginState()

        // 位置情報マネージャの設定
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // ユーザーに位置情報の使用許可をリクエスト
        locationManager.requestWhenInUseAuthorization()
        
        // 位置情報の取得開始
        locationManager.startUpdatingLocation()
        
        // ユーザーの現在位置を表示する設定
        mapView.showsUserLocation = true
        
        setupKeyboardDismissTapGesture()
    }
    
    private func setupCategoryButtons() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            // ScrollViewの制約
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5), // view.safeAreaLayoutGuideで上部に余白を設定
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 60), // 高さ
            
            // StackViewの制約
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        // カテゴリボタンをStackViewに追加
        for (index, category) in categories.enumerated() {
            let button = UIButton()
            button.setTitle(category.rawValue, for: .normal)
            button.backgroundColor = .systemBlue
            button.layer.cornerRadius = 10
            button.tag = index
            button.setTitleColor(.white, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
            button.addTarget(self, action: #selector(categoryButtonTapped(_:)), for: .touchUpInside)
            
            stackView.addArrangedSubview(button)
        }
        // ストックボタンをStackViewに追加
        for (index, stock) in stocks.enumerated() {
            let button = UIButton()
            button.setTitle(stock.rawValue, for: .normal)
            button.backgroundColor = .systemBlue
            button.layer.cornerRadius = 10
            button.tag = index
            button.setTitleColor(.white, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
            button.addTarget(self, action: #selector(categoryButtonTapped(_:)), for: .touchUpInside)
            
            stackView.addArrangedSubview(button)
        }
    }
    
    private func setupKeyboardDismissTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        // View全体で検出するためにキャンセルイベントを無視する
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func categoryButtonTapped(_ sender: UIButton) {
        if sender.tag < categories.count {
            let category = categories[sender.tag]
            print("Selected category: \(category.rawValue)")
            print("\(category.rawValue) ボタンがタップされました！")
            focusOnCategory(category: category)
        } else {
            print("Invalid tag, out of bounds")
        }
    }
    
    @objc func stockButtonTapped(_ sender: UIButton) {
        if sender.tag < stocks.count {
            let stock = stocks[sender.tag]
            print("Selected stock: \(stock.rawValue)")
            print("\(stock.rawValue) ボタンがタップされました！")
            focusOnStock(stock: stock)
        } else {
            print("Invalid tag, out of bounds")
        }
    }
    
    
    @IBAction func moveToCurrentLocation(_ sender: Any) {
        moveToUserLocation()
    }
    func moveToUserLocation() {
        guard let userLocation = mapView.userLocation.location else {
            print("現在地が取得できません")
            return
        }
        
        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(region, animated: true)
    }

    
    func focusOnCategory(category: ItemCategory) {
        // 現在表示中の地図領域を取得
        let visibleMapRect = mapView.visibleMapRect
        
        // アイテムとイベントをフィルタリングしてアノテーションを追加
        let filteredItems = items.filter { item in
            let coordinate = CLLocationCoordinate2D(latitude: item.coordinate.latitude, longitude: item.coordinate.longitude)
            let point = MKMapPoint(coordinate)
            if category == .all {
                return visibleMapRect.contains(point)
            }else{
                return visibleMapRect.contains(point) && item.category == category
            }
        }
//        print("Item Category: \(item.category.rawValue), Filter Category: \(category)")
        
        let filteredEvents = events.filter { event in
            let coordinate = CLLocationCoordinate2D(latitude: event.coordinate.latitude, longitude: event.coordinate.longitude)
            let point = MKMapPoint(coordinate)
            return visibleMapRect.contains(point)
        }
        // マップ上のアノテーションを更新
        mapView.removeAnnotations(mapView.annotations)
        addAnnotationsToMap(to: filteredItems) { item in
            return ItemAnnotation(item: item)
        }
        addAnnotationsToMap(to: filteredEvents) { event in
            return EventAnnotation(event: event)
        }
    }
    
    func focusOnStock(stock: StockCategory) {
        // 現在表示中の地図領域を取得
        let visibleMapRect = mapView.visibleMapRect
        
        // アイテムとイベントをフィルタリングしてアノテーションを追加
        let filteredItems = items.filter { item in
            let coordinate = CLLocationCoordinate2D(latitude: item.coordinate.latitude, longitude: item.coordinate.longitude)
            let point = MKMapPoint(coordinate)
            return visibleMapRect.contains(point) && item.stockCategory == stock
        }
//        print("Item Category: \(item.category.rawValue), Filter Category: \(category)")
        
        let filteredEvents = events.filter { event in
            let coordinate = CLLocationCoordinate2D(latitude: event.coordinate.latitude, longitude: event.coordinate.longitude)
            let point = MKMapPoint(coordinate)
            return visibleMapRect.contains(point)
        }
        // マップ上のアノテーションを更新
        mapView.removeAnnotations(mapView.annotations)
        addAnnotationsToMap(to: filteredItems) { item in
            return ItemAnnotation(item: item)
        }
        addAnnotationsToMap(to: filteredEvents) { event in
            return EventAnnotation(event: event)
        }
    }
    
    
    @objc func allCategoriesButtonTapped() {
        // 現在表示中の地図領域を取得
            let visibleMapRect = mapView.visibleMapRect
            
            // アイテムとイベントをフィルタリングしてアノテーションを追加
            let filteredItems = items.filter { item in
                let coordinate = CLLocationCoordinate2D(latitude: item.coordinate.latitude, longitude: item.coordinate.longitude)
                let point = MKMapPoint(coordinate)
                return visibleMapRect.contains(point)
            }
            
            let filteredEvents = events.filter { event in
                let coordinate = CLLocationCoordinate2D(latitude: event.coordinate.latitude, longitude: event.coordinate.longitude)
                let point = MKMapPoint(coordinate)
                return visibleMapRect.contains(point)
            }
            
            // マップ上のアノテーションを更新
            mapView.removeAnnotations(mapView.annotations)
            addAnnotationsToMap(to: filteredItems) { item in
                return ItemAnnotation(item: item)
            }
            addAnnotationsToMap(to: filteredEvents) { event in
                return EventAnnotation(event: event)
            }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            addAnnotationsToMap(to: items){ item in
                return ItemAnnotation(item: item)
            }
            addAnnotationsToMap(to: events){ event in
                return EventAnnotation(event: event)
            }
            return
        } else {
            searchLocation(searchText)
        }
    }
    
    func searchLocation(_ query: String) {
        // まずジオコーディングを試みる
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(query) { [weak self] (placemarks, error) in
            if let error = error {
                print("住所検索エラー: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first, let location = placemark.location else {
                return
            }
            // 地図の表示領域を変更
            let coordinate = location.coordinate
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            self?.mapView.setRegion(region, animated: true)
            
            // 全てのアノテーションを取得
            var allAnnotations: [MKPointAnnotation] = []

            // ItemAnnotationsとEventAnnotationsをまとめて処理
            allAnnotations.append(contentsOf: (self?.items.map { ItemAnnotation(item: $0) })!)
            allAnnotations.append(contentsOf: (self?.events.map { EventAnnotation(event: $0) })!)
            
            // 検索結果に基づくアノテーションの追加
            let nearbyAnnotations = allAnnotations.filter { annotation in
                let distance = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
                    .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
                return distance <= 10000 // 10km以内
            }
            self?.mapView.addAnnotations(nearbyAnnotations)
        }
    }
    
    func checkLoginState() {
        let groupID = UserDefaults.standard.string(forKey: "groupID")
//        let userID = UserDefaults.standard.string(forKey: "userID")
        
        if let groupID = groupID {
            // マップ画面に進む
            groupLoginButton.isHidden = true
            navigateToMap(groupID: groupID)
        } else {
            // 新規登録画面を表示
            showRegistrationButton()
        }
    }
    
    // 位置情報が更新されたときに呼び出される
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        
//        currentLocation = userLocation.coordinate
//        
//        // 現在位置を地図に表示
//        let region = MKCoordinateRegion(center: userLocation.coordinate,
//                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
//        mapView.setRegion(region, animated: true)
    }
    
    // 位置情報取得に失敗した場合
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error while updating location: \(error.localizedDescription)")
    }
    
    /// グループIDを指定してマップ上にアノテーションを載せて表示する
    /// - Parameter groupID: 指定するグループID
    func navigateToMap(groupID: String){
        let items = ItemPersistenceManager().load()
        let filteredByGroupID = ItemSearchManager(items: items).items(where: { $0.groupId == groupID })
        addAnnotationsToMap(to: filteredByGroupID){ item in
            return ItemAnnotation(item: item)
        }
    }
    
    @IBAction func toGroupLoginView(_ sender: Any) {
        showRegistrationButton()
    }
    
    func showCreationForm(at coordinate:CLLocationCoordinate2D){
        let shoppingItemView = ItemRegistrationView(coordinate: coordinate, onRegister: { [weak self] item, image in
            self?.handleItemRegistration(item: item, image: image)
        })
        let hostingController = UIHostingController(rootView: shoppingItemView)
        self.navigationController?.pushViewController(hostingController, animated: true)
    }
    
    // 登録されたアイテムを処理するメソッド
    private func handleItemRegistration(item: Item, image: UIImage) {
        let itemPersistenceManager = ItemPersistenceManager()
        var items = itemPersistenceManager.load()
        items.append(item)
        itemPersistenceManager.save(items: items)
        //戻る
        self.navigationController?.popViewController(animated: true)
        
        // 一時的なアノテーションを削除
        removeAnnotations(ofType: TemporaryAnnotation.self)
        print("登録されたアイテム: \(item)")
    }
    // 登録されたイベントを処理するメソッド
    private func handleEventRegistration(event: Event, image: UIImage) {
        let eventPersistenceManager = EventPersistenceManager()
        var events = eventPersistenceManager.load()
        events.append(event)
        eventPersistenceManager.save(events: events)
        //戻る
        self.navigationController?.popViewController(animated: true)
        
        // 一時的なアノテーションを削除
        removeAnnotations(ofType: TemporaryAnnotation.self)
        print("登録されたイベント: \(event)")
    }

    func addAnnotationsToMap<T: Annotatable, A: MKAnnotation>(to items: [T], createAnnotation: (T) -> A) {
        removeAnnotations(ofType: A.self)
        for item in items {
            let annotation = createAnnotation(item)
            mapView.addAnnotation(annotation)
        }
    }

    func removeAnnotations<AnnotationType: MKAnnotation>(ofType annotationType: AnnotationType.Type) {
        let annotationsToRemove = mapView.annotations.compactMap { $0 as? AnnotationType }
        mapView.removeAnnotations(annotationsToRemove)
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
    
    func selectRegistrationType(coordinate:CLLocationCoordinate2D){
        let itemAction = UIAlertAction(title: "アイテム登録",
                             style: .default) { (action) in
            self.showRegistrationViewFromAnnotation(isItem: true, coordinate: coordinate)
        }
        let eventAction = UIAlertAction(title: "イベント登録",
                             style: .default) { (action) in
            self.showRegistrationViewFromAnnotation(isItem: false, coordinate: coordinate)
        }
        let cancelAction = UIAlertAction(title: "キャンセル",
                             style: .cancel) { (action) in
            self.removeAnnotations(ofType: TemporaryAnnotation.self)
        }
        //        アクションシートで選択する
        let alert = UIAlertController(title: "新規作成",
                message: "この位置に情報を登録しますか？",
                preferredStyle: .alert)
        alert.addAction(itemAction)
        alert.addAction(eventAction)
        alert.addAction(cancelAction)
               
        self.present(alert, animated: true)
    }
    
    func showRegistrationViewFromAnnotation(isItem:Bool, coordinate:CLLocationCoordinate2D) {
        if isItem {
            let shoppingItemView = ItemRegistrationView(coordinate: coordinate, onRegister: { [weak self] item, image in
                self?.handleItemRegistration(item: item, image: image)
            })
            let hostingController = UIHostingController(rootView: shoppingItemView)
            navigationController?.pushViewController(hostingController, animated: true)
        } else {
            let shoppingItemView = EventRegistrationView(coordinate: coordinate, onRegister: { [weak self] event, image in
                self?.handleEventRegistration(event: event, image: image!)
            })
            let hostingController = UIHostingController(rootView: shoppingItemView)
            navigationController?.pushViewController(hostingController, animated: true)
        }
    }
}
// MARK: マップ挙動・アノテーション関連の処理
extension HomeViewController :MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // 新しい範囲に基づいてアノテーションを再表示
        let visibleRegion = mapView.visibleMapRect
        // 全てのアノテーションを取得
        var allAnnotations: [MKPointAnnotation] = []

        // ItemAnnotationsとEventAnnotationsをまとめて処理
        allAnnotations.append(contentsOf: items.map { ItemAnnotation(item: $0) })
        allAnnotations.append(contentsOf: events.map { EventAnnotation(event: $0) })
        
        let visibleAnnotations = allAnnotations.filter { annotation in
            return visibleRegion.contains(MKMapPoint(annotation.coordinate))
        }
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(visibleAnnotations)
    }

    
    /// マップスクロール時に現在地の自動追尾を停止する
    /// - Parameters:
    ///   - mapView: 表示しているmapView
    ///   - animated: animated description
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapView.setUserTrackingMode(.none, animated: false)
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }
        let location = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        // 一時的なアノテーションを追加
        let annotation = TemporaryAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "新規作成ポイント"
        mapView.addAnnotation(annotation)

        // ダイアログを表示
        selectRegistrationType(coordinate:coordinate)
    }

    // 吹き出しのアクセサリ（詳細ボタンなど）をタップしたとき
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // ItemAnnotation の場合
        if let itemAnnotation = view.annotation as? ItemAnnotation {
            showItemDetail(for: itemAnnotation)
        }
        // EventAnnotation の場合
        else if let eventAnnotation = view.annotation as? EventAnnotation {
            showEventDetail(for: eventAnnotation)
        }
    }

    private func showItemDetail(for annotation: ItemAnnotation) {
        // SwiftUIのビューを作成
        let itemDetailView = ItemDetailView(isPresented: .constant(true), item: annotation.item)
        let hostingController = UIHostingController(rootView: itemDetailView)
        
        // モーダルのスタイル設定
        hostingController.modalPresentationStyle = .pageSheet
        hostingController.modalTransitionStyle = .coverVertical
        
        // sheetPresentationControllerでハーフモーダル設定
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(hostingController, animated: true, completion: nil)
    }
    
    private func showEventDetail(for annotation: EventAnnotation) {
        // SwiftUIのビューを作成
        let eventDetailView = EventDetailView(isPresented: .constant(true), event: annotation.event)
        let hostingController = UIHostingController(rootView: eventDetailView)
        
        // モーダルのスタイル設定
        hostingController.modalPresentationStyle = .pageSheet
        hostingController.modalTransitionStyle = .coverVertical
        
        // sheetPresentationControllerでハーフモーダル設定
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(hostingController, animated: true, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard (annotation is ItemAnnotation || annotation is EventAnnotation) else { return nil }

        let reuseIdentifier = "CustomAnnotationView"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            annotationView?.canShowCallout = true // 吹き出しを有効化
        } else {
            annotationView?.annotation = annotation
        }

        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50)) // サイズ調整
        // 吹き出し左側に画像を表示
        if let itemAnnotation = annotation as? ItemAnnotation {
            imageView.image = itemAnnotation.item.imageData.flatMap { UIImage(data: $0) } ?? UIImage(named: "placeholder")

        }
        if let eventAnnotation = annotation as? EventAnnotation {
            imageView.image = eventAnnotation.event.imageData.flatMap { UIImage(data: $0) } ?? UIImage(named: "placeholder")
        }
        imageView.layer.cornerRadius = 10 // 角丸
        imageView.layer.masksToBounds = true
        annotationView?.leftCalloutAccessoryView = imageView
        
        let button = UIButton(type: .detailDisclosure)  // or any button type you prefer
        button.setTitle("詳細表示", for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        button.layer.cornerRadius = 10 // 角丸
        button.layer.masksToBounds = true
        annotationView?.rightCalloutAccessoryView = button

        return annotationView
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
}
