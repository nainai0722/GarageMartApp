//
//  ItemAnnotationView.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/11.
//

import MapKit

class ItemAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "ItemAnnotationView"

    override var annotation: MKAnnotation? {
        didSet {
            configure()
        }
    }

    private func configure() {
        guard let itemAnnotation = annotation as? ItemAnnotation else { return }

        // アイコン画像の設定
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
//        TODO: これは良くないけれど一旦保留
        imageView.image = UIImage(data: itemAnnotation.item.imageData!)
        imageView.layer.cornerRadius = 5 // 半径で角丸
        imageView.layer.masksToBounds = true

        // アノテーションビューに設定
        self.addSubview(imageView)
        self.frame = imageView.frame
        self.canShowCallout = true // タップ時に吹き出しを表示
    }
}
