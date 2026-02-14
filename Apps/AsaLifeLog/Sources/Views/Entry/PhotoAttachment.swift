import SwiftUI
import PhotosUI

// MARK: - PhotoAttachment

/// 写真添付ビュー
struct PhotoAttachment: View {
    @Binding var identifiers: [String]
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 5,
                matching: .images
            ) {
                Label("写真を追加", systemImage: "photo.badge.plus")
            }

            if !identifiers.isEmpty {
                Text("\(identifiers.count)枚の写真を添付済み")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: selectedItems) {
            Task {
                var newIdentifiers: [String] = []
                for item in selectedItems {
                    if let id = item.itemIdentifier {
                        newIdentifiers.append(id)
                    }
                }
                if !newIdentifiers.isEmpty {
                    identifiers = newIdentifiers
                }
            }
        }
    }
}
