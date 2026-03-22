//
//  HomeView.swift
//  AsaLanguageLearn
//
//  ホーム画面
//

import AsaUIKit
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: LanguageLearnViewModel?
    @State private var selectedTab = 0
    @State private var showingPractice = false
    @State private var selectedLesson: Lesson?

    var body: some View {
        TabView(selection: $selectedTab) {
            // ホームタブ
            NavigationStack {
                homeContent
                    .navigationTitle("AsaLanguageLearn")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }
            .tag(0)

            // コースタブ
            NavigationStack {
                CourseListView(viewModel: viewModel)
            }
            .tabItem {
                Label("コース", systemImage: "book.fill")
            }
            .tag(1)

            // 復習タブ
            NavigationStack {
                if viewModel != nil {
                    ReviewDeckView(
                        viewModel: ReviewViewModel(modelContext: modelContext),
                        speechRecognitionService: SpeechRecognitionService(),
                        textToSpeechService: TextToSpeechService()
                    )
                }
            }
            .tabItem {
                Label("復習", systemImage: "arrow.clockwise")
            }
            .tag(2)

            // ダッシュボードタブ
            NavigationStack {
                DashboardView(viewModel: DashboardViewModel(modelContext: modelContext))
            }
            .tabItem {
                Label("統計", systemImage: "chart.bar.fill")
            }
            .tag(3)
        }
        .tint(AsaColors.coffeeBrown)
        .task {
            if viewModel == nil {
                viewModel = LanguageLearnViewModel(modelContext: modelContext)
                await viewModel?.loadInitialData()
            }
        }
    }

    @ViewBuilder
    private var homeContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ストリークカード
                streakCard

                // 今日の復習セクション
                if let vm = viewModel, vm.dueItemsCount > 0 {
                    reviewSection
                }

                // 最近のコースセクション
                recentCoursesSection

                // クイックスタートセクション
                quickStartSection
            }
            .padding()
        }
        .background(AsaColors.softCream.opacity(0.3))
        .refreshable {
            await viewModel?.refresh()
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 16) {
            // 炎アイコン
            ZStack {
                Circle()
                    .fill(AsaColors.coffeeBrown.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AsaColors.coffeeBrown)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel?.currentStreak ?? 0)日連続")
                    .font(.title2.bold())
                    .foregroundColor(AsaColors.darkSlate)

                Text(viewModel?.hasStudiedToday == true ? "今日も学習済み！" : "今日の学習を始めよう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if viewModel?.hasStudiedToday == true {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Review Section

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("復習待ち")
                    .font(.headline)

                Spacer()

                Text("\(viewModel?.dueItemsCount ?? 0)個")
                    .font(.subheadline.bold())
                    .foregroundColor(AsaColors.coffeeBrown)
            }

            Button {
                selectedTab = 2
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("復習を始める")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .padding()
                .background(AsaColors.coffeeBrown)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Recent Courses Section

    private var recentCoursesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("コース")
                    .font(.headline)

                Spacer()

                Button("すべて見る") {
                    selectedTab = 1
                }
                .font(.subheadline)
                .foregroundColor(AsaColors.coffeeBrown)
            }

            if let courses = viewModel?.courses.prefix(3) {
                ForEach(Array(courses), id: \.id) { course in
                    NavigationLink {
                        LessonListView(course: course, viewModel: viewModel)
                    } label: {
                        CourseRowView(course: course)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Quick Start Section

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("クイックスタート")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                QuickStartButton(
                    title: "挨拶",
                    icon: "hand.wave.fill",
                    color: AsaColors.coffeeBrown
                ) {
                    if let course = viewModel?.courses.first {
                        viewModel?.selectCourse(course)
                        selectedTab = 1
                    }
                }

                QuickStartButton(
                    title: "復習",
                    icon: "arrow.clockwise",
                    color: AsaColors.mocha
                ) {
                    selectedTab = 2
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

// MARK: - Course Row View

struct CourseRowView: View {
    let course: Course

    var body: some View {
        HStack(spacing: 12) {
            // カテゴリアイコン
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(course.category.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: course.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(course.category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.subheadline.bold())
                    .foregroundColor(AsaColors.darkSlate)

                HStack(spacing: 8) {
                    Text(course.difficultyStars)
                        .font(.caption2)
                        .foregroundColor(.orange)

                    Text("\(course.totalLessonsCount)レッスン")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 進捗
            if course.progressPercentage > 0 {
                CircularProgressView(progress: course.progressPercentage)
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Quick Start Button

struct QuickStartButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(AsaColors.darkSlate)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(AsaColors.coffeeBrown, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(AsaColors.coffeeBrown)
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .modelContainer(for: [Course.self, Lesson.self, LearningItem.self, LearningProgress.self, UserProfile.self, StudySession.self])
}
