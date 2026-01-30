import SwiftUI
import AsaUIKit

// MARK: - InviteView

struct InviteView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    let event: Event

    @State private var isCopied = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.background
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // イベント情報
                    VStack(spacing: 16) {
                        Image(systemName: event.category.icon)
                            .font(.system(size: 48))
                            .foregroundStyle(AsaColors.coffeeBrown)
                            .frame(width: 80, height: 80)
                            .background(AsaColors.softCream)
                            .clipShape(Circle())

                        Text(event.title)
                            .font(.title3.bold())
                            .foregroundStyle(AsaColors.darkSlate)
                            .multilineTextAlignment(.center)
                    }

                    // 招待コード
                    VStack(spacing: 16) {
                        Text("招待コード")
                            .font(.subheadline)
                            .foregroundStyle(AsaColors.mutedSage)

                        Text(InviteCodeGenerator.formatted(event.inviteCode))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundStyle(AsaColors.coffeeBrown)
                            .tracking(4)

                        Button {
                            copyToClipboard()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "コピーしました" : "コードをコピー")
                            }
                            .font(.subheadline)
                            .foregroundStyle(isCopied ? .green : AsaColors.coffeeBrown)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(isCopied ? Color.green.opacity(0.1) : AsaColors.softCream)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(32)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 10)
                    .padding(.horizontal, 24)

                    // 共有ボタン
                    VStack(spacing: 16) {
                        Text("このコードを友人や家族と共有して\nイベントに招待しましょう")
                            .font(.subheadline)
                            .foregroundStyle(AsaColors.mutedSage)
                            .multilineTextAlignment(.center)

                        ShareLink(
                            item: shareText,
                            subject: Text(event.title),
                            message: Text("招待コード: \(event.inviteCode)")
                        ) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("招待を共有")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AsaColors.coffeeBrown)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("招待する")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Computed Properties

    private var shareText: String {
        """
        「\(event.title)」に参加しませんか？

        📅 \(formatDate(event.startDate))
        📍 \(event.location ?? "未設定")

        招待コード: \(InviteCodeGenerator.formatted(event.inviteCode))

        AsaEventLiveアプリで「招待コードで参加」から入力してください。
        """
    }

    // MARK: - Methods

    private func copyToClipboard() {
        UIPasteboard.general.string = event.inviteCode
        withAnimation {
            isCopied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E) HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    InviteView(event: Event.sampleEvents[0])
}
