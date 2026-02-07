import SwiftUI
import AsaUIKit
import AsaPhotoStoryKit

/// AIキャプション提案ビュー
/// 画像分析によるキャプション候補を表示し、選択・編集を可能にする
struct CaptionSuggestionView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    let elementId: UUID
    let onApply: (String) -> Void

    @State private var isAnalyzing = true
    @State private var suggestions: [String] = []
    @State private var selectedCaption = ""
    @State private var customCaption = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if isAnalyzing {
                    loadingView
                } else {
                    captionListView
                }
            }
            .padding()
            .navigationTitle("キャプション提案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("適用") {
                        let caption = customCaption.isEmpty ? selectedCaption : customCaption
                        onApply(caption)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(AsaColors.coffeeBrown)
                    .disabled(selectedCaption.isEmpty && customCaption.isEmpty)
                }
            }
            .task {
                await generateSuggestions()
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)
                .tint(AsaColors.coffeeBrown)

            Text("写真を分析中...")
                .font(.headline)
                .foregroundColor(AsaColors.darkSlate)

            Text("AIがキャプションを生成しています")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)

            Spacer()
        }
    }

    private var captionListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // AI提案セクション
                Text("提案されたキャプション")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                ForEach(suggestions, id: \.self) { suggestion in
                    SuggestionRow(
                        text: suggestion,
                        isSelected: selectedCaption == suggestion
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCaption = suggestion
                            customCaption = ""
                        }
                    }
                }

                Divider()
                    .padding(.vertical, 8)

                // カスタムキャプションセクション
                Text("自分で入力")
                    .font(.headline)
                    .foregroundColor(AsaColors.darkSlate)

                TextField("キャプションを入力...", text: $customCaption, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .onChange(of: customCaption) { _, newValue in
                        if !newValue.isEmpty {
                            selectedCaption = ""
                        }
                    }
            }
        }
    }

    // MARK: - Methods

    private func generateSuggestions() async {
        // シミュレーション: AI分析の遅延
        try? await Task.sleep(for: .seconds(1.5))

        await MainActor.run {
            suggestions = [
                "家族との素敵な思い出",
                "笑顔あふれるひととき",
                "大切な瞬間をいつまでも",
                "幸せがいっぱいの一枚",
                "心温まる家族の時間",
            ]
            isAnalyzing = false
        }
    }
}

// MARK: - SuggestionRow

private struct SuggestionRow: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AsaColors.coffeeBrown : AsaColors.mutedSage)

                Text(text)
                    .font(.body)
                    .foregroundColor(AsaColors.darkSlate)

                Spacer()
            }
            .padding()
            .background(isSelected ? AsaColors.softCream : AsaColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AsaColors.coffeeBrown : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CaptionSuggestionView(elementId: UUID()) { _ in }
}
