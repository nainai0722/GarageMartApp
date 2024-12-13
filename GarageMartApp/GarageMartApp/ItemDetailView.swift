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
                Image(uiImage: UIImage(data: item.imageData!) ?? UIImage(named: "ventilation_color")!)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                
                // 名前
                Text(item.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding([.top, .horizontal])
                
                // 説明事項
                Text(item.description)
                    .font(.body)
                    .padding([.horizontal, .bottom])
            }
            .background(GeometryReader { geometry in
                Color.clear.onChange(of: geometry.frame(in: .global).minY) { value in
                    scrollOffset = value
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

#Preview {
    @Previewable @State var isPresented = false
    let item = Item(id: UUID(), name: "test", description: "testtest", price: 100, category:.dailyGoods, imageUrl: "", coordinate: Coordinate(latitude: 0, longitude: 0), stock: 1, stockCategory:.many, image:UIImage(named: "ventilation_color")!) // 仮のItemを作成

    ItemDetailView(isPresented: $isPresented, item: item)
}
