import SwiftUI
import AsaUIKit

// MARK: - JoinEventView

struct JoinEventView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: EventListViewModel
    let userName: String

    @State private var inviteCode = ""
    @State private var displayName = ""
    @State private var isJoining = false
    @State private var errorMessage: String?
    @State private var joinedEvent: Event?

    @FocusState private var focusedField: Field?

    enum Field {
        case code
        case name
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        InviteCodeGenerator.isValid(inviteCode) &&
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var normalizedCode: String {
        InviteCodeGenerator.normalize(inviteCode)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.background
                    .ignoresSafeArea()

                if let event = joinedEvent {
                    successView(event: event)
                } else {
                    formView
                }
            }
            .navigationTitle("イベントに参加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                if joinedEvent == nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("参加") {
                            joinEvent()
                        }
                        .disabled(!isFormValid || isJoining)
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                displayName = userName
            }
        }
    }

    // MARK: - Subviews

    private var formView: some View {
        VStack(spacing: 32) {
            // 説明
            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundStyle(AsaColors.coffeeBrown)

                Text("招待コードを入力してください")
                    .font(.headline)
                    .foregroundStyle(AsaColors.darkSlate)
            }
            .padding(.top, 32)

            // 招待コード入力
            VStack(spacing: 8) {
                Text("招待コード")
                    .font(.subheadline)
                    .foregroundStyle(AsaColors.mutedSage)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("ABC-123", text: $inviteCode)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .code)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4)
                    .onChange(of: inviteCode) { _, newValue in
                        // 6文字以上入力されたら切り詰め
                        if newValue.count > 6 {
                            inviteCode = String(newValue.prefix(6))
                        }
                    }

                // バリデーション表示
                if !inviteCode.isEmpty {
                    HStack {
                        if InviteCodeGenerator.isValid(inviteCode) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("有効なコード形式です")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                            Text("6文字のコードを入力してください")
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal, 24)

            // 表示名入力
            VStack(spacing: 8) {
                Text("表示名")
                    .font(.subheadline)
                    .foregroundStyle(AsaColors.mutedSage)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("あなたの名前", text: $displayName)
                    .focused($focusedField, equals: .name)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4)
            }
            .padding(.horizontal, 24)

            // エラーメッセージ
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding()
                .background(.red.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .overlay {
            if isJoining {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("参加中...")
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func successView(event: Event) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // 成功アイコン
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("参加しました！")
                .font(.title2.bold())
                .foregroundStyle(AsaColors.darkSlate)

            // イベント情報
            VStack(spacing: 16) {
                Image(systemName: event.category.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(AsaColors.coffeeBrown)
                    .frame(width: 80, height: 80)
                    .background(AsaColors.softCream)
                    .clipShape(Circle())

                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(AsaColors.darkSlate)

                Text(event.category.displayName)
                    .font(.subheadline)
                    .foregroundStyle(AsaColors.mutedSage)

                HStack(spacing: 16) {
                    Label {
                        Text(formatDate(event.startDate))
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)

                    Label {
                        Text("\(event.participantCount)人")
                    } icon: {
                        Image(systemName: "person.2")
                    }
                    .font(.caption)
                    .foregroundStyle(AsaColors.mutedSage)
                }
            }
            .padding(32)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 10)
            .padding(.horizontal, 24)

            Spacer()

            // 完了ボタン
            AsaButton(title: "イベントを開く") {
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Methods

    private func joinEvent() {
        isJoining = true
        errorMessage = nil

        Task {
            do {
                let event = try await viewModel.joinEvent(
                    inviteCode: inviteCode,
                    displayName: displayName.trimmingCharacters(in: .whitespaces)
                )
                isJoining = false
                joinedEvent = event
            } catch {
                isJoining = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    JoinEventView(
        viewModel: EventListViewModel(
            dataService: MockEventDataService(),
            userId: "demo-user-id"
        ),
        userName: "デモユーザー"
    )
}
