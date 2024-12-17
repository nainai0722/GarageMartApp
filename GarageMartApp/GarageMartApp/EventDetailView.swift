//
//  EventDetailView.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/12.
//

import SwiftUI

struct EventDetailView: View {
    @Binding var isPresented: Bool
    var event: Event!
    
    @State private var scrollOffset: CGFloat = 0.0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Spacer()
                // 画像
                Image(uiImage: getEventImage(from: event.imageData))
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                
                // イベント名
                Text(event.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding([.top, .horizontal])
                
                // 説明事項
                Text(event.description)
                    .font(.body)
                    .padding([.horizontal, .bottom])
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
    
    func getEventImage(from data: Data?) -> UIImage {
        if let data = data, let image = UIImage(data: data) {
            return image
        } else {
            return UIImage(named: "ventilation_color")!
        }
    }
}

#Preview {
    @Previewable @State var isPresented = false
    let event = Event(title: "マーケット開催中", description: "日用品色々揃えています", startDate: Date(), endDate: Date(), coordinate: Coordinate(latitude: 0, longitude: 0), userId: "testUser") // 仮のEventを作成

    EventDetailView(isPresented: $isPresented, event: event)
}
