import SwiftUI
import AsaUIKit
import AsaCommunityKit

/// ホーム（ダッシュボード）画面
struct CommunityHomeView: View {
    @Bindable var viewModel: CommunityHomeViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - 安全アラート
                    if !viewModel.activeAlerts.isEmpty {
                        alertSection
                    }

                    // MARK: - 今日のゴミ出し
                    garbageSection

                    // MARK: - 統計カード
                    statsSection

                    // MARK: - 近日イベント
                    upcomingEventsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ホーム")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ProfileSettingsView(
                            viewModel: ProfileSettingsViewModel(
                                dataService: viewModel.dataService,
                                notificationService: NotificationService()
                            )
                        )
                    } label: {
                        Image(systemName: "person.circle")
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }
                }
            }
            .refreshable {
                viewModel.loadDashboard()
            }
            .onAppear {
                viewModel.loadDashboard()
            }
        }
    }

    // MARK: - Alert Section

    private var alertSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.activeAlerts) { alert in
                HStack(spacing: 12) {
                    Image(systemName: alert.alertLevel.iconName)
                        .foregroundStyle(.red)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(alert.reportDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Garbage Section

    private var garbageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日のゴミ出し")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            if viewModel.todaysGarbage.isEmpty {
                Text("今日の収集はありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                HStack(spacing: 12) {
                    ForEach(viewModel.todaysGarbage) { schedule in
                        VStack(spacing: 4) {
                            Image(systemName: schedule.garbageType.iconName)
                                .font(.title2)
                            Text(schedule.garbageType.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "未読投稿",
                value: "\(viewModel.unreadPostCount)",
                iconName: "envelope.badge"
            )
            StatCard(
                title: "今週のイベント",
                value: "\(viewModel.upcomingEvents.count)",
                iconName: "calendar.badge.clock",
                iconColor: .orange
            )
        }
    }

    // MARK: - Upcoming Events Section

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("近日のイベント")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)

            if viewModel.upcomingEvents.isEmpty {
                Text("予定されているイベントはありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ForEach(viewModel.upcomingEvents) { event in
                    HStack(spacing: 12) {
                        VStack {
                            Text(event.startDate.formatted(.dateTime.month(.abbreviated)))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(event.startDate.formatted(.dateTime.day()))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(AsaColors.coffeeBrown)
                        }
                        .frame(width: 50)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(event.location)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(event.attendeeCount)人")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}
