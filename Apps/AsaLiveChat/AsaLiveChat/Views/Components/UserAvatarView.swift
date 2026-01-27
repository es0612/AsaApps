//
//  UserAvatarView.swift
//  AsaLiveChat
//
//  ユーザーアバターコンポーネント
//

import SwiftUI
import AsaUIKit

/// ユーザーアバターを表示するコンポーネント
struct UserAvatarView: View {
    let user: ChatUser
    let size: AvatarSize
    let showOnlineStatus: Bool

    enum AvatarSize {
        case small   // 32pt
        case medium  // 44pt
        case large   // 64pt

        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 64
            }
        }

        var fontSize: Font {
            switch self {
            case .small: return .body
            case .medium: return .title3
            case .large: return .title
            }
        }

        var statusSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 16
            }
        }
    }

    init(user: ChatUser, size: AvatarSize = .medium, showOnlineStatus: Bool = true) {
        self.user = user
        self.size = size
        self.showOnlineStatus = showOnlineStatus
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // アバター本体
            Text(user.avatarEmoji)
                .font(size.fontSize)
                .frame(width: size.dimension, height: size.dimension)
                .background(AsaColors.softCream)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AsaColors.coffeeBrown.opacity(0.3), lineWidth: 1)
                )

            // オンライン状態インジケータ
            if showOnlineStatus {
                Circle()
                    .fill(user.isOnline ? Color.green : AsaColors.mutedSage)
                    .frame(width: size.statusSize, height: size.statusSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
        }
    }
}

// MARK: - User Avatar Group

/// 複数ユーザーのアバターをグループ表示
struct UserAvatarGroup: View {
    let users: [ChatUser]
    let maxDisplay: Int
    let size: UserAvatarView.AvatarSize

    init(users: [ChatUser], maxDisplay: Int = 3, size: UserAvatarView.AvatarSize = .small) {
        self.users = users
        self.maxDisplay = maxDisplay
        self.size = size
    }

    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(users.prefix(maxDisplay).enumerated()), id: \.element.id) { index, user in
                UserAvatarView(user: user, size: size, showOnlineStatus: false)
                    .zIndex(Double(maxDisplay - index))
            }

            // 追加ユーザー数
            if users.count > maxDisplay {
                Text("+\(users.count - maxDisplay)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: size.dimension, height: size.dimension)
                    .background(AsaColors.mutedSage)
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - User Row

/// ユーザー情報を1行で表示するコンポーネント
struct UserRow: View {
    let user: ChatUser
    let showStatus: Bool

    init(user: ChatUser, showStatus: Bool = true) {
        self.user = user
        self.showStatus = showStatus
    }

    var body: some View {
        HStack(spacing: 12) {
            UserAvatarView(user: user, size: .medium)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(AsaColors.darkSlate)

                if showStatus {
                    Text(user.statusText)
                        .font(.caption)
                        .foregroundColor(user.isTyping ? AsaColors.coffeeBrown : AsaColors.mutedSage)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("UserAvatarView") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            UserAvatarView(
                user: ChatUser(name: "パパ", avatarEmoji: "👨", isOnline: true),
                size: .small
            )

            UserAvatarView(
                user: ChatUser(name: "ママ", avatarEmoji: "👩", isOnline: true),
                size: .medium
            )

            UserAvatarView(
                user: ChatUser(name: "子供", avatarEmoji: "👶", isOnline: false),
                size: .large
            )
        }

        Divider()

        UserAvatarGroup(users: [
            ChatUser(name: "パパ", avatarEmoji: "👨"),
            ChatUser(name: "ママ", avatarEmoji: "👩"),
            ChatUser(name: "子供1", avatarEmoji: "👦"),
            ChatUser(name: "子供2", avatarEmoji: "👧"),
            ChatUser(name: "おじいちゃん", avatarEmoji: "👴")
        ])

        Divider()

        VStack(spacing: 8) {
            UserRow(user: ChatUser(name: "パパ", avatarEmoji: "👨", isOnline: true))
            UserRow(user: ChatUser(name: "ママ", avatarEmoji: "👩", isOnline: true, isTyping: true))
            UserRow(user: ChatUser(name: "子供", avatarEmoji: "👶", isOnline: false, lastActiveAt: Date().addingTimeInterval(-3600)))
        }
    }
    .padding()
}
