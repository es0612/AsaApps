import SwiftUI
import AsaUIKit

// MARK: - ParticipantListView

struct ParticipantListView: View {
    // MARK: - Properties

    @Bindable var viewModel: EventDetailViewModel

    // MARK: - Computed Properties

    private var hosts: [Participant] {
        viewModel.participants.filter { $0.role == .host }
    }

    private var coHosts: [Participant] {
        viewModel.participants.filter { $0.role == .coHost }
    }

    private var regularParticipants: [Participant] {
        viewModel.participants.filter { $0.role == .participant }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if viewModel.participants.isEmpty {
                emptyStateView
            } else {
                participantsList
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundStyle(AsaColors.coffeeBrown.opacity(0.3))

            Text("参加者情報を読み込み中...")
                .font(.headline)
                .foregroundStyle(AsaColors.darkSlate)
        }
    }

    private var participantsList: some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                // サマリー
                summaryCard

                // ホスト
                if !hosts.isEmpty {
                    Section {
                        ForEach(hosts) { participant in
                            ParticipantRow(
                                participant: participant,
                                isCurrentUser: participant.userId == viewModel.event.hostId,
                                canManage: viewModel.canManage
                            ) { newRole in
                                updateRole(participant: participant, to: newRole)
                            }
                        }
                    } header: {
                        sectionHeader(title: "ホスト", icon: "crown.fill", color: .orange)
                    }
                }

                // 共同ホスト
                if !coHosts.isEmpty {
                    Section {
                        ForEach(coHosts) { participant in
                            ParticipantRow(
                                participant: participant,
                                isCurrentUser: false,
                                canManage: viewModel.canManage
                            ) { newRole in
                                updateRole(participant: participant, to: newRole)
                            }
                        }
                    } header: {
                        sectionHeader(title: "共同ホスト", icon: "star.fill", color: .purple)
                    }
                }

                // 参加者
                if !regularParticipants.isEmpty {
                    Section {
                        ForEach(regularParticipants) { participant in
                            ParticipantRow(
                                participant: participant,
                                isCurrentUser: false,
                                canManage: viewModel.canManage
                            ) { newRole in
                                updateRole(participant: participant, to: newRole)
                            }
                        }
                    } header: {
                        sectionHeader(title: "参加者", icon: "person.fill", color: AsaColors.mutedSage)
                    }
                }
            }
            .padding()
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 24) {
            // オンライン
            VStack(spacing: 4) {
                Text("\(viewModel.onlineCount)")
                    .font(.title.bold())
                    .foregroundStyle(.green)
                Text("オンライン")
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
            }

            Divider()
                .frame(height: 40)

            // 合計
            VStack(spacing: 4) {
                Text("\(viewModel.participants.count)")
                    .font(.title.bold())
                    .foregroundStyle(AsaColors.coffeeBrown)
                Text("参加者")
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
            }

            Divider()
                .frame(height: 40)

            // 上限
            VStack(spacing: 4) {
                if let max = viewModel.event.maxParticipants {
                    Text("\(max)")
                        .font(.title.bold())
                        .foregroundStyle(AsaColors.mutedSage)
                } else {
                    Text("∞")
                        .font(.title.bold())
                        .foregroundStyle(AsaColors.mutedSage)
                }
                Text("上限")
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4)
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

    // MARK: - Methods

    private func updateRole(participant: Participant, to newRole: ParticipantRole) {
        Task {
            try? await viewModel.updateRole(for: participant, to: newRole)
        }
    }
}

// MARK: - ParticipantRow

struct ParticipantRow: View {
    let participant: Participant
    let isCurrentUser: Bool
    let canManage: Bool
    let onRoleChange: (ParticipantRole) -> Void

    @State private var showRoleMenu = false

    var body: some View {
        HStack(spacing: 12) {
            // アバター + オンライン状態
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(participant.initials)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                OnlineStatusBadge(status: participant.onlineStatus)
            }

            // 名前・ステータス
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(participant.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(AsaColors.darkSlate)

                    if isCurrentUser {
                        Text("あなた")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AsaColors.coffeeBrown)
                            .clipShape(Capsule())
                    }
                }

                Text(participant.lastSeenText)
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
            }

            Spacer()

            // ロールバッジ
            if participant.role != .participant {
                Text(participant.role.displayName)
                    .font(.caption)
                    .foregroundStyle(participant.role == .host ? .orange : .purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (participant.role == .host ? Color.orange : Color.purple).opacity(0.1)
                    )
                    .clipShape(Capsule())
            }

            // 管理メニュー
            if canManage && !isCurrentUser && participant.role != .host {
                Menu {
                    if participant.role != .coHost {
                        Button {
                            onRoleChange(.coHost)
                        } label: {
                            Label("共同ホストにする", systemImage: "star.fill")
                        }
                    }

                    if participant.role == .coHost {
                        Button {
                            onRoleChange(.participant)
                        } label: {
                            Label("共同ホストを解除", systemImage: "star.slash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(AsaColors.mutedSage)
                        .padding(8)
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    private var avatarColor: Color {
        let colors: [Color] = [
            AsaColors.coffeeBrown,
            AsaColors.mocha,
            AsaColors.mutedSage,
            .purple,
            .orange,
            .cyan
        ]
        let index = abs(participant.userId.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - OnlineStatusBadge

struct OnlineStatusBadge: View {
    let status: OnlineStatus

    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
            .overlay {
                Circle()
                    .stroke(.white, lineWidth: 2)
            }
    }

    private var statusColor: Color {
        switch status {
        case .online: return .green
        case .away: return .yellow
        case .offline: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    ParticipantListView(
        viewModel: EventDetailViewModel(
            event: Event.sampleEvents[0],
            userId: "user-1",
            dataService: MockEventDataService()
        )
    )
}
