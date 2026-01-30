import SwiftUI
import AsaUIKit

// MARK: - CreateEventView

struct CreateEventView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: EventListViewModel

    @State private var title = ""
    @State private var description = ""
    @State private var category: EventCategory = .other
    @State private var location = ""
    @State private var startDate = Date()
    @State private var endDate: Date?
    @State private var hasEndDate = false

    @State private var isCreating = false
    @State private var createdEvent: Event?
    @State private var showInviteCode = false

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AsaColors.background
                    .ignoresSafeArea()

                if showInviteCode, let event = createdEvent {
                    inviteCodeView(event: event)
                } else {
                    formView
                }
            }
            .navigationTitle("イベント作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                if !showInviteCode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("作成") {
                            createEvent()
                        }
                        .disabled(!isFormValid || isCreating)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var formView: some View {
        Form {
            // 基本情報
            Section("基本情報") {
                TextField("イベント名", text: $title)

                TextField("説明（任意）", text: $description, axis: .vertical)
                    .lineLimit(3...6)

                Picker("カテゴリ", selection: $category) {
                    ForEach(EventCategory.allCases, id: \.self) { category in
                        Label(category.displayName, systemImage: category.icon)
                            .tag(category)
                    }
                }

                TextField("場所（任意）", text: $location)
            }

            // 日時
            Section("日時") {
                DatePicker(
                    "開始日時",
                    selection: $startDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )

                Toggle("終了日時を設定", isOn: $hasEndDate)

                if hasEndDate {
                    DatePicker(
                        "終了日時",
                        selection: Binding(
                            get: { endDate ?? startDate.addingTimeInterval(3600) },
                            set: { endDate = $0 }
                        ),
                        in: startDate...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }

            // プレビュー
            Section("プレビュー") {
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundStyle(AsaColors.coffeeBrown)
                        .frame(width: 44, height: 44)
                        .background(AsaColors.softCream)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title.isEmpty ? "イベント名" : title)
                            .font(.headline)
                            .foregroundStyle(title.isEmpty ? .secondary : AsaColors.darkSlate)

                        Text(category.displayName)
                            .font(.caption)
                            .foregroundStyle(AsaColors.mutedSage)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .overlay {
            if isCreating {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("作成中...")
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func inviteCodeView(event: Event) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // 成功アイコン
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("イベントを作成しました！")
                .font(.title2.bold())
                .foregroundStyle(AsaColors.darkSlate)

            // 招待コード表示
            VStack(spacing: 16) {
                Text("招待コード")
                    .font(.subheadline)
                    .foregroundStyle(AsaColors.mutedSage)

                Text(InviteCodeGenerator.formatted(event.inviteCode))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(AsaColors.coffeeBrown)
                    .tracking(4)

                Button {
                    UIPasteboard.general.string = event.inviteCode
                } label: {
                    Label("コードをコピー", systemImage: "doc.on.doc")
                        .font(.subheadline)
                        .foregroundStyle(AsaColors.coffeeBrown)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AsaColors.softCream)
                        .clipShape(Capsule())
                }
            }
            .padding(32)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 10)
            .padding(.horizontal, 24)

            Text("このコードを共有して、\n友人や家族を招待しましょう")
                .font(.subheadline)
                .foregroundStyle(AsaColors.mutedSage)
                .multilineTextAlignment(.center)

            Spacer()

            // 完了ボタン
            AsaButton(title: "完了") {
                dismiss()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Methods

    private func createEvent() {
        isCreating = true

        Task {
            do {
                let event = try await viewModel.createEvent(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: description.trimmingCharacters(in: .whitespaces),
                    category: category,
                    location: location.isEmpty ? nil : location.trimmingCharacters(in: .whitespaces),
                    startDate: startDate,
                    endDate: hasEndDate ? endDate : nil
                )

                createdEvent = event
                isCreating = false
                showInviteCode = true
            } catch {
                isCreating = false
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CreateEventView(
        viewModel: EventListViewModel(
            dataService: MockEventDataService(),
            userId: "demo-user-id"
        )
    )
}
