//
//  PHPicker.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/20.
//

import SwiftUI
import PhotosUI

public struct PHPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var gpsCoordinates: CLLocationCoordinate2D?

    public class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PHPicker

        init(parent: PHPicker) {
            self.parent = parent
        }

        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let result = results.first else { return }
            
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                    guard let self = self, let image = object as? UIImage else { return }
                        DispatchQueue.main.async {
                            self.parent.selectedImage = image
                        }
                    result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.jpeg") { data, error in
                        guard let data = data else { return }

                        // Extract EXIF metadata
                        if let source = CGImageSourceCreateWithData(data as CFData, nil),
                           let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
                           let gpsDict = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any],
                           let latitude = gpsDict[kCGImagePropertyGPSLatitude as String] as? Double,
                           let longitude = gpsDict[kCGImagePropertyGPSLongitude as String] as? Double {
                            
                            let latRef = gpsDict[kCGImagePropertyGPSLatitudeRef as String] as? String
                            let lonRef = gpsDict[kCGImagePropertyGPSLongitudeRef as String] as? String

                            let adjustedLatitude = (latRef == "S") ? -latitude : latitude
                            let adjustedLongitude = (lonRef == "W") ? -longitude : longitude

                            DispatchQueue.main.async {
                                self.parent.gpsCoordinates = CLLocationCoordinate2D(latitude: adjustedLatitude, longitude: adjustedLongitude)
                            }
                        }
                    }
                }
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1 // 1枚のみ選択可能
        configuration.filter = .images // 画像のみ選択

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // 必要に応じて更新処理を記述
    }

}

#Preview {
//    PHPicker(selectedImage: UIImage(named:"ventilation_color")? )
}
