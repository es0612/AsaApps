import SwiftUI
import AsaEduGameKit
import AsaUIKit

// MARK: - プロフィール画面

/// ユーザーのプロフィール情報、レベル進捗、バッジコレクションを表示
struct ProfileView: View {

    // MARK: - Properties

    @Bindable var viewModel: ProfileViewModel

    // MARK: - State

    @State private var showBadgeCollection: Bool = false

    /// 利用可能なアバター絵文字
    private let avatarEmojis = [
        "🐱", "🐶", "🐰", "🐻", "🐼",
        "🦊", "🐸", "🐧", "🦁", "🐯",
        "🐮", "🐷", "🐵", "🦄", "🐲"
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // アバターセクション
                    avatarSection

                    // レベル進捗セクション
                    levelProgressSection

                    // プロフィール情報
                    profileInfoSection

                    // バッジコレクションリンク
                    badgeCollectionLink

                    // 統計サマリー
                    statsSummarySection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(AsaColors.softCream.opacity(0.3))
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if viewModel.isEditing {
                            viewModel.saveProfile()
                        } else {
                            viewModel.startEditing()
                        }
                    } label: {
                        Text(viewModel.isEditing ? "ほぞん" : "へんしゅう")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }

                if viewModel.isEditing {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            viewModel.cancelEditing()
                        } label: {
                            Text("キャンセル")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(AsaColors.mutedSage)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.loadProfile()
            }
            .navigationDestination(isPresented: $showBadgeCollection) {
                BadgeCollectionView(viewModel: viewModel)
            }
        }
    }

    // MARK: - アバターセクション

    private var avatarSection: some View {
        VStack(spacing: 12) {
            if viewModel.isEditing {
                // 編集モード: アバター選択
                VStack(spacing: 8) {
                    Text(viewModel.editEmoji)
                        .font(.system(size: 80))

                    // アバター選択グリッド
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                        ForEach(avatarEmojis, id: \.self) { emoji in
                            Button {
                                viewModel.editEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 32))
                                    .padding(4)
                                    .background(
                                        viewModel.editEmoji == emoji
                                            ? AsaColors.coffeeBrown.opacity(0.2)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
            } else {
                // 通常モード: 大きなアバター表示
                Text(viewModel.profile?.avatarEmoji ?? "🐱")
                    .font(.system(size: 80))
            }
        }
        .padding(.top, 16)
    }

    // MARK: - レベル進捗セクション

    private var levelProgressSection: some View {
        AsaCard {
            VStack(spacing: 12) {
                LevelBadgeView(
                    level: viewModel.profile?.currentLevel ?? 1,
                    levelName: viewModel.profile?.levelDisplayName ?? "ビギナー",
                    starsToNextLevel: viewModel.profile?.starsToNextLevel ?? 50,
                    totalStars: viewModel.profile?.totalStars ?? 0
                )
            }
        }
    }

    // MARK: - プロフィール情報セクション

    private var profileInfoSection: some View {
        AsaCard {
            VStack(spacing: 16) {
                if viewModel.isEditing {
                    // 編集モード
                    VStack(alignment: .leading, spacing: 12) {
                        // 名前入力
                        VStack(alignment: .leading, spacing: 4) {
                            Text("なまえ")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AsaColors.mutedSage)

                            TextField("おなまえをいれてね", text: $viewModel.editName)
                                .font(.system(size: 18, design: .rounded))
                                .padding(12)
                                .background(AsaColors.softCream.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // 年齢入力
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ねんれい")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AsaColors.mutedSage)

                            Stepper(
                                value: $viewModel.editAge,
                                in: 3...12
                            ) {
                                Text("\(viewModel.editAge)さい")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(AsaColors.darkSlate)
                            }
                            .padding(8)
                            .background(AsaColors.softCream.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                } else {
                    // 通常モード
                    VStack(spacing: 12) {
                        profileRow(
                            label: "なまえ",
                            value: viewModel.profile?.name.isEmpty == false
                                ? viewModel.profile!.name
                                : "せっていしてね"
                        )

                        Divider()

                        profileRow(
                            label: "ねんれい",
                            value: "\(viewModel.profile?.age ?? 5)さい"
                        )

                        Divider()

                        profileRow(
                            label: "かくとくほし",
                            value: "\(viewModel.profile?.totalStars ?? 0)こ ⭐"
                        )
                    }
                }
            }
        }
    }

    /// プロフィール行
    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AsaColors.mutedSage)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AsaColors.darkSlate)
        }
    }

    // MARK: - バッジコレクションリンク

    private var badgeCollectionLink: some View {
        Button {
            showBadgeCollection = true
        } label: {
            AsaCard {
                HStack(spacing: 12) {
                    Text("🏅")
                        .font(.system(size: 28))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("バッジコレクション")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(AsaColors.darkSlate)

                        Text("\(viewModel.unlockedBadges.count)/\(viewModel.allBadges.count) かいほうずみ")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(AsaColors.mutedSage)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(AsaColors.mutedSage)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 統計サマリーセクション

    private var statsSummarySection: some View {
        AsaCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("がくしゅうきろく")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AsaColors.darkSlate)

                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(viewModel.profile?.sessions.count ?? 0)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AsaColors.coffeeBrown)
                        Text("そうプレイ")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(AsaColors.mutedSage)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text("\(viewModel.unlockedBadges.count)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        Text("バッジ")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(AsaColors.mutedSage)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 4) {
                        Text("Lv.\(viewModel.profile?.currentLevel ?? 1)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        Text("レベル")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(AsaColors.mutedSage)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView(
        viewModel: ProfileViewModel(dataService: EduGameDataService(inMemory: true))
    )
}
