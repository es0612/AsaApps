//
//  EditIdeaView.swift
//  AsaCrowdsource
//
//  アイデア編集画面
//

import SwiftUI
import SwiftData
import AsaUIKit

struct EditIdeaView: View {
    // MARK: - Properties

    let idea: Idea
    let onUpdated: (Idea) -> Void

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var familyViewModel: FamilyGroupViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.localDataService) private var localDataService
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = CreateIdeaViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // カテゴリ選択
                    categorySection

                    // タイトル
                    titleSection

                    // 説明
                    descriptionSection

                    // エラーメッセージ
                    if let error = viewModel.errorMessage {
                        errorMessageView(error)
                    }
                }
                .padding(24)
            }
            .background(Color(AsaColors.softCream).opacity(0.3))
            .navigationTitle("アイデアを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Color(AsaColors.coffeeBrown))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        submitIdea()
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("更新")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isLoading)
                    .foregroundColor(viewModel.canSubmit ? Color(AsaColors.coffeeBrown) : Color(AsaColors.mutedSage))
                }
            }
            .onAppear {
                setupViewModel()
            }
        }
    }

    // MARK: - Subviews

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ")
                .font(.headline)
                .foregroundColor(Color(AsaColors.darkSlate))

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(IdeaCategory.allCases) { category in
                    CategoryButton(
                        category: category,
                        isSelected: viewModel.category == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.category = category
                        }
                    }
                }
            }
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("タイトル *")
                    .font(.headline)
                    .foregroundColor(Color(AsaColors.darkSlate))

                Spacer()

                Text("\(viewModel.titleCharacterCount)/100")
                    .font(.caption)
                    .foregroundColor(
                        viewModel.titleCharacterCount > 100 ? .red : Color(AsaColors.mutedSage)
                    )
            }

            TextField("アイデアのタイトルを入力", text: Binding(
                get: { viewModel.title },
                set: { viewModel.title = $0 }
            ))
            .textFieldStyle(RoundedTextFieldStyle())

            if !viewModel.isTitleValid && !viewModel.title.isEmpty {
                Text("タイトルは1〜100文字で入力してください")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("説明（任意）")
                    .font(.headline)
                    .foregroundColor(Color(AsaColors.darkSlate))

                Spacer()

                Text("\(viewModel.descriptionCharacterCount)/1000")
                    .font(.caption)
                    .foregroundColor(
                        viewModel.descriptionCharacterCount > 1000 ? .red : Color(AsaColors.mutedSage)
                    )
            }

            TextField("アイデアの詳細を入力", text: Binding(
                get: { viewModel.ideaDescription },
                set: { viewModel.ideaDescription = $0 }
            ), axis: .vertical)
            .textFieldStyle(RoundedTextFieldStyle())
            .lineLimit(5...10)

            if !viewModel.isDescriptionValid {
                Text("説明は1000文字以内で入力してください")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private func errorMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.footnote)
                .foregroundColor(.red)
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Private Methods

    private func setupViewModel() {
        // Environment経由で配布された共有のLocalDataServiceを利用（毎回new禁止）
        guard let dataService = localDataService else { return }
        viewModel.setDataService(dataService)

        if let group = familyViewModel.currentGroup {
            viewModel.setGroupId(group.id.uuidString)
        }

        if let user = authViewModel.currentUser {
            viewModel.setAuthor(id: user.id, name: user.displayName)
        }

        // 編集モードで初期化
        viewModel.setupForEditing(idea)
    }

    private func submitIdea() {
        Task {
            if let updatedIdea = await viewModel.submit() {
                onUpdated(updatedIdea)
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EditIdeaView(idea: Idea.sampleIdeas[0]) { _ in }
        .environmentObject(AuthViewModel())
        .environmentObject(FamilyGroupViewModel())
}
