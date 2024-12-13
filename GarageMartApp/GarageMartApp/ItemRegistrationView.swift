//
//  ItemRegistrationView.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/10.
//

import SwiftUI
import MapKit

struct ItemRegistrationView: View {
    var coordinate: CLLocationCoordinate2D
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false // 画像ピッカーを表示するためのフラグ
    @State private var itemName: String = ""
    @State private var itemDescription: String = ""
    @State private var itemPrice: String = ""
    @State private var itemQuantity: String = ""
    @State private var selectedStock: StockCategory = .only
    @State private var selectedCategory: ItemCategory = .food
    let onRegister: (Item,UIImage) -> Void
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
                        showImagePicker.toggle()
                    }) {
                        Text("画像を選択")
                    }
                    .sheet(isPresented: $showImagePicker) {
                        // 画像ピッカーの表示
                        ImagePicker(selectedImage: $selectedImage)
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
                    
                    Button(action: {
                        // 登録処理
                        guard let intPrice = Int(itemPrice), let intQuantity = Int(itemQuantity) else { return }
                        let inputItem = Item(id: UUID(), name: itemName, description: itemDescription, price: intPrice, category:selectedCategory, imageUrl: "", coordinate: Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude), stock: intQuantity, stockCategory:selectedStock ,image: selectedImage)
                        guard let selectedImage = selectedImage else { return }
                        onRegister(inputItem,selectedImage)
                    }) {
                        Text("アイテムを登録する")
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
    }
    // 入力がすべて有効か判定
    private func isFormValid() -> Bool {
        return !itemName.isEmpty && !itemDescription.isEmpty && !itemPrice.isEmpty &&  !itemQuantity.isEmpty && selectedImage != nil
    }
    private func selectImage() {
        // 画像選択のロジック（後述）
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
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
        onRegister: { item, image in
            print("Preview Registration:")
            print("Item name: \(item.name), Category: \(item.category)")
        }
    )
}


