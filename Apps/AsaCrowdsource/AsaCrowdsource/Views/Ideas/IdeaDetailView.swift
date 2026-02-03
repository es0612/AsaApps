//
//  IdeaDetailView.swift
//  AsaCrowdsource
//
//  アイデア詳細画面
//

import SwiftUI
import SwiftData
import AsaUIKit

struct IdeaDetailView: View {
    // MARK: - Properties

    let ideaId: UUID
    let onUpdate: (Idea) -> Void
    let onDelete: () -> Void

    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = IdeaDetailViewModel()
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var newComment = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let idea = viewModel.idea {
                    ideaContent(idea)
                } else {
                    errorView
                }
            }
            .navigationTitle("アイデア詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        if let idea = viewModel.idea {
                            onUpdate(idea)
                        }
                        dismiss()
                    }
                }

                if viewModel.canEdit || viewModel.canDelete {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            if viewModel.canEdit {
                                Button {
                                    showEditSheet = true
                                } label: {
                                    Label("編集", systemImage: "pencil")
                                }
                            }

                            if viewModel.canProgressStatus {
                                Button {
                                    Task {
                                        await viewModel.progressStatus()
                                    }
                                } label: {
                                    if let nextStatus = viewModel.idea?.status.nextStatus {
                                        Label("「\(nextStatus.displayName)」に進める", systemImage: "arrow.right.circle")
                                    }
                                }
                            }

                            if viewModel.canDelete {
                                Divider()
                                Button(role: .destructive) {
                                    showDeleteAlert = true
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(Color(AsaColors.coffeeBrown))
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let idea = viewModel.idea {
                    EditIdeaView(idea: idea) { updatedIdea in
                        viewModel.idea = updatedIdea
                    }
                }
            }
            .alert("アイデアを削除", isPresented: $showDeleteAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    Task {
                        let success = await viewModel.deleteIdea()
                        if success {
                            onDelete()
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("このアイデアを削除しますか？この操作は取り消せません。")
            }
            .task {
                setupViewModel()
                await viewModel.loadIdea(id: ideaId)
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Text("読み込み中...")
                .font(.subheadline)
                .foregroundColor(Color(AsaColors.mutedSage))
            Spacer()
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(Color(AsaColors.mutedSage))
            Text("アイデアが見つかりません")
                .font(.headline)
            Spacer()
        }
    }

    private func ideaContent(_ idea: Idea) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ヘッダーカード
                ideaHeaderCard(idea)

                // 投票セクション
                votingSection

                // コメントセクション
                commentsSection

                // コメント入力
                commentInputSection
            }
            .padding()
        }
        .background(Color(AsaColors.softCream).opacity(0.3))
    }

    private func ideaHeaderCard(_ idea: Idea) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // ステータスとカテゴリ
            HStack {
                Text(idea.category.displayNameWithEmoji)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(AsaColors.softCream))
                    .cornerRadius(4)

                Spacer()

                Text(idea.status.displayNameWithEmoji)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: idea.status))
                    .cornerRadius(4)
            }

            // タイトル
            Text(idea.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(AsaColors.darkSlate))

            // 説明
            if !idea.ideaDescription.isEmpty {
                Text(idea.ideaDescription)
                    .font(.body)
                    .foregroundColor(Color(AsaColors.darkSlate))
            }

            Divider()

            // 投稿者情報
            HStack {
                Circle()
                    .fill(Color(AsaColors.coffeeBrown).opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(idea.authorName.prefix(1)))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(AsaColors.coffeeBrown))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(idea.authorName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(AsaColors.darkSlate))

                    Text(formattedDate(idea.createdAt))
                        .font(.caption)
                        .foregroundColor(Color(AsaColors.mutedSage))
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    private var votingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("投票")
                .font(.headline)
                .foregroundColor(Color(AsaColors.darkSlate))

            VotingView(
                voteSummary: viewModel.voteSummary,
                userVote: viewModel.userVote
            ) { voteType in
                Task {
                    await viewModel.vote(type: voteType)
                }
            }
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("コメント")
                    .font(.headline)
                    .foregroundColor(Color(AsaColors.darkSlate))

                Text("(\(viewModel.commentsCount))")
                    .font(.subheadline)
                    .foregroundColor(Color(AsaColors.mutedSage))
            }

            if viewModel.comments.isEmpty {
                Text("コメントはまだありません")
                    .font(.subheadline)
                    .foregroundColor(Color(AsaColors.mutedSage))
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.comments) { comment in
                    CommentRowView(comment: comment) {
                        Task {
                            await viewModel.deleteComment(id: comment.id)
                        }
                    }
                }
            }
        }
    }

    private var commentInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("コメントを追加")
                .font(.subheadline)
                .foregroundColor(Color(AsaColors.darkSlate))

            HStack(spacing: 8) {
                TextField("コメントを入力...", text: $newComment, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .lineLimit(1...4)

                Button {
                    Task {
                        await viewModel.addComment(content: newComment)
                        newComment = ""
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color(AsaColors.coffeeBrown))
                        .cornerRadius(12)
                }
                .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Private Methods

    private func setupViewModel() {
        let dataService = LocalDataService(modelContainer: modelContext.container)
        viewModel.setDataService(dataService)

        if let user = authViewModel.currentUser {
            viewModel.setCurrentUser(id: user.id, name: user.displayName)
        }
    }

    private func statusColor(for status: IdeaStatus) -> Color {
        switch status {
        case .proposed: return Color(AsaColors.mutedSage)
        case .discussing: return Color(AsaColors.coffeeBrown)
        case .approved: return Color.green.opacity(0.8)
        case .inProgress: return Color.orange
        case .completed: return Color.green
        case .archived: return Color.gray
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    IdeaDetailView(
        ideaId: UUID(),
        onUpdate: { _ in },
        onDelete: {}
    )
    .environmentObject(AuthViewModel())
}
