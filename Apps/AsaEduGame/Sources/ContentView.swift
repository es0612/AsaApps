import SwiftUI
import SwiftData
import AsaEduGameKit
import AsaUIKit

// MARK: - メインコンテンツビュー

/// TabViewベースのメイン画面
/// 3タブ: ホーム, しんちょく, プロフィール
struct ContentView: View {

    // MARK: - Services

    private let dataService: EduGameDataServiceProtocol
    private let questionGenerator: QuestionGenerating
    private let scoringService: GameScoring
    private let difficultyService: DifficultyAdjusting

    // MARK: - ViewModels

    @State private var homeVM: HomeViewModel
    @State private var progressVM: ProgressViewModel
    @State private var profileVM: ProfileViewModel

    // MARK: - State

    @State private var selectedTab: Int = 0

    // MARK: - Init

    init() {
        let dataService = EduGameDataService()
        let questionGenerator = QuestionGeneratorService()
        let scoringService = ScoringService()
        let difficultyService = AdaptiveDifficultyService()

        // 初回起動時にデモ用サンプルデータを投入
        Self.loadSampleDataIfNeeded(modelContainer: dataService.modelContainer)

        self.dataService = dataService
        self.questionGenerator = questionGenerator
        self.scoringService = scoringService
        self.difficultyService = difficultyService

        self._homeVM = State(initialValue: HomeViewModel(dataService: dataService))
        self._progressVM = State(initialValue: ProgressViewModel(dataService: dataService))
        self._profileVM = State(initialValue: ProfileViewModel(dataService: dataService))
    }

    /// 初回起動時にサンプルデータを投入
    /// - プロフィール（はなちゃん 6歳）+ 14件のゲーム履歴 + 5つの実績バッジ
    private static func loadSampleDataIfNeeded(modelContainer: ModelContainer) {
        let key = "AsaEduGame_SampleDataLoaded_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let sampleService = SampleDataService(modelContainer: modelContainer)
        do {
            try sampleService.loadSampleData()
            UserDefaults.standard.set(true, forKey: key)
        } catch {
            print("サンプルデータ投入エラー: \(error.localizedDescription)")
        }
    }

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // ホームタブ
            HomeView(
                viewModel: homeVM,
                dataService: dataService,
                questionGenerator: questionGenerator,
                scoringService: scoringService,
                difficultyService: difficultyService
            )
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }
            .tag(0)

            // しんちょくタブ
            ProgressDashboardView(viewModel: progressVM)
                .tabItem {
                    Label("しんちょく", systemImage: "chart.bar.fill")
                }
                .tag(1)

            // プロフィールタブ
            ProfileView(viewModel: profileVM)
                .tabItem {
                    Label("プロフィール", systemImage: "person.fill")
                }
                .tag(2)
        }
        .tint(AsaColors.coffeeBrown)
        .modelContainer(dataService.modelContainer)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
