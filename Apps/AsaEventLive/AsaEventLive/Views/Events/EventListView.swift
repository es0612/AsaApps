import SwiftUI
import AsaUIKit

// MARK: - EventListView

struct EventListView: View {
    // MARK: - Properties

    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel: EventListViewModel
    @State private var showCreateSheet = false
    @State private var showJoinSheet = false
    @State private var selectedEvent: Event?
    @State private var showSettingsSheet = false

    let user: AppUser

    // MARK: - Initialization

    init(user: AppUser) {
        self.user = user
        _viewModel = State(initialValue: EventListViewModel(
            dataService: MockEventDataService(),
            userId: user.id
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.background
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.events.isEmpty {
                    loadingView
                } else if viewModel.events.isEmpty {
                    emptyStateView
                } else {
                    eventsList
                }
            }
            .navigationTitle("イベント")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettingsSheet = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title2)
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showCreateSheet = true
                        } label: {
                            Label("イベントを作成", systemImage: "plus.circle")
                        }

                        Button {
                            showJoinSheet = true
                        } label: {
                            Label("招待コードで参加", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateEventView(viewModel: viewModel)
            }
            .sheet(isPresented: $showJoinSheet) {
                JoinEventView(viewModel: viewModel, userName: user.displayName)
            }
            .sheet(isPresented: $showSettingsSheet) {
                settingsSheet
            }
            .navigationDestination(item: $selectedEvent) { event in
                EventDetailView(event: event, userId: user.id, dataService: authViewModel.dataService)
            }
            .onAppear {
                viewModel = EventListViewModel(
                    dataService: authViewModel.dataService,
                    userId: user.id
                )
                viewModel.startObserving()
            }
            .onDisappear {
                viewModel.stopObserving()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AsaColors.coffeeBrown)

            Text("読み込み中...")
                .font(.subheadline)
                .foregroundStyle(AsaColors.mutedSage)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(AsaColors.coffeeBrown.opacity(0.5))

            VStack(spacing: 8) {
                Text("イベントがありません")
                    .font(.headline)
                    .foregroundStyle(AsaColors.darkSlate)

                Text("新しいイベントを作成するか、\n招待コードで参加しましょう")
                    .font(.subheadline)
                    .foregroundStyle(AsaColors.mutedSage)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                AsaButton(title: "作成", action: {
                    showCreateSheet = true
                })
                .frame(width: 120)

                AsaButton(title: "参加", action: {
                    showJoinSheet = true
                }, color: AsaColors.mutedSage)
                .frame(width: 120)
            }
        }
        .padding()
    }

    private var eventsList: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                // ライブ中のイベント
                if !viewModel.liveEvents.isEmpty {
                    Section {
                        ForEach(viewModel.liveEvents) { event in
                            EventCard(event: event, isLive: true) {
                                selectedEvent = event
                            }
                        }
                    } header: {
                        sectionHeader(title: "ライブ中", icon: "antenna.radiowaves.left.and.right", color: .red)
                    }
                }

                // 予定のイベント
                if !viewModel.upcomingEvents.isEmpty {
                    Section {
                        ForEach(viewModel.upcomingEvents) { event in
                            EventCard(event: event, isLive: false) {
                                selectedEvent = event
                            }
                        }
                    } header: {
                        sectionHeader(title: "予定", icon: "calendar", color: AsaColors.coffeeBrown)
                    }
                }

                // 過去のイベント
                if !viewModel.pastEvents.isEmpty {
                    Section {
                        ForEach(viewModel.pastEvents) { event in
                            EventCard(event: event, isLive: false) {
                                selectedEvent = event
                            }
                        }
                    } header: {
                        sectionHeader(title: "過去のイベント", icon: "clock.arrow.circlepath", color: AsaColors.mutedSage)
                    }
                }
            }
            .padding()
        }
    }

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(AsaColors.background)
    }

    private var settingsSheet: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(AsaColors.coffeeBrown)
                            .frame(width: 50, height: 50)
                            .overlay {
                                Text(user.displayName.prefix(1))
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName)
                                .font(.headline)
                            if let email = user.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button(role: .destructive) {
                        authViewModel.signOut()
                        showSettingsSheet = false
                    } label: {
                        Label("サインアウト", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        showSettingsSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - EventCard

struct EventCard: View {
    let event: Event
    let isLive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // ヘッダー
                HStack {
                    // カテゴリアイコン
                    Image(systemName: event.category.icon)
                        .font(.title2)
                        .foregroundStyle(isLive ? .red : AsaColors.coffeeBrown)
                        .frame(width: 44, height: 44)
                        .background(isLive ? Color.red.opacity(0.1) : AsaColors.softCream)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(event.title)
                                .font(.headline)
                                .foregroundStyle(AsaColors.darkSlate)

                            if isLive {
                                Text("LIVE")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.red)
                                    .clipShape(Capsule())
                            }
                        }

                        Text(event.category.displayName)
                            .font(.caption)
                            .foregroundStyle(AsaColors.mutedSage)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)
                }

                // 詳細情報
                HStack(spacing: 16) {
                    Label {
                        Text(formatDate(event.startDate))
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)

                    if let location = event.location {
                        Label {
                            Text(location)
                        } icon: {
                            Image(systemName: "mappin")
                        }
                        .font(.caption)
                        .foregroundStyle(AsaColors.mutedSage)
                        .lineLimit(1)
                    }

                    Spacer()

                    Label {
                        Text("\(event.participantCount)")
                    } icon: {
                        Image(systemName: "person.2")
                    }
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
                }
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: isLive ? Color.red.opacity(0.2) : Color.black.opacity(0.05), radius: isLive ? 8 : 4)
            .overlay {
                if isLive {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")

        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "今日 HH:mm"
        } else if Calendar.current.isDateInTomorrow(date) {
            formatter.dateFormat = "明日 HH:mm"
        } else {
            formatter.dateFormat = "M/d HH:mm"
        }

        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    let dataService = MockEventDataService()
    let authViewModel = AuthViewModel(dataService: dataService)

    return EventListView(user: AppUser.demo)
        .environment(authViewModel)
}
