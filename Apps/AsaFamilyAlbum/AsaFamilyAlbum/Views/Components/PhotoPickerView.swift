//
//  PhotoPickerView.swift
//  AsaFamilyAlbum
//
//  Created on 2025/10/14
//

import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    let album: Album
    var viewModel: FamilyAlbumViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var successCount = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 選択状態の表示
                if !selectedItems.isEmpty {
                    SelectionStatusView(count: selectedItems.count)
                }

                // PhotosPicker
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 50,
                    matching: .images
                ) {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 64))
                            .foregroundColor(Color("AsaMutedSage"))

                        VStack(spacing: 8) {
                            Text("写真を選択")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("AsaDarkSlate"))

                            Text("最大50枚まで選択できます")
                                .font(.body)
                                .foregroundColor(Color("AsaMocha"))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PlainButtonStyle())

                // 処理中の表示
                if isProcessing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color("AsaCoffeeBrown"))

                        Text("写真を追加しています...")
                            .font(.body)
                            .foregroundColor(Color("AsaMocha"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color("AsaSoftCream").opacity(0.5))
                }

                // エラーメッセージ
                if let errorMessage = errorMessage {
                    ErrorMessageView(message: errorMessage) {
                        self.errorMessage = nil
                    }
                }

                // 成功メッセージ
                if successCount > 0 && !isProcessing {
                    SuccessMessageView(count: successCount)
                }
            }
            .background(Color("AsaSoftCream").opacity(0.3))
            .navigationTitle("写真を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color("AsaMocha"))
                    .disabled(isProcessing)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        Task {
                            await addPhotosToAlbum()
                        }
                    }
                    .foregroundColor(Color("AsaCoffeeBrown"))
                    .disabled(selectedItems.isEmpty || isProcessing)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func addPhotosToAlbum() async {
        isProcessing = true
        errorMessage = nil
        successCount = 0

        var addedCount = 0
        var errors: [Error] = []

        for item in selectedItems {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {

                    // UIImageからPhotoモデルを作成してアルバムに追加
                    await viewModel.addPhotoFromImage(uiImage, to: album)
                    addedCount += 1
                }
            } catch {
                errors.append(error)
            }
        }

        await MainActor.run {
            successCount = addedCount
            isProcessing = false

            if !errors.isEmpty {
                errorMessage = "\(errors.count)枚の写真の追加に失敗しました"
            }

            // 成功した場合は少し待ってから自動で閉じる
            if addedCount > 0 && errors.isEmpty {
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5秒
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SelectionStatusView: View {
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color("AsaCoffeeBrown"))

            Text("\(count)枚選択中")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(Color("AsaDarkSlate"))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("AsaCoffeeBrown").opacity(0.1))
    }
}

struct ErrorMessageView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Color("AsaMocha"))

            Text(message)
                .font(.body)
                .foregroundColor(Color("AsaDarkSlate"))

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color("AsaMutedSage"))
            }
        }
        .padding(16)
        .background(Color("AsaMocha").opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct SuccessMessageView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

            Text("\(count)枚の写真を追加しました")
                .font(.body)
                .foregroundColor(Color("AsaDarkSlate"))

            Spacer()
        }
        .padding(16)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    PhotoPickerView(album: Album.sampleAlbums[0], viewModel: FamilyAlbumViewModel())
}
