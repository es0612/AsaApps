import SwiftUI
import AsaUIKit
import AsaCommunityKit

/// 防災ダッシュボード画面
struct SafetyDashboardView: View {
    @Bindable var viewModel: SafetyViewModel
    @State private var showReportSheet = false
    @State private var showShelterMap = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Active Alerts
                    if viewModel.activeAlertCount > 0 {
                        alertBanner
                    }

                    // MARK: - Quick Actions
                    HStack(spacing: 12) {
                        quickActionButton(
                            title: "安全レポート",
                            iconName: "exclamationmark.triangle.fill",
                            color: .orange
                        ) {
                            showReportSheet = true
                        }
                        quickActionButton(
                            title: "避難所マップ",
                            iconName: "map.fill",
                            color: .blue
                        ) {
                            showShelterMap = true
                        }
                    }

                    // MARK: - Safety Reports
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("安全レポート")
                                .font(.headline)
                                .foregroundStyle(AsaColors.darkSlate)
                            Spacer()
                            Toggle("未解決のみ", isOn: $viewModel.showActiveOnly)
                                .labelsHidden()
                                .tint(AsaColors.coffeeBrown)
                        }

                        let reports = viewModel.showActiveOnly
                            ? viewModel.safetyReports.filter { !$0.isResolved }
                            : viewModel.safetyReports

                        if reports.isEmpty {
                            EmptyStateView(
                                iconName: "checkmark.shield",
                                title: "安全です",
                                message: "現在アクティブなレポートはありません"
                            )
                        } else {
                            ForEach(reports) { report in
                                SafetyReportRow(report: report) {
                                    viewModel.resolveReport(report)
                                }
                            }
                        }
                    }

                    // MARK: - Garbage Schedule
                    NavigationLink {
                        GarbageScheduleView(
                            viewModel: GarbageScheduleViewModel(
                                dataService: viewModel.dataService,
                                notificationService: viewModel.notificationService
                            )
                        )
                    } label: {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                            VStack(alignment: .leading) {
                                Text("ゴミ出しカレンダー")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("スケジュールとリマインダー")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("防災・安全")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showReportSheet = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showReportSheet) {
                SafetyReportSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showShelterMap) {
                NavigationStack {
                    ShelterMapView(shelters: viewModel.shelters)
                        .navigationTitle("避難所マップ")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("閉じる") { showShelterMap = false }
                            }
                        }
                }
            }
            .onAppear {
                viewModel.loadSafetyData()
            }
        }
    }

    private var alertBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text("\(viewModel.activeAlertCount)件のアクティブな警報があります")
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func quickActionButton(title: String, iconName: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AsaColors.darkSlate)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

/// 安全レポート行コンポーネント
struct SafetyReportRow: View {
    let report: SafetyReport
    let onResolve: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: report.alertLevel.iconName)
                .font(.title3)
                .foregroundStyle(report.isResolved ? Color.secondary : Color.red)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(report.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if report.isResolved {
                        Text("解決済み")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                Text(report.reportDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(report.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if !report.isResolved {
                Button("解決") {
                    onResolve()
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AsaColors.coffeeBrown)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
    }
}
