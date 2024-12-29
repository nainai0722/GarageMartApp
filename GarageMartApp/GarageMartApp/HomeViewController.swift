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
import Firebase
import Combine

enum ContentMode {
    case itemMode
    case eventMode
    case catMode
}

class HomeViewController: UIViewController,UISearchBarDelegate,@preconcurrency CLLocationManagerDelegate, UIActionSheetDelegate {
    @IBOutlet weak var mapView: MKMapView!

    private var viewModel = HomeViewModel()
    private var cancellables: Set<AnyCancellable> = []
    
    var currentLocation:CLLocation?
    let searchBar = UISearchBar()
    private var categories: [ItemCategory] = ItemCategory.allCases
    private var stocks: [StockCategory] = StockCategory.allCases
    private var favorites: [Favorite] = Favorite.allCases
//    private var filterElement: (any Categorable)?
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
    var events:[Event] = []
//    var cats:[Cat] = []
    private var hostingController: UIHostingController<SideMenuView>?
    private var menuIsVisible = false
        
    var contentMode: ContentMode = .itemMode {
        didSet {
            updateAnnotations()
        }
    }

    
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
        
        viewModel.$items
                    .sink { [weak self] items in
                        self?.updateAnnotations()
                    }
                    .store(in: &cancellables)
        
        viewModel.$events
            .sink { [weak self] events in
                self?.updateAnnotations()
            }
            .store(in: &cancellables)
        
        viewModel.$cats
            .sink { [weak self] cats in
                self?.updateAnnotations()
            }
            .store(in: &cancellables)
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
    
    func updateAnnotations(items:[Item]? = nil, events:[Event]? = nil) {
        switch contentMode {
        case .itemMode:
               //アノテーションをアイテムだけにする
            self.removeAnnotations(ofType: EventAnnotation.self)
            self.removeAnnotations(ofType: CatAnnotation.self)
            let itemsToDisplay = items ?? viewModel.items
            replaceAnnotations(to:itemsToDisplay , createAnnotation: {ItemAnnotation(item: $0)})
        case .eventMode:
               //アノテーションをイベントだけにする
            self.removeAnnotations(ofType: ItemAnnotation.self)
            self.removeAnnotations(ofType: CatAnnotation.self)
            let eventToDisplay = events ?? viewModel.events
            replaceAnnotations(to: eventToDisplay, createAnnotation: {EventAnnotation(event: $0)})
        case .catMode:
            self.removeAnnotations(ofType: EventAnnotation.self)
            self.removeAnnotations(ofType: ItemAnnotation.self)
            replaceAnnotations(to: viewModel.cats, createAnnotation: {CatAnnotation(cat: $0)})
        }
    }
    
