import SwiftUI
import PhotosUI
import AsaUIKit

/// 写真選択シート
/// PhotosUI PhotosPickerを使用して複数写真を選択する
struct PhotoPickerSheetView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoading = false

    let onPhotosSelected: ([Data]) -> Void

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 説明テキスト
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(AsaColors.coffeeBrown)

                    Text("写真を選択")
                        .font(.title2.bold())
                        .foregroundColor(AsaColors.darkSlate)

                    Text("ストーリーに追加する写真を選んでください")
                        .font(.subheadline)
                        .foregroundColor(AsaColors.mutedSage)
                }
                .padding(.top, 32)

                // PhotosPicker
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 20,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text("写真ライブラリから選択")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AsaColors.coffeeBrown)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                // 選択状態表示
                if !selectedItems.isEmpty {
                    Text("\(selectedItems.count)枚の写真を選択中")
                        .font(.subheadline.bold())
                        .foregroundColor(AsaColors.coffeeBrown)
                }

                if isLoading {
                    ProgressView("写真を読み込み中...")
                        .progressViewStyle(.circular)
                }

                Spacer()

                // 追加ボタン
                if !selectedItems.isEmpty {
                    AsaButton(
                        title: "追加する",
                        action: { loadSelectedPhotos() },
                        color: AsaColors.coffeeBrown,
                        isEnabled: !isLoading
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("写真を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
    }

    // MARK: - Methods

    private func loadSelectedPhotos() {
        isLoading = true
        Task {
            var imageDataArray: [Data] = []
            for item in selectedItems {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    imageDataArray.append(data)
                }
            }
            await MainActor.run {
                isLoading = false
                onPhotosSelected(imageDataArray)
                dismiss()
            }
        }
    }
}

#Preview {
    PhotoPickerSheetView { _ in }
}
