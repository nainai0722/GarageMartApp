//
//  ItemRegistrationView.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/10.
//

import SwiftUI
import MapKit
import CoreLocation
import CoreLocation
import ImageIO
import MobileCoreServices
import PhotosUI
import Photos

struct ItemRegistrationView: View {
    @State var item:Item?
    @State var coordinate: CLLocationCoordinate2D
    @State private var selectedImage: UIImage? = nil
    @State var gpsCoordinates: CLLocationCoordinate2D?
    @State private var showPermissionAlert = false
    @State private var showErrorAlert = false
    @State private var showImagePicker = false // 画像ピッカーを表示するためのフラグ
    @State private var isUseCurrentLocation = false
    @State private var isSelectImageCoordinate = false //画像の位置情報を使うか選択するボタン
    @State private var imageCoordinate: CLLocationCoordinate2D? // 画像の位置情報
    @State private var isSelectCurrentCoordinate = false
    @State var region: MKCoordinateRegion
    private let locationManager = CLLocationManager()
    
    @State private var itemName: String = ""
    @State private var itemDescription: String = ""
    @State private var itemPrice: String = ""
    @State private var itemQuantity: String = ""
    @State private var selectedStock: StockCategory = .only
    @State private var selectedCategory: ItemCategory = .food
    @State private var registerButtonText:String = ""
    @State private var annotations: [AnnotatedLocation] = [
        AnnotatedLocation(coordinate: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917))
    ]
    @State private var isDeleted: Bool = false
    let onRegister: (Item) -> Void
    let onDelete: (Item) -> Void
    
    var body: some View {
        ScrollView {
            ZStack{
                VStack(alignment: .leading, spacing: 16) {
                    // 画像の表示部分
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                    } else {
                        Text("画像が選択されていません")
                    }
                    
                    // フォトライブラリから画像を選択するボタン
                    Button(action: {
                        checkPhotoLibraryPermission()
                    }) {
                        Text("画像を選択")
                    }
                    .alert(isPresented: $showPermissionAlert) {
                        Alert(
                            title: Text("写真ライブラリへのアクセスが許可されていません"),
                            message: Text("設定アプリでアクセスを許可してください。"),
                            primaryButton: .default(Text("設定を開く"), action: openAppSettings),
                            secondaryButton: .cancel()
                        )
                                }
                    .sheet(isPresented: $showImagePicker) {
                        // 画像ピッカーの表示
                        PHPicker(selectedImage: $selectedImage, gpsCoordinates: $gpsCoordinates)
                    }
                    Text("マップから位置情報を選択する")
                        .font(.headline)
                    Map(coordinateRegion: .constant(region), annotationItems: annotations) { item in
                        MapAnnotation(coordinate: item.coordinate) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title)
                                Text("登録する位置")
                                    .font(.caption)
                            }
                        }
                    }
                        .frame(height: 300)
                        .gesture(DragGesture().onEnded { _ in
                            // ピンの位置をマップで変更可能に
                            updatePinFromMap()
                        })
                    
                    Toggle("現在地にピンを移動", isOn: $isUseCurrentLocation)
                        .toggleStyle(SwitchToggleStyle())
                        .onChange(of: isUseCurrentLocation) { _, newValue in
                            if newValue {
                                isSelectImageCoordinate = false
                                //　ピンの位置を現在地に移動する
                                self.coordinate = updateToCurrentLocation()
                            }
                        }
                    if selectedImage != nil {
                        Toggle("写真の画像の位置情報を使う", isOn: $isSelectImageCoordinate)
                            .toggleStyle(SwitchToggleStyle())
                            .onChange(of: isSelectImageCoordinate) { _, newValue in
                                if newValue {
                                    // 画像の位置情報を取得し、coordinateにセット
                                    if let imageCoordinate = gpsCoordinates {
                                        isUseCurrentLocation = false
                                        annotations = [AnnotatedLocation(coordinate: imageCoordinate)]
                                        region.center = imageCoordinate
                                        self.coordinate = imageCoordinate
                                    } else {
                                        // 位置情報が取得できない場合の処理
                                        isSelectImageCoordinate = false
                                        showErrorAlert = true
                                    }
                                }
                            }.alert(isPresented: $showErrorAlert) {
                                Alert(
                                    title: Text("エラー"),
                                    message: Text("画像に位置情報が含まれていません"),
                                    dismissButton: .default(Text("OK"))
                                )
                            }
                    }
                    Text("アイテム登録")
                        .font(.headline)
                    
                    TextField("Item Name", text: $itemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description", text: $itemDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SegmentStockPickerView(selectedStock: $selectedStock)
                    
                    SegmentCategoryPickerView(selectedCategory: $selectedCategory)
                    
                    TextField("Price", text: $itemPrice)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    
                    TextField("Quantity", text: $itemQuantity)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    if isDeleted {
                        Button(action: {
                            guard let selectedImage = selectedImage else { return }
                            guard let userId = LoginManager.shared.getUserID() else { return }
                            guard let intPrice = Int(itemPrice), let intQuantity = Int(itemQuantity),let resizedImage = resizeImageToHeight(image: selectedImage, targetHeight: 1024) ,let imageData = resizedImage.jpegData(compressionQuality: 0.7) else { return }
                            if let item = item {
                                let deleteItem = Item(id: item.id, name: itemName, description: itemDescription, price: intPrice, category:selectedCategory, coordinate: Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude), stock: intQuantity, stockCategory:selectedStock ,userId:userId, imageData:imageData)
                                onDelete(deleteItem)
                            }
                        }){
                            Text("削除する")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    
                    Button(action: {
                        // 登録処理
                        guard let selectedImage = selectedImage else { return }
                        guard let userId = LoginManager.shared.getUserID() else { return }
                        guard let intPrice = Int(itemPrice), let intQuantity = Int(itemQuantity),let resizedImage = resizeImageToHeight(image: selectedImage, targetHeight: 1024) ,let imageData = resizedImage.jpegData(compressionQuality: 0.7) else { return }
                        if let item = item {
                            let updateItem = Item(id: item.id, name: itemName, description: itemDescription, price: intPrice, category:selectedCategory, coordinate: Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude), stock: intQuantity, stockCategory:selectedStock ,userId:userId, imageData:imageData)
                            onRegister(updateItem)
                        } else {
                            let inputItem = Item(id: UUID().uuidString, name: itemName, description: itemDescription, price: intPrice, category:selectedCategory, coordinate: Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude), stock: intQuantity, stockCategory:selectedStock ,userId:userId, imageData:imageData)
                            onRegister(inputItem)
                        }
                        
                    }) {
                        Text(registerButtonText)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    // 条件に応じてボタンを無効化
                    .disabled(!isFormValid())
                    .padding()
                }
                .padding()
                Color.clear
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
            }
        }
        .onAppear(){
            annotations = [AnnotatedLocation(coordinate: coordinate)]
            if let item = item {
                itemName = item.name
                itemDescription = item.description
                itemPrice = String(item.price)
                selectedStock = item.stockCategory
                selectedCategory = item.category
                itemQuantity = String(item.stock)
                fetchImage(item:item)
                registerButtonText = "アイテムを更新する"
                isDeleted = true
            } else {
                registerButtonText = "アイテムを登録する"
                isDeleted = false
            }
        }
    }
    
    private func fetchImage(item: Item) {
        ItemPersistenceManager().fetchImage(from: item) { result in
            switch result {
            case .success(let image):
                DispatchQueue.main.async {
                    self.selectedImage = image
                }
            case .failure(let error):
                print("Error fetching image: \(error)")
            }
        }
    }
    
    // 入力がすべて有効か判定
    private func isFormValid() -> Bool {
        return !itemName.isEmpty && !itemDescription.isEmpty && !itemPrice.isEmpty &&  !itemQuantity.isEmpty && selectedImage != nil
    }

    private func updateToCurrentLocation() -> CLLocationCoordinate2D{
        if let location = locationManager.location?.coordinate {
            annotations = [AnnotatedLocation(coordinate: location)]
            region.center = location
            return location
        }
        return coordinate
    }

    func updateToImageLocation() -> CLLocationCoordinate2D?  {
        guard let image = selectedImage, let imageData = image.jpegData(compressionQuality: 1.0) else {
            isSelectImageCoordinate = false
            return nil
        }
        // 画像のメタデータを取得
        if let source = CGImageSourceCreateWithData(imageData as CFData, nil) {
            // メタデータの取得
            if let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
                if let gpsDict = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
                    if let latitude = gpsDict[kCGImagePropertyGPSLatitude as String] as? Double,
                       let longitude = gpsDict[kCGImagePropertyGPSLongitude as String] as? Double {
                        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    }
                }
            }
        }
        isSelectImageCoordinate = false
        return nil
    }


    private func updatePinFromMap() {
        let newLocation = AnnotatedLocation(coordinate: region.center)
        annotations = [newLocation]
    }

    private func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    // MARK: 写真ライブラリへのアクセス関連処理
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            showImagePicker = true // アクセスが許可されている場合、ピッカーを開く
        case .denied, .restricted:
            showPermissionAlert = true // アクセス拒否されている場合、アラートを表示
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
                        showImagePicker = true
                    } else {
                        showPermissionAlert = true
                    }
                }
            }
        @unknown default:
            showPermissionAlert = true
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct AnnotatedLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct SegmentStockPickerView: View {
    @Binding var selectedStock: StockCategory
    
    var body: some View {
        VStack {
            Text("在庫状況を選択してください")
            Picker("Options", selection: $selectedStock) {
                ForEach(StockCategory.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Text("選択中: \(selectedStock.rawValue)")
        }
        .padding()
    }
}

struct SegmentCategoryPickerView: View {
    @Binding var selectedCategory: ItemCategory
    
    var body: some View {
        VStack {
            Text("カテゴリーを選択してください")
            Picker("Options", selection: $selectedCategory) {
                ForEach(ItemCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                    Text(category.rawValue)
                        .tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Text("選択中: \(selectedCategory.rawValue)")
        }
        .padding()
    }
}

#Preview {
    ItemRegistrationView(
        coordinate: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
        region: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917), // 初期値：東京
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ),
        onRegister: { item in
            print("Preview Registration:")
            print("Item name: \(item.name), Category: \(item.category)")
        },
        onDelete: { item in
            print("Preview Delete")
        }
    )
}