    private func showSideMenu() {
            // SideMenuViewのSwiftUIビューをUIHostingControllerに変換
        let sideMenuView = SideMenuView(onSelectMode: {[weak self] contentMode in
            self?.hideSideMenu()
            self?.contentMode = contentMode
        })
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
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func categoryButtonTapped(_ sender: UIButton) {
        if sender.tag < categories.count {
            let category = categories[sender.tag]
            print("\(category.rawValue) ボタンがタップされました！")
            
            focusOnFilteredItems(items: category == .all ? viewModel.items : viewModel.items.filter{ $0.category == category }){ error in
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
            let filteredItems = viewModel.items.filter{ $0.stockCategory == stock }
            focusOnFilteredItems(items: filteredItems)

        } else {
            print("Invalid tag, out of bounds")
        }
    }

    @objc func favoriteButtonTapped(_ sender: UIButton) {
        if sender.tag < favorites.count {
            let favorite = favorites[sender.tag]
            print("\(favorite.rawValue) ボタンがタップされました！")
            
            let userId = LoginManager.shared.getUserID()
            BasicUserPersistenceManager().loadBasicUsers{ basicUsers in
                guard let currentUser = basicUsers.filter({ $0.userId == userId }).first else { return }
                let filterList = self.viewModel.items.filter{ item in
                    currentUser.wishList.contains(item.id)
                }
                self.focusOnFilteredItems(items: filterList, attemptCount:0){eror in
                    self.showErrorAlert(title: "エラー", message: "買いたいリストが見つかりませんでした", buttonTitle: "OK")
                }
            }
        }
    }
    
    @IBAction func moveToCurrentLocation(_ sender: Any) {
        moveToUserLocation()
    }
    
    /// 視覚表示領域のアノテーションのみを配列形式で返す
    /// - Parameter list: <#list description#>
    /// - Returns: 指定した型のアノテーション配列
    func annotationsInVisibleRegion<T: Annotatable>(list: [T]) -> [T] {
        return list.filter { element in
            let coordinate = CLLocationCoordinate2D(latitude: element.coordinate.latitude, longitude: element.coordinate.longitude)
            let point = MKMapPoint(coordinate)
            return mapView.visibleMapRect.contains(point)
        }
    }

    func zoomOutMap(centerCoordinate: CLLocationCoordinate2D? = nil, scale: Double = 1.5) {
        let currentRegion = mapView.region
        let newCenter = centerCoordinate ?? currentRegion.center
        let newSpan = MKCoordinateSpan(
            latitudeDelta: min(currentRegion.span.latitudeDelta * scale, scale),
            longitudeDelta: min(currentRegion.span.longitudeDelta * scale, scale)
        )
        let newRegion = MKCoordinateRegion(center: newCenter, span: newSpan)
        mapView.setRegion(newRegion, animated: true)
    }
    
    /// マップ内のイベント・アイテム情報のみ表示する。
    /// また、地図上にアノテーションがなければ、再帰呼び出しでマップを縮小してマップのエリアを広げて再度表示する。
    /// - Parameters:
    ///   - key: Item情報におけるフィルタリングのキー情報
    ///   - attemptCount: 呼び出しの初期値を設定 0にすれば10回再起呼び出歯を行う
    ///   - filterHandler:
    ///   - onError:
    func focusOnFilteredItems(items: [Item],
                         attemptCount: Int = 0,
                         onError: ((String) -> Void)? = nil) {
         let maxAttempts = 10
        let maxScale = 1.5
         guard attemptCount < maxAttempts else {
             print("最大試行回数に到達しました")
             onError?("選択したアイテムは見つかりませんでした")
             return
         }
        guard mapView.region.span.longitudeDelta < maxScale || mapView.region.span.latitudeDelta < maxScale else {
            print("ズームアウトの上限に到達しました")
            onError?("選択したアイテムは見つかりませんでした")
            return
        }

         let visibleItems = annotationsInVisibleRegion(list: items)

         if visibleItems.isEmpty {
             zoomOutMap(scale: maxScale)
             DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                 self.focusOnFilteredItems(items: items, attemptCount: attemptCount + 1, onError: onError)
             }
         } else {
             updateAnnotations(items: visibleItems)
         }
     }
    
//    MARK: 検索処理
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            updateAnnotations()
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
        }
    }
    
    func checkLoginState() {
        self.groupLoginButton.isHidden = true
//        アクセストークンの有無で判定する
        if LoginManager.shared.checkToken(), let _ = LoginManager.shared.getUserID(){
            // マップ画面にとどまる
//            showHomeView()
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
                    self.showUserLoginView()
                }
            })
        }
    }
    
    @IBAction func toGroupLoginView(_ sender: Any) {
        showGroupLoginView()
    }
//    MARK: 登録処理
    // 登録されたアイテムを処理するメソッド
    private func handleItemRegistration(item: Item) {
        viewModel.saveItem(item: item) { result in
            if case .success(let item) = result {
                print("登録されたアイテム: \(item)")
                //戻る
                self.navigationController?.popViewController(animated: true)
                // 登録された場所へ移動するアラート
                self.conformAlert(item:item, mapView: self.mapView)
            }
            if case .failure(let failure) = result {
                print("登録失敗。 \(failure)")
            }
        }
        // 一時的なアノテーションを削除
        self.removeAnnotations(ofType: TemporaryAnnotation.self)
    }
    
