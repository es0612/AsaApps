//
//  CommentRowView.swift
//  AsaCrowdsource
//
//  コメント行表示
//

import SwiftUI
import AsaUIKit

struct CommentRowView: View {
    // MARK: - Properties

    let comment: Comment
    let onDelete: () -> Void

    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showDeleteAlert = false

    // MARK: - Computed Properties

    private var canDelete: Bool {
        authViewModel.currentUser?.id == comment.authorId
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ヘッダー（投稿者・日時）
            HStack {
                // アバター
                Circle()
                    .fill(Color(AsaColors.coffeeBrown).opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(comment.authorName.prefix(1)))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color(AsaColors.coffeeBrown))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.authorName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(AsaColors.darkSlate))

                    HStack(spacing: 4) {
                        Text(formattedDate)
                            .font(.caption2)
                            .foregroundColor(Color(AsaColors.mutedSage))

                        if comment.isEdited {
                            Text("(編集済み)")
                                .font(.caption2)
                                .foregroundColor(Color(AsaColors.mutedSage))
                        }
                    }
                }

                Spacer()

                // 削除メニュー
                if canDelete {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Color(AsaColors.mutedSage))
                            .padding(8)
                    }
                }
            }

            // コメント本文
            Text(comment.content)
                .font(.body)
                .foregroundColor(Color(AsaColors.darkSlate))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .alert("コメントを削除", isPresented: $showDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("このコメントを削除しますか？")
        }
    }

    // MARK: - Private Properties

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: comment.createdAt, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        ForEach(Comment.sampleComments(for: UUID())) { comment in
            CommentRowView(comment: comment) {}
        }
    }
    .padding()
    .background(Color(AsaColors.softCream).opacity(0.3))
    .environmentObject(AuthViewModel())
}
