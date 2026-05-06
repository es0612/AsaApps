import SwiftUI
import AsaEduGameKit
import AsaUIKit

// MARK: - ホーム画面

/// ゲームモード選択画面
/// 上部にユーザー情報、中央に4つのゲームモードカードを表示
struct HomeView: View {

    // MARK: - Properties

    @Bindable var viewModel: HomeViewModel

    /// サービスDI（ゲーム画面に渡す）
    let dataService: EduGameDataServiceProtocol
    let questionGenerator: QuestionGenerating
    let scoringService: GameScoring
    let difficultyService: DifficultyAdjusting

    // MARK: - State

    @State private var selectedMode: GameMode?
    @State private var showDifficultySheet: Bool = false
    @State private var navigateToGame: Bool = false
    @State private var selectedDifficulty: DifficultyLevel = .easy

    // MARK: - Constants

    /// 2列グリッドレイアウト
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ユーザー情報ヘッダー
                    userHeaderSection

                    // ゲームモード選択グリッド
                    gameModeGridSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(AsaColors.softCream.opacity(0.3))
            .navigationTitle("AsaEduGame")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadProfile()
            }
            .sheet(isPresented: $showDifficultySheet) {
                difficultySelectionSheet
            }
            .navigationDestination(isPresented: $navigateToGame) {
                if let mode = selectedMode, let profile = viewModel.profile {
                    GameContainerView(
                        gameMode: mode,
                        difficulty: selectedDifficulty,
                        profile: profile,
                        dataService: dataService,
                        questionGenerator: questionGenerator,
                        scoringService: scoringService,
                        difficultyService: difficultyService
                    )
                }
            }
        }
    }

    // MARK: - ユーザー情報ヘッダー

    private var userHeaderSection: some View {
        HStack(spacing: 16) {
            // アバター
            Text(viewModel.profile?.avatarEmoji ?? "🐱")
                .font(.system(size: 50))

            VStack(alignment: .leading, spacing: 4) {
                // 名前
                Text(viewModel.profile?.name.isEmpty == false
                     ? viewModel.profile!.name
                     : "おなまえをいれてね")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AsaColors.darkSlate)

                // レベル
                HStack(spacing: 4) {
                    Text("Lv.\(viewModel.profile?.currentLevel ?? 1)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AsaColors.coffeeBrown)

                    Text(viewModel.profile?.levelDisplayName ?? "ビギナー")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AsaColors.mutedSage)
                }

                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundColor(AsaColors.coffeeBrown)
                        .font(.system(size: 14))
                    Text("\(viewModel.profile?.totalStars ?? 0)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AsaColors.darkSlate)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - ゲームモードグリッド

    private var gameModeGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("あそぶモードをえらんでね！")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AsaColors.darkSlate)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    gameModeCard(mode: mode)
                }
            }
        }
    }

    /// ゲームモードカード
    private func gameModeCard(mode: GameMode) -> some View {
        Button {
            selectedMode = mode
            showDifficultySheet = true
        } label: {
            AsaCard {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(mode.themeColor.opacity(0.15))
                            .frame(width: 72, height: 72)
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(mode.themeColor)
                    }

                    Text(mode.displayName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(mode.themeColor)

                    Text(mode.modeDescription)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(AsaColors.mutedSage)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.displayName)モード")
        .accessibilityHint(mode.modeDescription)
    }

    /// 難易度に応じた SF Symbol アイコン名（数字円で1/2/3を可視化）
    private func difficultyIcon(for difficulty: DifficultyLevel) -> String {
        switch difficulty.starCount {
        case 1: return "1.circle.fill"
        case 2: return "2.circle.fill"
        default: return "3.circle.fill"
        }
    }

    // MARK: - 難易度選択シート

    private var difficultySelectionSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let mode = selectedMode {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(mode.themeColor.opacity(0.15))
                                .frame(width: 96, height: 96)
                            Image(systemName: mode.systemImage)
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundColor(mode.themeColor)
                        }
                        Text(mode.displayName)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(mode.themeColor)
                    }
                    .padding(.top, 16)

                    VStack(spacing: 16) {
                        Text("むずかしさをえらんでね")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(AsaColors.darkSlate)

                        ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                            ChildFriendlyButton(
                                title: difficulty.displayName,
                                color: mode.themeColor,
                                icon: difficultyIcon(for: difficulty)
                            ) {
                                selectedDifficulty = difficulty
                                showDifficultySheet = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    navigateToGame = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
            .navigationTitle("むずかしさ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("もどる") {
                        showDifficultySheet = false
                    }
                    .font(.system(size: 16, design: .rounded))
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    HomeView(
        viewModel: HomeViewModel(dataService: EduGameDataService(inMemory: true)),
        dataService: EduGameDataService(inMemory: true),
        questionGenerator: QuestionGeneratorService(),
        scoringService: ScoringService(),
        difficultyService: AdaptiveDifficultyService()
    )
}
