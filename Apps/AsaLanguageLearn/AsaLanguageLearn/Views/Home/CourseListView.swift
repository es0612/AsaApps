//
//  CourseListView.swift
//  AsaLanguageLearn
//
//  コース一覧画面
//

import AsaUIKit
import SwiftUI

struct CourseListView: View {
    let viewModel: LanguageLearnViewModel?

    @State private var selectedCategory: ContentCategory?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // カテゴリフィルター
                categoryFilter

                // コースリスト
                courseList
            }
            .padding()
        }
        .navigationTitle("コース")
        .navigationBarTitleDisplayMode(.large)
        .background(AsaColors.softCream.opacity(0.3))
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryChip(
                    title: "すべて",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(ContentCategory.allCases, id: \.rawValue) { category in
                    CategoryChip(
                        title: category.displayName,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }

    // MARK: - Course List

    private var courseList: some View {
        LazyVStack(spacing: 16) {
            if let courses = viewModel?.courses {
                let filteredCourses = selectedCategory == nil
                    ? courses
                    : courses.filter { $0.category == selectedCategory }

                ForEach(filteredCourses, id: \.id) { course in
                    NavigationLink {
                        LessonListView(course: course, viewModel: viewModel)
                    } label: {
                        CourseCardView(course: course)
                    }
                    .buttonStyle(.plain)
                }

                if filteredCourses.isEmpty {
                    emptyState
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("コースがありません")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline.bold())
            }
            .foregroundColor(isSelected ? .white : AsaColors.darkSlate)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? AsaColors.coffeeBrown
                    : Color.white
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Course Card View

struct CourseCardView: View {
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                // カテゴリアイコン
                ZStack {
                    Circle()
                        .fill(course.category.color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: course.category.icon)
                        .font(.title3)
                        .foregroundColor(course.category.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(course.title)
                        .font(.headline)
                        .foregroundColor(AsaColors.darkSlate)

                    Text(course.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if course.isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }

            // 情報バー
            HStack(spacing: 16) {
                // 難易度
                Label {
                    Text(course.difficultyStars)
                        .font(.caption2)
                } icon: {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                }
                .foregroundColor(.orange)

                // レッスン数
                Label {
                    Text("\(course.totalLessonsCount)レッスン")
                        .font(.caption)
                } icon: {
                    Image(systemName: "book.fill")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)

                // 所要時間
                Label {
                    Text("\(course.estimatedMinutes)分")
                        .font(.caption)
                } icon: {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)

                Spacer()
            }

            // 進捗バー
            if course.progressPercentage > 0 {
                VStack(spacing: 4) {
                    ProgressView(value: course.progressPercentage)
                        .tint(AsaColors.coffeeBrown)

                    HStack {
                        Text("\(course.completedLessonsCount)/\(course.totalLessonsCount) 完了")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(Int(course.progressPercentage * 100))%")
                            .font(.caption.bold())
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CourseListView(viewModel: nil)
    }
}
