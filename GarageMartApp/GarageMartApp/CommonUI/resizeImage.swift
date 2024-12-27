//
//  resizeImage.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/26.
//

import UIKit

func resizeImageToHeight(image: UIImage, targetHeight: CGFloat) -> UIImage? {
    let originalSize = image.size
    let scaleFactor = targetHeight / originalSize.height
    let targetWidth = originalSize.width * scaleFactor
    let targetSize = CGSize(width: targetWidth, height: targetHeight)
    
    UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: targetSize))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return resizedImage
}
