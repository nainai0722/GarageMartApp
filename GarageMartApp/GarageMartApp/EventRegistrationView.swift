//
//  EventRegistrationView.swift
//  GarageMartApp
//
//  Created by 指原奈々 on 2024/12/12.
//

import SwiftUI
import CoreLocation

struct EventRegistrationView: View {
    let coordinate: CLLocationCoordinate2D
    let onRegister: (Event, UIImage?) -> Void
    @State private var showImagePicker = false // 画像ピッカーを表示するためのフラグ
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                }
                Section(header: Text("Date and Time")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                Section(header: Text("Location")) {
                    Text("Latitude: \(coordinate.latitude)")
                    Text("Longitude: \(coordinate.longitude)")
                }
                Section(header: Text("Image")) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    } else {
                        Button(action: {
                            showImagePicker.toggle()
                        }) {
                            Text("画像を選択")
                        }
                        .sheet(isPresented: $showImagePicker) {
                            // 画像ピッカーの表示
                            ImagePicker(selectedImage: $selectedImage)
                        }
                    }
                }
            }
            .navigationTitle("Register Event")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let location = Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
                        guard let userId = LoginManager.shared.getUserID() else { return }
                        let newEvent = Event(
                            title: title,
                            description: description,
                            startDate: startDate,
                            endDate: endDate,
                            coordinate: location,
                            image: selectedImage?.pngData(),
                            userId:userId
                        )
                        onRegister(newEvent, selectedImage)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct EventRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        EventRegistrationView(coordinate: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917)) { _, _ in }
    }
}
