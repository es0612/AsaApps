import SwiftUI
import AsaUIKit

// MARK: - EventDetailView

struct EventDetailView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EventDetailViewModel
    @State private var showCreatePost = false
    @State private var showInviteSheet = false
    @State private var showLeaveAlert = false

    // MARK: - Initialization

    init(event: Event, userId: String, dataService: any EventDataServiceProtocol) {
        _viewModel = State(initialValue: EventDetailViewModel(
            event: event,
            userId: userId,
            dataService: dataService
        ))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AsaColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // イベントヘッダー
                eventHeader

                // タブ選択
                tabPicker

                // コンテンツ
                TabView(selection: $viewModel.selectedTab) {
                    TimelineView(viewModel: viewModel)
                        .tag(EventDetailTab.timeline)

                    ParticipantListView(viewModel: viewModel)
                        .tag(EventDetailTab.participants)

                    ActivityFeedView(activities: viewModel.activities)
                        .tag(EventDetailTab.activity)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            // フローティング投稿ボタン
            if viewModel.selectedTab == .timeline {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingPostButton
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(viewModel.event.title)
                        .font(.headline)

                    if viewModel.event.status == .live {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.red)
                                .frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.caption2.bold())
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showInviteSheet = true
                    } label: {
                        Label("招待する", systemImage: "person.badge.plus")
                    }

                    if !viewModel.isHost {
                        Button(role: .destructive) {
                            showLeaveAlert = true
                        } label: {
                            Label("イベントを退出", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AsaColors.coffeeBrown)
                }
            }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView(viewModel: viewModel)
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteView(event: viewModel.event)
        }
        .alert("イベントを退出しますか？", isPresented: $showLeaveAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("退出", role: .destructive) {
                leaveEvent()
            }
        } message: {
            Text("タイムラインや参加履歴は削除されます。")
        }
        .onAppear {
            viewModel.startObserving()
        }
        .onDisappear {
            viewModel.stopObserving()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Subviews

    private var eventHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // カテゴリアイコン
                Image(systemName: viewModel.event.category.icon)
                    .font(.title)
                    .foregroundStyle(viewModel.event.status == .live ? .red : AsaColors.coffeeBrown)
                    .frame(width: 56, height: 56)
                    .background(viewModel.event.status == .live ? Color.red.opacity(0.1) : AsaColors.softCream)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.event.category.displayName)
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)

                    HStack(spacing: 8) {
                        Label {
                            Text(formatDate(viewModel.event.startDate))
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)

                        if let location = viewModel.event.location {
                            Label {
                                Text(location)
                            } icon: {
                                Image(systemName: "mappin")
                            }
                            .font(.caption)
                            .foregroundStyle(AsaColors.mutedSage)
                            .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // オンライン人数
                VStack(spacing: 2) {
                    Text("\(viewModel.onlineCount)")
                        .font(.title2.bold())
                        .foregroundStyle(AsaColors.coffeeBrown)
                    Text("オンライン")
                        .font(.caption2)
                        .foregroundStyle(AsaColors.mutedSage)
                }
            }
            .padding()
            .background(.white)
        }
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(EventDetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.rawValue)
                                .font(.subheadline)
                        }
                        .foregroundStyle(viewModel.selectedTab == tab ? AsaColors.coffeeBrown : AsaColors.mutedSage)
                        .fontWeight(viewModel.selectedTab == tab ? .semibold : .regular)

                        Rectangle()
                            .fill(viewModel.selectedTab == tab ? AsaColors.coffeeBrown : .clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(.white)
    }

    private var floatingPostButton: some View {
        Button {
            showCreatePost = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AsaColors.coffeeBrown)
                .clipShape(Circle())
                .shadow(color: AsaColors.coffeeBrown.opacity(0.3), radius: 8, y: 4)
        }
    }

    // MARK: - Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")

        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "今日 HH:mm"
        } else {
            formatter.dateFormat = "M/d HH:mm"
        }

        return formatter.string(from: date)
    }

    private func leaveEvent() {
        Task {
            do {
                try await viewModel.leaveEvent()
                dismiss()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EventDetailView(
            event: Event.sampleEvents[0],
            userId: "user-1",
            dataService: MockEventDataService()
        )
    }
}