//    MARK: 削除処理
    // アイテムを削除する処理するメソッド
    private func handleItemDelete(item: Item) {
        viewModel.deleteItem(item: item)
        navigationController?.popViewController(animated: true)
        // 一時的なアノテーションを削除
        self.removeAnnotations(ofType: TemporaryAnnotation.self)
    }
    
    // 登録されたイベントを処理するメソッド
    private func handleEventRegistration(event: Event) {
        EventPersistenceManager().save(event: event){ result in
            if case .success(let item) = result {
                print("登録されたアイテム: \(item)")
                //戻る
                self.navigationController?.popViewController(animated: true)
                
                // 登録された場所へ移動するアラート
                self.conformAlert(item: event, mapView: self.mapView)
            }
            if case .failure(let failure) = result {
                print("イベント登録失敗。 \(failure)")
            }
        }
        // 一時的なアノテーションを削除
        self.removeAnnotations(ofType: TemporaryAnnotation.self)
    }
    
    // 登録された猫情報を処理するメソッド
    private func handleCatRegistration(cat: Cat) {
        CatPersistenceManager().save(cat: cat){ result in
            if case .success(let cat) = result {
                print("登録された猫情報: \(cat)")
                //戻る
                self.navigationController?.popViewController(animated: true)
                
                // 登録された場所へ移動するアラート
                self.conformAlert(item: cat, mapView: self.mapView)
            }
            if case .failure(let failure) = result {
                print("イベント登録失敗。 \(failure)")
            }
        }
        // 一時的なアノテーションを削除
        self.removeAnnotations(ofType: TemporaryAnnotation.self)
    }

    func replaceAnnotations<T: Annotatable, A: MKPointAnnotation>(to list: [T], createAnnotation: (T) -> A) {
        let visibleRegion = mapView.visibleMapRect
        var newAnnotations:Set<A> = []
        
        for element in list {
            let annotation = createAnnotation(element)
            
            if visibleRegion.contains(MKMapPoint(CLLocationCoordinate2D(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude))){
                newAnnotations.insert(annotation)
            }
        }
        // 現在のアノテーションをセットに変換
        let currentAnnotations = Set(mapView.annotations.compactMap { $0 as? A })
        
        // 追加するアノテーションの差分（新しく追加するべきもの）
        let annotationsToAdd = newAnnotations.subtracting(currentAnnotations)
        
        // 削除するアノテーションの差分（削除すべきもの）
        let annotationsToRemove = currentAnnotations.subtracting(newAnnotations)
        
        // アノテーションの削除
        mapView.removeAnnotations(Array(annotationsToRemove) as [any MKAnnotation])
        
        // アノテーションの追加
        mapView.addAnnotations(Array(annotationsToAdd) as [any MKAnnotation])
    }

    func removeAnnotations<AnnotationType: MKAnnotation>(ofType annotationType: AnnotationType.Type) {
        let annotationsToRemove = mapView.annotations.compactMap { $0 as? AnnotationType }
        mapView.removeAnnotations(annotationsToRemove)
    }
    
