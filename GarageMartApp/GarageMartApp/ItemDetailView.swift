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
    @State var count : Int = 0
    @State var isEditEnabled:Bool
    @State private var isButtonDisabled: Bool = true // ボタンの無効化状態を管理
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
                    .font(.caption)
                    .padding([.horizontal, .bottom])
                
                HStack {
                    Text(item.category.rawValue)
                        .font(.body)
                        .padding(8) // 同じく内側の余白
                        .background(Color(.lightGray))
                        .cornerRadius(10)
                        .shadow(radius: 5,x: 5 ,y: 5)
                    Text(item.stockCategory.rawValue)
                        .font(.body)
                        .padding(8) // 同じく内側の余白
                        .background(Color(.lightGray))
                        .cornerRadius(10)
                        .shadow(radius: 5,x: 5 ,y: 5)
                }
                Text("金額 : " + String(item.price) + "円")
                    .font(.title)
                sameUserItemsHorizontalScrollView(item: item)
                Button(action:{
                    wishListButtonAction()
                }){
                    Text(isButtonDisabled ? "買いたい済" : "買いたい")
                }
                .buttonStyle(CustomButtonStyle(isDisabled: isButtonDisabled))
                .disabled(isButtonDisabled)
                
                Text("買いたい人が\(count)人います")
                    .font(.headline)
            
                if isEditEnabled {
                    Button(action:{
                        // 編集画面に行く
                    }){
                        Text("編集する")
                            .background(Color(.blue))
                    }
                    .buttonStyle(CustomButtonStyle(isDisabled: isButtonDisabled))
                }
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
            checkEditUser()
            Task {
                checkIsCounted()
            }
        }
        .onDisappear {
            // モーダルが閉じられる際の処理
            isPresented = false
        }
    }
    private func checkEditUser() {
        guard let userId = LoginManager.shared.getUserID() else { return }
        if item.userId == userId {
            isEditEnabled = true
        }else {
            isEditEnabled = false
        }
    }
    
    private func checkIsCounted() {
        guard let userId = LoginManager.shared.getUserID() else {
            isButtonDisabled = true
            return
        }

        BasicUserPersistenceManager().loadBasicUsers { basicUsers in
            var sum = 0
            for basicUser in basicUsers {
                for itemId in basicUser.wishList {
                    if itemId == item.id {
                        sum += 1
                    }
                }
            }
            
            let currentBasicUser = basicUsers.first { $0.userId == userId }
            let matchItem = currentBasicUser?.wishList.contains(item.id) ?? false
            
            DispatchQueue.main.async {
                isButtonDisabled = matchItem
                count = sum
            }
        }
    }
    
    private func wishListButtonAction() {
        guard let userId = LoginManager.shared.getUserID() else { return }

        BasicUserPersistenceManager().loadBasicUsers{ basicUsers in
            let currentBasicUser = basicUsers.filter{ $0.userId == userId}.first
            let matchItem = currentBasicUser?.wishList.filter{ $0 == item.id }.first
            if matchItem == nil {
                if currentBasicUser == nil {
                    let basicUser = BasicUser(userId: userId, userName: "無名ユーザー", wishList: [item.id])
                    BasicUserPersistenceManager().save(basicUser: basicUser)
                    count += 1
                    isButtonDisabled = false
                }else {
                    if var currentBasicUser = currentBasicUser {
                        currentBasicUser.wishList.append(item.id)
                        
                        // 更新された currentBasicUser を保存
                        BasicUserPersistenceManager().update(basicUser:currentBasicUser)
                        count += 1
                        isButtonDisabled = false
                    }
                }
            }
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


struct sameUserItemsHorizontalScrollView: View {
    var item: Item!
    @State private var filteredItems: [Item] = [] // 非同期で取得したデータを保持する
    var body: some View {
        Text("\(item.userId)さんは他にもアイテムを登録しています")
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(filteredItems, id: \.id) { filteredItem in
                    ItemCardView(item: filteredItem)
                        .frame(width: 200, height: 150) // 子要素のサイズを固定
                        .background(Color(.lightGray)) // レイアウトを確認
                        .cornerRadius(5)
                        .padding(5)
                        .shadow(radius: 5,x: 5 ,y: 5)
                        .padding(.horizontal)
                }
            }
        }
        .onAppear {
            loadFilteredItems(for: item)
        }
    }
    private func loadFilteredItems(for item:Item){
        let itemPersistenceManager = ItemPersistenceManager()
        itemPersistenceManager.loadItems{ items in
            DispatchQueue.main.async {
                self.filteredItems = items.filter{ $0.userId == item.userId }
            }
            
        }
    }
}

struct ItemCardView: View {
    var item: Item!
    var body: some View {
        VStack {
            Text(item.name)
            Text(item.description)
        }
        
    }
}

#Preview {
    @Previewable @State var isPresented = false
    let item = Item(id: "12345", name: "テスト", price: 1000, category: ItemCategory.toy, coordinate: Coordinate(latitude: 0, longitude: 0), stock: 1, stockCategory: StockCategory.few,userId: "testUser", imageData:UIImage(named: "ventilation_color")!.pngData()!) // 仮のItemを作成
    
    ItemDetailView(isPresented: $isPresented, item: item, isEditEnabled: false)
}
