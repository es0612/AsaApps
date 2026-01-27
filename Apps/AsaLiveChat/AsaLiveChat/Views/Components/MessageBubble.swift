//
//  MessageBubble.swift
//  AsaLiveChat
//
//  チャットメッセージバブルコンポーネント
//

import SwiftUI
import AsaUIKit

/// チャットメッセージを表示するバブルコンポーネント
///
/// 送信者（自分）と受信者（相手）でスタイルが異なります。
struct MessageBubble: View {
    let message: Message
    let showSenderName: Bool

    init(message: Message, showSenderName: Bool = true) {
        self.message = message
        self.showSenderName = showSenderName
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isSentByMe {
                Spacer(minLength: 60)
                sentMessageBubble
            } else {
                receivedMessageBubble
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Sent Message (自分のメッセージ)

    private var sentMessageBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AsaColors.coffeeBrown)
                .clipShape(BubbleShape(isSentByMe: true))

            HStack(spacing: 4) {
                Text(message.displayTimestamp)
                    .font(.caption2)
                    .foregroundColor(AsaColors.mutedSage)

                Image(systemName: message.status.icon)
                    .font(.caption2)
                    .foregroundColor(statusColor)
            }
        }
    }

    // MARK: - Received Message (相手のメッセージ)

    private var receivedMessageBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            // アバター
            Text(message.senderName.prefix(1))
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 32, height: 32)
                .background(AsaColors.softCream)
                .foregroundColor(AsaColors.darkSlate)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                // 送信者名
                if showSenderName {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(AsaColors.mutedSage)
                }

                // メッセージ本文
                Text(message.content)
                    .font(.body)
                    .foregroundColor(AsaColors.darkSlate)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AsaColors.softCream.opacity(0.5))
                    .clipShape(BubbleShape(isSentByMe: false))

                // タイムスタンプ
                Text(message.displayTimestamp)
                    .font(.caption2)
                    .foregroundColor(AsaColors.mutedSage)
            }
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch message.status {
        case .pending, .sending:
            return AsaColors.mutedSage
        case .sent, .delivered:
            return AsaColors.coffeeBrown.opacity(0.6)
        case .read:
            return AsaColors.coffeeBrown
        case .failed:
            return .red
        }
    }
}

// MARK: - Bubble Shape

/// メッセージバブルの形状（片側だけ角丸）
struct BubbleShape: Shape {
    let isSentByMe: Bool
    let cornerRadius: CGFloat = 18

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: isSentByMe
                ? [.topLeft, .topRight, .bottomLeft]
                : [.topLeft, .topRight, .bottomRight],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview("送信メッセージ") {
    VStack(spacing: 16) {
        MessageBubble(
            message: Message(
                content: "おはようございます！今日も頑張りましょう！",
                senderName: "パパ",
                senderId: "user-1",
                isSentByMe: true,
                status: .sent
            )
        )

        MessageBubble(
            message: Message(
                content: "送信中...",
                senderName: "パパ",
                senderId: "user-1",
                isSentByMe: true,
                status: .sending
            )
        )
    }
    .padding()
}

#Preview("受信メッセージ") {
    VStack(spacing: 16) {
        MessageBubble(
            message: Message(
                content: "おはよう！いい天気だね",
                senderName: "ママ",
                senderId: "user-2",
                isSentByMe: false
            )
        )

        MessageBubble(
            message: Message(
                content: "今日のお昼ご飯は何にする？",
                senderName: "ママ",
                senderId: "user-2",
                isSentByMe: false
            ),
            showSenderName: false
        )
    }
    .padding()
}
