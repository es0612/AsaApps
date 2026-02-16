import SwiftUI
import AsaUIKit

// MARK: - フォトハイライトビュー

/// 家族のフォトハイライト表示
struct PhotoHighlightView: View {
    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("フォトハイライト")
                    .font(.headline)
                Spacer()
                Button("すべて見る") {}
                    .font(.caption)
                    .foregroundStyle(AsaColors.coffeeBrown)
            }

            // フォトプレースホルダー
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        photoPlaceholder(index)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        )
    }

    // MARK: - Private

    private func photoPlaceholder(_ index: Int) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: gradientColors(for: index),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 100, height: 100)
            .overlay {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.6))
            }
    }

    private func gradientColors(for index: Int) -> [Color] {
        let palettes: [[Color]] = [
            [AsaColors.coffeeBrown.opacity(0.4), AsaColors.mocha.opacity(0.3)],
            [.purple.opacity(0.3), .indigo.opacity(0.2)],
            [.orange.opacity(0.3), .yellow.opacity(0.2)],
            [AsaColors.mutedSage.opacity(0.4), .teal.opacity(0.2)],
        ]
        return palettes[index % palettes.count]
    }
}
