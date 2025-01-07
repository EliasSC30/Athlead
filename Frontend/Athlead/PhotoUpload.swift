//
//  PhotoUpload.swift
//  Athlead
//
//  Created by Oezcan, Elias on 07.01.25.
//

import Foundation


import SwiftUI
import PhotosUI

struct UploadPhotoView: View {
    let onPicChanged: (String) -> Void
    @State private var selectedImage: UIImage? = nil
    @State private var isPickerPresented = false
    @State private var uploadStatus = ""

    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                Text("No image selected")
                    .foregroundColor(.gray)
            }

            Button("Select Photo") {
                isPickerPresented = true
            }
            .padding()
            .sheet(isPresented: $isPickerPresented) {
                PhotoPicker(image: $selectedImage)
            }

            if selectedImage != nil {
                Button("Upload Photo") {
                    uploadPhoto()
                }
                .padding()
            }

            Text(uploadStatus)
                .foregroundColor(.blue)
                .padding()
        }
    }

    func uploadPhoto() {
        guard let image = selectedImage else { return }

        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            uploadStatus = "Failed to encode image"
            return
        }
        let base64String = imageData.base64EncodedString()
        
        if User == nil {
            print("Should never happen! User invalid but wants to upload photo")
            return
        }
        let toSend = UploadPhoto(name: User.unsafelyUnwrapped.ID, data: base64String);
        
        fetch("photos", UploadPhotoResponse.self, "POST", nil, toSend){
            response in
            switch response {
            case .success(let res): onPicChanged(base64String)
            case .failure(let err): print("Couldn't upload photo", err)
            }
        }
        
    }
}

// Photo Picker Implementation
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

