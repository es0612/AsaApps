import SwiftUI
import AsaPapaHubKit
import AsaUIKit

// MARK: - 通知設定ビュー

/// 通知の有効・無効と時間設定
struct NotificationSettingsView: View {
    @Binding var preferences: HubUserPreferences?
    @State private var notificationAuthorized = false

    // MARK: - Body

    var body: some View {
        List {
            Section {
                Toggle(isOn: notificationsBinding) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("通知")
                                .font(.body)
                            Text("朝活リマインダーや進捗通知")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }
                }
                .tint(AsaColors.coffeeBrown)
            } header: {
                Text("通知設定")
            }

            if preferences?.notificationsEnabled ?? false {
                Section {
                    DatePicker(
                        "起床時間",
                        selection: wakeUpTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                } header: {
                    Text("朝活リマインダー")
                } footer: {
                    Text("設定した時間に朝活開始のリマインダーが届きます。")
                }
            }

            if !notificationAuthorized {
                Section {
                    Button {
                        Task {
                            notificationAuthorized = await NotificationBridge.shared.requestAuthorization()
                        }
                    } label: {
                        Label("通知を許可", systemImage: "bell.badge")
                    }
                } footer: {
                    Text("通知を受け取るにはシステムの通知許可が必要です。")
                }
            }
        }
        .navigationTitle("通知設定")
        .onChange(of: preferences?.wakeUpTime) { _, newTime in
            if let time = newTime, preferences?.notificationsEnabled ?? false {
                let hour = Calendar.current.component(.hour, from: time)
                let minute = Calendar.current.component(.minute, from: time)
                NotificationBridge.shared.scheduleMorningReminder(hour: hour, minute: minute)
            }
        }
    }

    // MARK: - Private

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { preferences?.notificationsEnabled ?? false },
            set: { newValue in
                preferences?.notificationsEnabled = newValue
                preferences?.updatedAt = Date()
                if !newValue {
                    NotificationBridge.shared.removeAllNotifications()
                }
            }
        )
    }

    private var wakeUpTimeBinding: Binding<Date> {
        Binding(
            get: { preferences?.wakeUpTime ?? Date() },
            set: { newValue in
                preferences?.wakeUpTime = newValue
                preferences?.updatedAt = Date()
            }
        )
    }
}
