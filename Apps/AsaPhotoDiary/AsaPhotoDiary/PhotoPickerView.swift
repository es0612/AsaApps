//
//  PhotoPickerView.swift
//  AsaPhotoDiary
//  
//  Created on 2025/07/05
//

import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var selectedImageData: Data?
    @Binding var selectedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 16) {
            // 写真表示エリア
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 2)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("写真を選択してください")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // 写真選択ボタン
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                    Text(selectedImage == nil ? "写真を選択" : "写真を変更")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("AsaCoffeeBrown"))
                .cornerRadius(10)
                .shadow(radius: 2)
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    await loadImage(from: newValue)
                }
            }
            
            // 写真削除ボタン
            if selectedImage != nil {
                Button(action: {
                    selectedPhoto = nil
                    selectedImageData = nil
                    selectedImage = nil
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.title2)
                        Text("写真を削除")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("AsaMutedSage"))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
            }
        }
        .padding()
    }
    
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    selectedImageData = data
                    selectedImage = uiImage
                }
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
}

#Preview {
    PhotoPickerView(
        selectedPhoto: .constant(nil),
        selectedImageData: .constant(nil),
        selectedImage: .constant(nil)
    )
    .background(Color("AsaSoftCream"))
}