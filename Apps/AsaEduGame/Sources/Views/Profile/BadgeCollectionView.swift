import SwiftUI
import AsaEduGameKit
import AsaUIKit

// MARK: - バッジコレクション画面

/// 全13バッジのグリッド表示
/// 解除済みはカラフル表示、未解除はグレーアウト
struct BadgeCollectionView: View {

    // MARK: - Properties

    @Bindable var viewModel: ProfileViewModel

    // MARK: - State

    @State private var selectedBadge: BadgeDefinition?
    @State private var showBadgeDetail: Bool = false

    // MARK: - Constants

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 進捗表示
                progressHeader

                // バッジグリッド
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(BadgeDefinition.allCases, id: \.rawValue) { badge in
                        badgeCell(badge: badge)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(AsaColors.softCream.opacity(0.3))
        .navigationTitle("バッジコレクション")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBadgeDetail) {
            if let badge = selectedBadge {
                badgeDetailSheet(badge: badge)
            }
        }
    }

    // MARK: - 進捗ヘッダー

    private var progressHeader: some View {
        AsaCard {
            VStack(spacing: 10) {
                Text("🏅 バッジしゅうしゅう")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AsaColors.darkSlate)

                // 解除済み数
                HStack(spacing: 4) {
                    Text("\(viewModel.unlockedBadges.count)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AsaColors.coffeeBrown)

                    Text("/ \(viewModel.allBadges.count)")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(AsaColors.mutedSage)
                }

                // プログレスバー
                ProgressView(
                    value: Double(viewModel.unlockedBadges.count),
                    total: Double(viewModel.allBadges.count)
                )
                .tint(AsaColors.coffeeBrown)
            }
        }
    }

    // MARK: - バッジセル

    private func badgeCell(badge: BadgeDefinition) -> some View {
        let isUnlocked = isBadgeUnlocked(badge)

        return Button {
            selectedBadge = badge
            showBadgeDetail = true
        } label: {
            VStack(spacing: 8) {
                // バッジ絵文字
                ZStack {
                    Circle()
                        .fill(isUnlocked
                              ? Color(badge.emoji == "⭐" ? "AsaCoffeeBrown" : badge.rawValue.hashValue % 2 == 0 ? "AsaMocha" : "AsaMutedSage").opacity(0.15)
                              : Color.gray.opacity(0.1))
                        .frame(width: 70, height: 70)

                    if isUnlocked {
                        Text(badge.emoji)
                            .font(.system(size: 36))
                    } else {
                        Text("???")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }

                // バッジ名
                Text(isUnlocked ? badge.title : "???")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(isUnlocked ? AsaColors.darkSlate : .gray.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isUnlocked ? badge.title : "まだかいほうされていないバッジ")
    }

    // MARK: - バッジ詳細シート

    private func badgeDetailSheet(badge: BadgeDefinition) -> some View {
        let isUnlocked = isBadgeUnlocked(badge)
        let achievement = findAchievement(for: badge)

        return VStack(spacing: 24) {
            // バッジ絵文字
            ZStack {
                Circle()
                    .fill(isUnlocked
                          ? AsaColors.coffeeBrown.opacity(0.1)
                          : Color.gray.opacity(0.1))
                    .frame(width: 120, height: 120)

                if isUnlocked {
                    Text(badge.emoji)
                        .font(.system(size: 64))
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.gray.opacity(0.4))
                        Text("???")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
            }
            .padding(.top, 32)

            // バッジ名
            Text(badge.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(isUnlocked ? AsaColors.darkSlate : .gray)

            // 説明
            Text(badge.badgeDescription)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(AsaColors.mutedSage)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // 解除日
            if isUnlocked, let unlockedAt = achievement?.unlockedAt {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(AsaColors.mutedSage)
                    Text(unlockedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AsaColors.mutedSage)
                }
            } else {
                // 解除条件ヒント
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.yellow)
                    Text("ヒント: \(badge.badgeDescription)")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AsaColors.mutedSage)
                }
            }

            Spacer()

            // 閉じるボタン
            Button {
                showBadgeDetail = false
            } label: {
                Text("とじる")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AsaColors.coffeeBrown)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(AsaColors.softCream)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 32)
        }
        .presentationDetents([.medium])
    }

    // MARK: - ヘルパー

    /// バッジが解除済みかチェック
    private func isBadgeUnlocked(_ badge: BadgeDefinition) -> Bool {
        viewModel.unlockedBadges.contains { $0.badgeId == badge.rawValue }
    }

    /// バッジに対応するアチーブメントを検索
    private func findAchievement(for badge: BadgeDefinition) -> Achievement? {
        viewModel.unlockedBadges.first { $0.badgeId == badge.rawValue }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BadgeCollectionView(
            viewModel: ProfileViewModel(dataService: EduGameDataService(inMemory: true))
        )
    }
}
