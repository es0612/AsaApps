//
//  LessonListView.swift
//  AsaLanguageLearn
//
//  レッスン一覧画面
//

import SwiftUI

struct LessonListView: View {
    let course: Course
    let viewModel: LanguageLearnViewModel?

    @Environment(\.modelContext) private var modelContext
    @State private var selectedLesson: Lesson?
    @State private var showingPractice = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // コース情報ヘッダー
                courseHeader

                // レッスンリスト
                lessonList
            }
            .padding()
        }
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color("AsaSoftCream").opacity(0.3))
        .fullScreenCover(isPresented: $showingPractice) {
            if let lesson = selectedLesson {
                PracticeView(
                    lesson: lesson,
                    speechRecognitionService: SpeechRecognitionService(),
                    textToSpeechService: TextToSpeechService(),
                    modelContext: modelContext
                )
            }
        }
    }

    // MARK: - Course Header

    private var courseHeader: some View {
        VStack(spacing: 16) {
            // カテゴリアイコン
            ZStack {
                Circle()
                    .fill(course.category.color.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: course.category.icon)
                    .font(.system(size: 36))
                    .foregroundColor(course.category.color)
            }

            Text(course.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // 進捗
            HStack(spacing: 20) {
                StatBadge(
                    title: "完了",
                    value: "\(course.completedLessonsCount)/\(course.totalLessonsCount)",
                    icon: "checkmark.circle.fill"
                )

                StatBadge(
                    title: "難易度",
                    value: course.difficultyStars,
                    icon: "star.fill"
                )

                StatBadge(
                    title: "所要時間",
                    value: "\(course.estimatedMinutes)分",
                    icon: "clock.fill"
                )
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Lesson List

    private var lessonList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("レッスン")
                .font(.headline)

            ForEach(course.lessons.sorted { $0.sortOrder < $1.sortOrder }, id: \.id) { lesson in
                LessonCardView(
                    lesson: lesson,
                    lessonNumber: lesson.sortOrder + 1
                ) {
                    selectedLesson = lesson
                    showingPractice = true
                }
            }
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color("AsaCoffeeBrown"))

            Text(value)
                .font(.caption.bold())
                .foregroundColor(Color("AsaDarkSlate"))

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Lesson Card View

struct LessonCardView: View {
    let lesson: Lesson
    let lessonNumber: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // レッスン番号
                ZStack {
                    Circle()
                        .fill(lesson.isCompleted ? Color.green : Color("AsaCoffeeBrown"))
                        .frame(width: 40, height: 40)

                    if lesson.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(lessonNumber)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.subheadline.bold())
                        .foregroundColor(Color("AsaDarkSlate"))

                    Text(lesson.lessonDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    // アイテム数と進捗
                    HStack(spacing: 12) {
                        Label("\(lesson.totalItemsCount)フレーズ", systemImage: "text.bubble")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        if lesson.isStarted && !lesson.isCompleted {
                            Label(
                                "\(lesson.completedItemsCount)/\(lesson.totalItemsCount)",
                                systemImage: "chart.bar.fill"
                            )
                            .font(.caption2)
                            .foregroundColor(Color("AsaCoffeeBrown"))
                        }

                        if lesson.itemsDueForReview.count > 0 {
                            Label(
                                "\(lesson.itemsDueForReview.count)復習",
                                systemImage: "arrow.clockwise"
                            )
                            .font(.caption2)
                            .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color("AsaCoffeeBrown"))
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.03), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LessonListView(course: .sampleGreetingsCourse, viewModel: nil)
    }
}
