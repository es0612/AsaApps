import SwiftUI
import AsaUIKit

// MARK: - CreatePostView

struct CreatePostView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: EventDetailViewModel

    @State private var content = ""
    @State private var selectedType: EventPostType = .text
    @State private var isCreating = false

    @FocusState private var isTextFieldFocused: Bool

    // MARK: - Computed Properties

    private var canCreate: Bool {
        !content.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 投稿タイプ選択
                    typeSelector

                    // テキスト入力
                    textEditor

                    Spacer()
                }
            }
            .navigationTitle("投稿を作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("投稿") {
                        createPost()
                    }
                    .disabled(!canCreate || isCreating)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Subviews

    private var typeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach([EventPostType.text, .milestone, .announcement], id: \.self) { type in
                    typeButton(type)
                }
            }
            .padding()
        }
        .background(.white)
    }

    private func typeButton(_ type: EventPostType) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedType = type
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(typeDisplayName(type))
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(selectedType == type ? backgroundColor(for: type) : AsaColors.background)
            .foregroundStyle(selectedType == type ? .white : AsaColors.darkSlate)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var textEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            // プレースホルダー付きテキストエディタ
            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text(placeholderText)
                        .foregroundStyle(AsaColors.mutedSage)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }

                TextEditor(text: $content)
                    .focused($isTextFieldFocused)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4)

            // 文字数カウント
            HStack {
                Spacer()
                Text("\(content.count) / 500")
                    .font(.caption)
                    .foregroundStyle(content.count > 500 ? .red : AsaColors.mutedSage)
            }
        }
        .padding()
    }

    // MARK: - Methods

    private func typeDisplayName(_ type: EventPostType) -> String {
        switch type {
        case .text: return "テキスト"
        case .milestone: return "マイルストーン"
        case .announcement: return "お知らせ"
        case .photo: return "写真"
        }
    }

    private func backgroundColor(for type: EventPostType) -> Color {
        switch type {
        case .text: return AsaColors.coffeeBrown
        case .milestone: return .purple
        case .announcement: return AsaColors.mocha
        case .photo: return .cyan
        }
    }

    private var placeholderText: String {
        switch selectedType {
        case .text: return "今の様子を共有しましょう..."
        case .milestone: return "達成したことを記録しましょう..."
        case .announcement: return "参加者にお知らせしましょう..."
        case .photo: return "写真について説明しましょう..."
        }
    }

    private func createPost() {
        isCreating = true

        Task {
            do {
                try await viewModel.createPost(
                    content: content.trimmingCharacters(in: .whitespaces),
                    type: selectedType
                )
                isCreating = false
                dismiss()
            } catch {
                isCreating = false
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CreatePostView(
        viewModel: EventDetailViewModel(
            event: Event.sampleEvents[0],
            userId: "user-1",
            dataService: MockEventDataService()
        )
    )
}
