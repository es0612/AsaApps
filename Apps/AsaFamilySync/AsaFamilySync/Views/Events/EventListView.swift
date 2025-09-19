import SwiftUI
import AsaUIKit

struct EventListView: View {
    @State private var selectedCategory: EventCategory? = nil
    @State private var showAddEvent = false

    let categories = EventCategory.allCases

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // カテゴリフィルター
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryChip(
                                title: "すべて",
                                icon: "square.grid.2x2",
                                color: AsaColors.darkSlate,
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )

                            ForEach(categories, id: \.self) { category in
                                CategoryChip(
                                    title: category.displayName,
                                    icon: category.icon,
                                    color: category.color,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    // 今後の予定セクション
                    VStack(alignment: .leading, spacing: 16) {
                        Text("今後の予定")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        // プレースホルダーイベント
                        EventCard(
                            title: "家族旅行",
                            category: .leisure,
                            startTime: Date().addingTimeInterval(86400 * 3),
                            assignedMembers: ["太郎", "花子"]
                        )
                        .padding(.horizontal)

                        EventCard(
                            title: "学校の面談",
                            category: .school,
                            startTime: Date().addingTimeInterval(86400 * 7),
                            assignedMembers: ["太郎"]
                        )
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            .navigationTitle("予定")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddEvent = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(AsaColors.coffeeBrown)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventView()
        }
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.15))
            )
            .foregroundColor(isSelected ? .white : color)
        }
    }
}

struct EventCard: View {
    let title: String
    let category: EventCategory
    let startTime: Date
    let assignedMembers: [String]

    var body: some View {
        AsaCard {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(category.color)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: category.icon)
                            .font(.caption)
                            .foregroundColor(category.color)
                        Text(title)
                            .font(.body)
                            .fontWeight(.medium)
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(startTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !assignedMembers.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(assignedMembers.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}