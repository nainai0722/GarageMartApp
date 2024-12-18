//
//  ContentView.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/19.
//

import SwiftUI

import SwiftUI

struct SideMenuView: View {
    var body: some View {
        VStack {
            Text("メニュー項目 1")
            Divider()
            Text("メニュー項目 2")
            Divider()
            Text("メニュー項目 3")
            Divider()
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuView()
            .frame(width: 250)
            .background(Color.white)
            .cornerRadius(10)
    }
}


struct ContentView: View {
    @State private var menuVisible = false // メニューの表示・非表示
    
    var body: some View {
        NavigationView {
            ZStack {
                // メインのコンテンツ
                VStack {
                    Text("Main Content Here")
                        .font(.largeTitle)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                
                // 横スワイプメニュー
                if menuVisible {
                    HStack {
                        MenuView()
                            .frame(width: 250)
                            .transition(.move(edge: .leading)) // 横からスライドイン
                    }
                    .background(Color.black.opacity(0.5).edgesIgnoringSafeArea(.all))
                    .onTapGesture {
                        withAnimation {
                            menuVisible = false
                        }
                    }
                }
                
                // メニューアイコン（左上）
                HStack {
                    Button(action: {
                        withAnimation {
                            menuVisible.toggle()
                        }
                    }) {
                        Image(systemName: "person.crop.circle.fill") // アイコン画像（丸型）
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.black)
                            .padding(10)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
            .navigationBarHidden(true) // ナビゲーションバーを隠す
        }
    }
}

struct MenuView: View {
    var body: some View {
        VStack {
            Text("メニューアイテム1")
            Divider()
            Text("メニューアイテム2")
            Divider()
            Text("メニューアイテム3")
            Divider()
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
