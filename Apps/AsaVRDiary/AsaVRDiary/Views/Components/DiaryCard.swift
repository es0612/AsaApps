//
//  DiaryCard.swift
//  AsaVRDiary
//
//  日記カードコンポーネント（2D表示用）
//

import SwiftUI

/// 日記カード（一覧表示用）
struct DiaryCard: View {
    let entry: DiaryEntry
    var onTap: (() -> Void)?
    var onFavoriteToggle: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                HStack {
                    // 日付
                    Text(entry.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // カテゴリ
                    CategoryBadge(category: entry.category, showLabel: false)

                    // 気分
                    Text(entry.mood.emoji)
                        .font(.title3)
                }

                // タイトル
                Text(entry.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // 本文プレビュー
                Text(entry.contentPreview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // フッター
                HStack {
                    // 気分ラベル
                    Text(entry.mood.displayName)
                        .font(.caption)
                        .foregroundStyle(entry.mood.color)

                    // 強度インジケーター
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { level in
                            Circle()
                                .fill(level <= entry.moodIntensity ? entry.mood.color : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }

                    Spacer()

                    // お気に入りボタン
                    Button {
                        onFavoriteToggle?()
                    } label: {
                        Image(systemName: entry.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(entry.isFavorite ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: entry.mood.color.opacity(0.2), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(entry.mood.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// 日記カード（コンパクト版）
struct DiaryCardCompact: View {
    let entry: DiaryEntry
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // 気分絵文字
                Text(entry.mood.emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(entry.mood.color.opacity(0.15))
                    .clipShape(Circle())

                // コンテンツ
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(entry.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        CategoryBadge(category: entry.category, showIcon: false)
                    }
                }

                Spacer()

                // お気に入りマーク
                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

/// 日記詳細ヘッダー
struct DiaryDetailHeader: View {
    let entry: DiaryEntry

    var body: some View {
        VStack(spacing: 16) {
            // 気分
            VStack(spacing: 8) {
                Text(entry.mood.emoji)
                    .font(.system(size: 60))

                Text(entry.mood.displayName)
                    .font(.headline)
                    .foregroundStyle(entry.mood.color)

                // 強度
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { level in
                        Circle()
                            .fill(level <= entry.moodIntensity ? entry.mood.color : Color.gray.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(entry.mood.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // メタ情報
            HStack(spacing: 16) {
                Label(entry.formattedDate, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                CategoryBadge(category: entry.category)

                if entry.isFavorite {
                    Label("お気に入り", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            DiaryCard(
                entry: DiaryEntry(
                    title: "素晴らしい一日",
                    content: "今日は家族と公園に行った。子供たちが楽しそうで、とても嬉しかった。",
                    category: .family,
                    mood: .veryHappy,
                    moodIntensity: 5,
                    isFavorite: true
                )
            )

            DiaryCardCompact(
                entry: DiaryEntry(
                    title: "プロジェクト完成",
                    content: "ついにMVPが完成した！",
                    category: .work,
                    mood: .excited,
                    moodIntensity: 4
                )
            )

            DiaryDetailHeader(
                entry: DiaryEntry(
                    title: "感謝の気持ち",
                    content: "周りの人に感謝",
                    category: .special,
                    mood: .grateful,
                    moodIntensity: 5,
                    isFavorite: true
                )
            )
        }
        .padding()
    }
}
