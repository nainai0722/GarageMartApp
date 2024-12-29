//
//  CatRegistrationView.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/23.
//

import SwiftUI
import CoreLocation
import PhotosUI
import Photos

struct CatRegistrationView: View {
    let coordinate: CLLocationCoordinate2D
    @State var gpsCoordinates: CLLocationCoordinate2D?
    @State private var showPermissionAlert = false
    let onRegister: (Cat) -> Void
    @State var cat:Cat?
    @State private var name:String = ""
    @State private var description:String = ""
    @State private var selectedHealth: HealthStatus = .good
    @State private var selectedColor: ColorCategory = .black
    @State private var selectedAge: AgeCategory = .kitten
    @State private var selectedPattern: Pattern = .bicolor
    @State private var selectedImage:UIImage?
    @State private var showImagePicker = false // 画像ピッカーを表示するためのフラグ
    @Environment(\.presentationMode) private var presentationMode
    
    init(cat: Cat? = nil, coordinate: CLLocationCoordinate2D, onRegister: @escaping (Cat) -> Void) {
        self.cat = cat
        self.coordinate = coordinate
        self.onRegister = onRegister
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("名前を入力", text: $name)
                    TextField("詳細を入力", text: $description)
                    // 他のフィールドも追加できます
                    SegmentHealthPickerView(selectedHealth: $selectedHealth)
                    SegmentAgePickerView(selectedAge: $selectedAge)
                    ColorGridView(selectedColor: $selectedColor)
                    PatternGridView(selectedPattern: $selectedPattern)
                }
                Section(header: Text("画像")) {
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
                    
                }
            }
            .navigationTitle("猫を登録")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let location = Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        guard let selectedImage = selectedImage else { return }
                        guard let userId = LoginManager.shared.getUserID() else { return }
                        guard let resizedImage = resizeImageToHeight(image: selectedImage, targetHeight: 1024),let imageData = resizedImage.jpegData(compressionQuality: 0.7)
                        else { return }
                        let cat = Cat(id: UUID().uuidString, name: name, pattern: .bicolor, colorCategory: selectedColor, healthStatus: selectedHealth, ageCategory: .adult, coordinate: Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude), userId: "TestUser",imageData: imageData)
                        onRegister(cat)
                        presentationMode.wrappedValue.dismiss()
                    }.disabled(validated())
                }
            }
        }
    }
    func validated() -> Bool {
        if !name.isEmpty{
            return false
        }
        return true
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
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

struct SegmentHealthPickerView: View {
    @Binding var selectedHealth: HealthStatus
    
    var body: some View {
        VStack {
            Text("健康状態を選択してください")
            Picker("Options", selection: $selectedHealth) {
                ForEach(HealthStatus.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
    }
}

struct ColorGridView: View {
    @Binding var selectedColor: ColorCategory

    let columns = [GridItem(.adaptive(minimum: 100))]

    var body: some View {
        VStack {
            Text("毛の色を選択してください")
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(ColorCategory.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedColor == category ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .onTapGesture {
                            selectedColor = category
                        }
                }
            }
            .padding()
        }
    }
}

struct PatternGridView: View {
    @Binding var selectedPattern: Pattern

    let columns = [GridItem(.adaptive(minimum: 100))]

    var body: some View {
        VStack {
            Text("模様や柄を選択してください")
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Pattern.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedPattern == category ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .onTapGesture {
                            selectedPattern = category
                        }
                }
            }
            .padding()
        }
    }
}


//selectedAge
struct SegmentAgePickerView: View {
    @Binding var selectedAge: AgeCategory
    
    var body: some View {
        VStack {
            Text("おおよその年齢を選択してください")
            Picker("Options", selection: $selectedAge) {
                ForEach(AgeCategory.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
    }
}

#Preview {
    let cat = Cat(name: "はっち")
    CatRegistrationView(cat: cat, coordinate: CLLocationCoordinate2D(),onRegister: { cat in
        print("\(cat.name)")
    })
}

