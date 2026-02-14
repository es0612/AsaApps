import SwiftUI
import AsaLifeLogKit

// MARK: - PhotoGridView

/// 写真グリッドビュー
struct PhotoGridView: View {
    let identifiers: [String]
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
    ]

    var body: some View {
        if identifiers.isEmpty {
            Text("写真なし")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(identifiers, id: \.self) { identifier in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                }
            }
        }
    }
}
