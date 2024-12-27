//
//  ContentView.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/19.
//

import SwiftUI

struct SideMenuView: View {
    let onSelectMode: (ContentMode) -> Void
    var body: some View {
        VStack {
            
            Button(action: {
                onSelectMode(ContentMode.itemMode)
            }) {
                Text("アイテムマップ")
            }
            Divider()
            Button(action: {
                onSelectMode(ContentMode.eventMode)
            }){
                Text("イベントマップ")
            }
            Divider()
            Button(action: {
                onSelectMode(ContentMode.catMode)
            }){
                Text("地域猫マップ")
            }
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
        SideMenuView(onSelectMode: { contentMode in
            print("\(contentMode)を選びました")
        })
            .frame(width: 250)
            .background(Color.white)
            .cornerRadius(10)
    }
}
