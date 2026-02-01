//
//  DiaryDetailView.swift
//  AsaVRDiary
//
//  日記詳細画面
//

import SwiftUI

/// 日記詳細画面
struct DiaryDetailView: View {
    let entry: DiaryEntry
    @Bindable var viewModel: DiaryViewModel
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ヘッダー
                DiaryDetailHeader(entry: entry)

                // タイトル
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.title)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(entry.formattedCreatedAt)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 本文
                Text(entry.content)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )

                // VR情報（設定されている場合）
                if entry.hasCustomVRPosition {
                    vrPositionInfo
                }
            }
            .padding()
        }
        .navigationTitle("日記詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }

                    Button {
                        viewModel.toggleFavorite(entry)
                    } label: {
                        Label(
                            entry.isFavorite ? "お気に入りを解除" : "お気に入りに追加",
                            systemImage: entry.isFavorite ? "star.slash" : "star"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditDiaryView(entry: entry, viewModel: viewModel)
        }
        .alert("日記を削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                viewModel.deleteEntry(entry)
                dismiss()
            }
        } message: {
            Text("「\(entry.title)」を削除しますか？この操作は取り消せません。")
        }
    }

    // MARK: - Subviews

    /// VR位置情報
    private var vrPositionInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("VR空間での配置", systemImage: "cube.transparent")
                .font(.headline)

            HStack(spacing: 16) {
                VStack {
                    Text("X")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", entry.vrPositionX ?? 0))
                        .font(.subheadline)
                        .fontDesign(.monospaced)
                }

                VStack {
                    Text("Y")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", entry.vrPositionY ?? 0))
                        .font(.subheadline)
                        .fontDesign(.monospaced)
                }

                VStack {
                    Text("Z")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f", entry.vrPositionZ ?? 0))
                        .font(.subheadline)
                        .fontDesign(.monospaced)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    NavigationStack {
        DiaryDetailView(
            entry: DiaryEntry(
                title: "素晴らしい一日",
                content: """
                今日は家族と公園に行った。

                子供たちが楽しそうに遊んでいて、とても嬉しかった。
                天気も良くて、ピクニック日和だった。

                こういう日常の幸せを大切にしたい。
                """,
                category: .family,
                mood: .veryHappy,
                moodIntensity: 5,
                isFavorite: true
            ),
            viewModel: DiaryViewModel()
        )
    }
}
