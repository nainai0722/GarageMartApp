//
//  ItemDetailView.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/11.
//

import SwiftUI

struct ItemDetailView: View {
    @Binding var isPresented: Bool
    var item: Item!
    
    @State private var scrollOffset: CGFloat = 0.0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Spacer()
                // 画像
                ItemImageView(item: item)
        
                // 名前
                Text(item.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding([.top, .horizontal])
                
                // 説明事項
                Text(item.description)
                    .font(.body)
                    .padding([.horizontal, .bottom])
                Text(item.category.rawValue)
                    .font(.title)
                Text(item.stockCategory.rawValue)
                    .font(.title)
                Text(String(item.price))
                    .font(.title)
            }
            .background(GeometryReader { geometry in
                Color.clear.onChange(of: geometry.frame(in: .global).minY) { _, newValue in
                    scrollOffset = newValue
                }
            })
        }
        .onAppear {
            // ハーフモーダル表示設定
            if let sheet = UIApplication.shared.windows.first?.rootViewController?.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
        .onDisappear {
            // モーダルが閉じられる際の処理
            isPresented = false
        }
    }
}

struct ItemImageView: View {
    var item: Item!
    @State private var uiImage: UIImage? = nil // For storing the fetched image
    var body: some View {
        if let uiImage = uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
        } else {
            Image("ventilation_color") // Placeholder
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .onAppear {
                    fetchImage()
                }
        }
    }
    
    private func fetchImage() {
        ItemPersistenceManager().fetchImage(from: item) { result in
            switch result {
            case .success(let image):
                DispatchQueue.main.async {
                    self.uiImage = image
                }
            case .failure(let error):
                print("Error fetching image: \(error)")
            }
        }
    }
}


#Preview {
    @Previewable @State var isPresented = false
    let item = Item(id: "12345", name: "テスト", price: 1000, category: ItemCategory.toy, coordinate: Coordinate(latitude: 0, longitude: 0), stock: 1, stockCategory: StockCategory.few,userId: "testUser", imageData:UIImage(named: "ventilation_color")!.pngData()!) // 仮のItemを作成
    
    ItemDetailView(isPresented: $isPresented, item: item)
}