//    MARK: 画面遷移
    func showGroupLoginView() {
        // 新しいStoryboardをインスタンス化
        let storyboard = UIStoryboard(name: "GroupLoginView", bundle: nil)
        
        // Storyboard IDを使ってViewControllerをインスタンス化
        if let viewController = storyboard.instantiateViewController(withIdentifier: "GroupLoginViewController") as? GroupLoginViewController {
            // ViewControllerを表示
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    func showHomeView() {
        //SwiftUI画面に遷移する UserLoginView
        let homeView = HomeView()
        let hostingController = UIHostingController(rootView: homeView)
        navigationController?.pushViewController(hostingController, animated: true)
    }
    
    
    func showUserLoginView() {
        //SwiftUI画面に遷移する UserLoginView
        let userLoginView = UserLoginView(onLogin: { [weak self] email in
             print("Login したのは\(email)ユーザー")
            self?.navigationController?.popViewController(animated: true)
        })
        let hostingController = UIHostingController(rootView: userLoginView)
        navigationController?.pushViewController(hostingController, animated: true)
    }
    
    func selectRegistrationType(coordinate:CLLocationCoordinate2D, region:MKCoordinateRegion){
        let itemAction = UIAlertAction(title: "アイテム登録",
                             style: .default) { (action) in
            self.presentRegistrationView(coordinate: coordinate, region:region)
        }
        let eventAction = UIAlertAction(title: "イベント登録",
                             style: .default) { (action) in
            self.presentRegistrationView(coordinate: coordinate,region: region)
        }
        let catAction = UIAlertAction(title: "地域猫登録",
                             style: .default) { (action) in
            self.presentRegistrationView(coordinate: coordinate,region: region)
        }
        let cancelAction = UIAlertAction(title: "キャンセル",
                             style: .cancel) { (action) in
            self.removeAnnotations(ofType: TemporaryAnnotation.self)
        }
        //        アクションシートで選択する
        let alert = UIAlertController(title: "新規作成",
                message: "この位置に情報を登録しますか？",
                preferredStyle: .alert)
        switch contentMode {
        case .itemMode:
            alert.addAction(itemAction)
        case .eventMode:
            alert.addAction(eventAction)
        case .catMode:
            alert.addAction(catAction)
        }
        alert.addAction(cancelAction)
               
        self.present(alert, animated: true)
    }
    
    func presentRegistrationView( coordinate:CLLocationCoordinate2D,region:MKCoordinateRegion) {
        switch contentMode {
        case .itemMode:
            let itemRegistrationView = ItemRegistrationView(coordinate: coordinate, region: region,onRegister: { [weak self] item in
                self?.handleItemRegistration(item: item)
            },onDelete: {[weak self] item in
                self?.handleItemDelete(item: item)
            })
            let hostingController = UIHostingController(rootView: itemRegistrationView)
            navigationController?.pushViewController(hostingController, animated: true)
        case .eventMode:
            let eventRegistrationView = EventRegistrationView(coordinate: coordinate, onRegister: { [weak self] event, image in
                self?.handleEventRegistration(event: event, image: image!)
            })
            let hostingController = UIHostingController(rootView: eventRegistrationView)
            navigationController?.pushViewController(hostingController, animated: true)
        case .catMode:
            let catRegistrationView = CatRegistrationView(coordinate: coordinate, onRegister: { [weak self] cat in
                self?.handleCatRegistration(cat: cat)
            })
            let hostingController = UIHostingController(rootView: catRegistrationView)
            navigationController?.pushViewController(hostingController, animated: true)
        }
    }
    /// 編集のためにアイテム登録画面を開く
    /// - Parameter item: アイテム詳細画面で保持しているitem情報を渡す
    func showItemRegistrationViewForEdit(item:Item){
        let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: item.coordinate.latitude, longitude: item.coordinate.longitude)
        
        let itemRegistrationView = ItemRegistrationView(item: item, coordinate: coordinate, region: self.mapView.region, onRegister: { [weak self] item in
            self?.handleItemRegistration(item: item)
        },onDelete: { [weak self] item in
            self?.handleItemDelete(item: item)
        })
        let hostingController = UIHostingController(rootView: itemRegistrationView)
        navigationController?.pushViewController(hostingController, animated: true)
    }
    /// アイテム詳細画面を表示する
    /// - Parameter item: アノテーションに含まれるitem情報を渡す
    private func showItemDetail(for item: Item) {
        // SwiftUIのビューを作成
        let itemDetailView = ItemDetailView(isPresented: .constant(true), item: item, isEditEnabled: false, onEdit: { [weak self] item in
            self?.showItemRegistrationViewForEdit(item: item)
            
        })
        
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
    
    /// イベント詳細画面を表示する
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
        updateAnnotations()
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
        selectRegistrationType(coordinate:coordinate, region: mapView.region)
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
