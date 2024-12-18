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
    var currentLocation:CLLocation?
    let searchBar = UISearchBar()
    private var categories: [ItemCategory] = ItemCategory.allCases
    private var stocks: [StockCategory] = StockCategory.allCases
    private var favorites: [Favorite] = Favorite.allCases
    private var filterElement: (any Categorable)?
    private var favoriteList:[Item] = []
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
    private var hostingController: UIHostingController<SideMenuView>?
    private var menuIsVisible = false
        
    
    @IBOutlet weak var groupLoginButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ビューが表示される直前に呼ばれる
        self.removeAnnotations(ofType: TemporaryAnnotation.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        searchBar.placeholder = "住所検索"
        navigationItem.titleView = searchBar
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showMenu))
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
        
        ItemPersistenceManager().loadItems { items in
            self.items = items
            self.focusOn(filterBy: ItemCategory.all) { item, category in
                return true // 全カテゴリを含む場合
            }
        }
        // スワイプジェスチャーの設定
                let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
                swipeGesture.direction = .right
                self.view.addGestureRecognizer(swipeGesture)
    }
    
    // メニュー表示用のメソッド
    @objc func showMenu() {
        if !menuIsVisible {
            // メニューを表示
            showSideMenu()
        } else {
            // メニューを非表示
            hideSideMenu()
        }
    }
    
    private func showSideMenu() {
            // SideMenuViewのSwiftUIビューをUIHostingControllerに変換
            let sideMenuView = SideMenuView()
            hostingController = UIHostingController(rootView: sideMenuView)
            
            // ホスティングコントローラーのビューを表示
            guard let hostingController = hostingController else { return }
            
            // ホスティングコントローラーのビューを現在のビューに追加
            addChild(hostingController)
            view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)
            
            // 初期位置を設定（左端に隠す）
            hostingController.view.frame = CGRect(x: -250, y: 0, width: 250, height: self.view.frame.height)
            
            // アニメーションでスライドイン
            UIView.animate(withDuration: 0.3, animations: {
                hostingController.view.frame.origin.x = 0
            }) { _ in
                self.menuIsVisible = true
            }
        }
        
        // メニューを非表示にする処理
    private func hideSideMenu() {
        guard let hostingController = hostingController else { return }
        
        // アニメーションでスライドアウト
        UIView.animate(withDuration: 0.3, animations: {
            hostingController.view.frame.origin.x = -250
        }) { _ in
            hostingController.view.removeFromSuperview()
            hostingController.removeFromParent()
            self.menuIsVisible = false
        }
    }
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        if !menuIsVisible {
            // メニューを表示
            showSideMenu()
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func categoryButtonTapped(_ sender: UIButton) {
        if sender.tag < categories.count {
            let category = categories[sender.tag]
            print("\(category.rawValue) ボタンがタップされました！")
            
            focusOn(filterBy: category, attemptCount: 0) { item, category in
                if category == .all {
                    return true // 全カテゴリを含む場合
                } else {
                    return item.category == category
                }
            } onError: { error in
                self.showErrorAlert(message: error)
            }


        } else {
            print("Invalid tag, out of bounds")
        }
    }
    
    @objc func stockButtonTapped(_ sender: UIButton) {
        if sender.tag < stocks.count {
            let stock = stocks[sender.tag]
            print("\(stock.rawValue) ボタンがタップされました！")
            focusOn(filterBy:stock) { item, stockCategory in
                return item.stockCategory == stockCategory
            }

        } else {
            print("Invalid tag, out of bounds")
        }
    }
//                favoriteButtonTapped
    @objc func favoriteButtonTapped(_ sender: UIButton) {
        if sender.tag < favorites.count {
            let favorite = favorites[sender.tag]
            print("\(favorite.rawValue) ボタンがタップされました！")
            var filterList:[Item] = []
            let userId = LoginManager.shared.getUserID()
            BasicUserPersistenceManager().loadBasicUsers{ basicUsers in
                for basicUser in basicUsers {
                    if userId == basicUser.userId {
                        for list in basicUser.wishList{
                            filterList = self.items.filter{$0.id == list }
                            self.focusOnFavorite(favoriteList: filterList, attemptCount:0){eror in
                                self.showErrorAlert(title: "エラー", message: "買いたいリストが見つかりませんデイsた", buttonTitle: "OK")
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    @IBAction func moveToCurrentLocation(_ sender: Any) {
        moveToUserLocation()
    }
    
    func filterAnnotations<T: Annotatable>(list: [T]) -> [T] {
        return list.filter { element in
            let coordinate = CLLocationCoordinate2D(latitude: element.coordinate.latitude, longitude: element.coordinate.longitude)
            let point = MKMapPoint(coordinate)
            return mapView.visibleMapRect.contains(point)
        }
    }

    
   func focusOnFavorite(favoriteList: [Item], attemptCount: Int = 0, onError: ((String) -> Void)? = nil) {
        let maxAttempts = 10
        guard attemptCount < maxAttempts else {
            print("最大試行回数に到達しました")
            onError?("買いたいリストに入れたアイテムは見つかりませんでした")
            return
        }

        let filteredItems = filterAnnotations(list: favoriteList)
        let filteredEvents = filterAnnotations(list: events)

        if filteredItems.isEmpty {
            zoomOutMap(scale: 1.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.focusOnFavorite(favoriteList: favoriteList, attemptCount: attemptCount + 1, onError: onError)
            }
        } else {
            replaceAnnotations(to: filteredItems) { ItemAnnotation(item: $0) }
            replaceAnnotations(to: filteredEvents) { EventAnnotation(event: $0) }
        }
    }

    func zoomOutMap(centerCoordinate: CLLocationCoordinate2D? = nil, scale: Double = 1.5) {
        let currentRegion = mapView.region
        let newCenter = centerCoordinate ?? currentRegion.center
        let newSpan = MKCoordinateSpan(
            latitudeDelta: currentRegion.span.latitudeDelta * scale,
            longitudeDelta: currentRegion.span.longitudeDelta * scale
        )
        let newRegion = MKCoordinateRegion(center: newCenter, span: newSpan)
        mapView.setRegion(newRegion, animated: true)
    }

    
    
    func focusOn<T: Equatable>(
        filterBy key: T,
        attemptCount: Int = 10,
        filterHandler: @escaping (Item, T) -> Bool,
        onError: ((String) -> Void)? = nil
    ){
        // 現在表示中の地図領域を取得
        let visibleMapRect = mapView.visibleMapRect

        // アイテムをフィルタリング
        let filteredItems = items.filter { item in
            let coordinate = CLLocationCoordinate2D(latitude: item.coordinate.latitude, longitude: item.coordinate.longitude)
            let point = MKMapPoint(coordinate)
            return visibleMapRect.contains(point) && filterHandler(item, key)
        }

        // イベントをフィルタリング
        let filteredEvents = events.filter { event in
            let coordinate = CLLocationCoordinate2D(latitude: event.coordinate.latitude, longitude: event.coordinate.longitude)
            let point = MKMapPoint(coordinate)
            return visibleMapRect.contains(point)
        }

        if filteredItems.isEmpty {
            zoomOutMap(scale: 1.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.focusOn(filterBy: key, attemptCount: attemptCount + 1, filterHandler: filterHandler, onError: onError)
            }
        } else {
            replaceAnnotations(to: filteredItems) { ItemAnnotation(item: $0) }
            replaceAnnotations(to: filteredEvents) { EventAnnotation(event: $0) }
        }
        // マップ上のアノテーションを更新
        replaceAnnotations(to: filteredItems) { item in
            return ItemAnnotation(item: item)
        }
        replaceAnnotations(to: filteredEvents) { event in
            return EventAnnotation(event: event)
        }
    }
//    MARK: 検索処理
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            replaceAnnotations(to: items){ item in
                return ItemAnnotation(item: item)
            }
            replaceAnnotations(to: events){ event in
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
        self.groupLoginButton.isHidden = true
//        アクセストークンの有無で判定する
        if LoginManager.shared.checkToken(), let _ = LoginManager.shared.getUserID(){
            // マップ画面にとどまる
            
        } else {
            //　トークンがなければ、再取得を実行する
            //  TODO: 処理の流れを記述しただけでトークンの成否などの詳細は未判定
            LoginManager.shared.retryAccessToken(completion: { result in
                switch result {
                case .success():
                    return
                case .failure(let error):
                    print("error: \(error)")
                    // ログイン画面を表示
                    self.showUserLoginButton()
                }
            })
        }
    }
    
    /// グループIDを指定してマップ上にアノテーションを載せて表示する
    /// - Parameter groupID: 指定するグループID
    func navigateToMap(groupID: String){
        ItemPersistenceManager().loadItems { items in
            let filteredByGroupID = ItemSearchManager(items: items).items(where: { $0.groupId == groupID })
            self.replaceAnnotations(to: filteredByGroupID){ item in
                return ItemAnnotation(item: item)
            }
        }
    }
    
    @IBAction func toGroupLoginView(_ sender: Any) {
        showRegistrationButton()
    }
//    MARK: 登録処理
    // 登録されたアイテムを処理するメソッド
    private func handleItemRegistration(item: Item) {
        ItemPersistenceManager().save(item: item){ result in
            if case .success(let item) = result {
                print("登録されたアイテム: \(item)")
                //戻る
                self.navigationController?.popViewController(animated: true)
                
                // 一時的なアノテーションを削除
                self.removeAnnotations(ofType: TemporaryAnnotation.self)
                
                ItemPersistenceManager().loadItems(completion: { items in
                    self.items = items
                    self.focusOn(filterBy: ItemCategory.all) { item, category in
                        return true // 全カテゴリを含む場合
                    }
                })
            }
            if case .failure(let failure) = result {
                print("登録失敗。 \(failure)")
                // 一時的なアノテーションを削除
                self.removeAnnotations(ofType: TemporaryAnnotation.self)
            }
        }
    }
    // 登録されたイベントを処理するメソッド
    private func handleEventRegistration(event: Event, image: UIImage) {
        EventPersistenceManager().save(event: event){ result in
            if case .success(let item) = result {
                print("登録されたアイテム: \(item)")
                //戻る
                self.navigationController?.popViewController(animated: true)
                
                // 一時的なアノテーションを削除
                self.removeAnnotations(ofType: TemporaryAnnotation.self)
                
                EventPersistenceManager().loadEvents(completion: { events in
                    self.events = events
                    self.focusOn(filterBy: ItemCategory.all) { item, category in
                        return true // 全カテゴリを含む場合
                    }
                })
            }
            if case .failure(let failure) = result {
                print("イベント登録失敗。 \(failure)")
                // 一時的なアノテーションを削除
                self.removeAnnotations(ofType: TemporaryAnnotation.self)
            }
        }
    }

    func replaceAnnotations<T: Annotatable, A: MKAnnotation>(to items: [T], createAnnotation: (T) -> A) {
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
    
//    MARK: 画面遷移
    func showRegistrationButton() {
        // 新しいStoryboardをインスタンス化
        let storyboard = UIStoryboard(name: "GroupLoginView", bundle: nil)
        
        // Storyboard IDを使ってViewControllerをインスタンス化
        if let viewController = storyboard.instantiateViewController(withIdentifier: "GroupLoginViewController") as? GroupLoginViewController {
            // ViewControllerを表示
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func showUserLoginButton() {
        //SwiftUI画面に遷移する UserLoginView
        let userLoginView = UserLoginView(onLogin: { [weak self] email in
             print("Login したのは\(email)ユーザー")
            self?.navigationController?.popViewController(animated: true)
        })
        let hostingController = UIHostingController(rootView: userLoginView)
        navigationController?.pushViewController(hostingController, animated: true)
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
            let itemRegistrationView = ItemRegistrationView(coordinate: coordinate, onRegister: { [weak self] item in
                self?.handleItemRegistration(item: item)
            })
            let hostingController = UIHostingController(rootView: itemRegistrationView)
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
    
    // 位置情報が更新されたときに呼び出される
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        currentLocation = userLocation
    }
    
    // 位置情報取得に失敗した場合
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // エラー内容をログ出力
        print("位置情報取得失敗: \(error.localizedDescription)")
        
        // エラー内容を元にアラートを表示
        let alertMessage: String
        if (error as NSError).code == CLError.denied.rawValue {
            alertMessage = "位置情報の使用が拒否されています。設定を確認してください。"
        } else {
            alertMessage = "位置情報の取得に失敗しました。"
        }
        
        let alert = UIAlertController(title: "エラー", message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
        
        // 必要に応じて、地図を初期位置に戻す
        guard let currentLocation = currentLocation else { return  }
        let defaultCoordinate = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude) // 東京をデフォルト位置とする例
        mapView.setCenter(defaultCoordinate, animated: true)
    }
    
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
            showItemDetail(for: itemAnnotation.item)
        }
        // EventAnnotation の場合
        else if let eventAnnotation = view.annotation as? EventAnnotation {
            showEventDetail(for: eventAnnotation.event)
        }
    }
    
    
    /// アイテム登録画面を表示する
    /// - Parameter item: Item型に位置情報をセットして引数として渡す
    private func showItemDetail(for item: Item) {
        // SwiftUIのビューを作成
        let itemDetailView = ItemDetailView(isPresented: .constant(true), item: item, isEditEnabled: false)
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
    
    /// イベント登録画面を表示する
    /// - Parameter event: Event型に位置情報をセットして引数として渡す
    private func showEventDetail(for event: Event) {
        // SwiftUIのビューを作成
        let eventDetailView = EventDetailView(isPresented: .constant(true), event: event)
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
            if !itemAnnotation.item.imageUrl.isEmpty{
                ItemPersistenceManager().fetchImage(from: itemAnnotation.item){ result in
                    DispatchQueue.main.async { // UI更新はメインスレッドで行う
                        switch result {
                        case .success(let image):
                            imageView.image = image
                        case .failure(let error):
                            print("Error fetching image: \(error.localizedDescription)")
                            imageView.image = UIImage(named: "placeholder")
                        }
                    }
                }
            }else{
                imageView.image = UIImage(named: "placeholder")
            }
            annotationView?.markerTintColor = .red
        }
        if let eventAnnotation = annotation as? EventAnnotation {
            imageView.image = eventAnnotation.event.imageData.flatMap { UIImage(data: $0) } ?? UIImage(named: "placeholder")
            annotationView?.markerTintColor = .yellow
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
// MARK: UI関連
extension HomeViewController {
    private func setupKeyboardDismissTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        // View全体で検出するためにキャンセルイベントを無視する
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
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
        enumeratedCategorableButton(customCategories: categories,setSelector: #selector(categoryButtonTapped(_:)))
        // ストックボタンをStackViewに追加
        enumeratedCategorableButton(customCategories: stocks,setSelector: #selector(stockButtonTapped(_:)))
        
        enumeratedCategorableButton(customCategories: favorites,setSelector: #selector(favoriteButtonTapped(_:)))
    }
    
    /// アイテムの選択肢項目をボタンにして横スクロール表示する
    /// - Parameters:
    ///   - customCategories: アイテムの選択肢項目をリストで渡す
    ///   - setSelector: ボタンタップ時の処理を指定して渡す
    private func enumeratedCategorableButton<T:Categorable>(customCategories: [T], setSelector:Selector){
        for (index, customCategory) in customCategories.enumerated() {
            let button = UIButton()
            button.setTitle(customCategory.rawValue, for: .normal)
            button.backgroundColor = .systemBlue
            button.layer.cornerRadius = 10
            button.tag = index
            button.setTitleColor(.white, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
            button.addTarget(self, action: setSelector, for: .touchUpInside)
            
            stackView.addArrangedSubview(button)
        }
    }
}
// MARK: デバッグ用のデータ置き場
extension HomeViewController {
    
    static var group = Group(name: "myGroup", password: "123456", createdBy: "2024-12-07 21:46:30", members: [])
    
    func checkDebugUserGroup() {
        if UserDefaults.standard.string(forKey: "groupID") == nil {
            let groupID = HomeViewController.group.id.uuidString
            UserDefaults.standard.set(groupID, forKey: "groupID")
        }
    }
}
