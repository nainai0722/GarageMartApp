//
//  CustomButtonStyle.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/18.
//

import SwiftUI

/// ボタンのスタイルを角丸・青色背景・白文字・フォントサイズheadline・disabled制御を指定する
struct CustomButtonStyle: ButtonStyle {
    var isDisabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(isDisabled ? Color.gray : Color.blue)
            .cornerRadius(5)
            .tint(.white)
            .font(.headline)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .shadow(radius: 5,x: 5 ,y: 5)
            .disabled(isDisabled)
    }
}
