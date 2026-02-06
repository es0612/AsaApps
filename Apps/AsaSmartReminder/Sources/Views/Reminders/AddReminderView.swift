import AsaSmartReminderKit
import AsaUIKit
import SwiftUI

// MARK: - リマインダー追加

struct AddReminderView: View {
    @Bindable var viewModel: SmartReminderViewModel
    let dataService: ReminderDataService
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var note = ""
    @State private var selectedLocation: ReminderLocation?
    @State private var triggerOnEntry = true
    @State private var triggerOnExit = false
    @State private var isRepeating = false
    @State private var showLocationPicker = false

    var body: some View {
        NavigationStack {
            Form {
                // タイトルセクション
                Section("リマインダー内容") {
                    TextField("タイトル（例: 牛乳を買う）", text: $title)
                    TextField("メモ（任意）", text: $note, axis: .vertical)
                        .lineLimit(2 ... 4)
                }

                // 場所選択セクション
                Section("場所") {
                    if let location = selectedLocation {
                        HStack {
                            Image(systemName: location.category.systemImageName)
                                .foregroundStyle(AsaColors.coffeeBrown)
                            VStack(alignment: .leading) {
                                Text(location.name)
                                    .font(.headline)
                                if let address = location.address {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button("変更") {
                                showLocationPicker = true
                            }
                            .font(.caption)
                        }
                    } else {
                        Button {
                            showLocationPicker = true
                        } label: {
                            Label("場所を選択", systemImage: "mappin.circle")
                                .foregroundStyle(AsaColors.coffeeBrown)
                        }
                    }
                }

                // トリガー設定セクション
                Section("通知タイミング") {
                    Toggle("到着時に通知", isOn: $triggerOnEntry)
                    Toggle("離脱時に通知", isOn: $triggerOnExit)
                    Toggle("毎回通知（繰り返し）", isOn: $isRepeating)
                }

                // 既存の場所から選択
                if viewModel.locations.count > 0 && selectedLocation == nil {
                    Section("登録済みの場所") {
                        ForEach(viewModel.locations) { location in
                            Button {
                                selectedLocation = location
                            } label: {
                                HStack {
                                    Image(systemName: location.category.systemImageName)
                                        .foregroundStyle(AsaColors.coffeeBrown)
                                    VStack(alignment: .leading) {
                                        Text(location.name)
                                        if let address = location.address {
                                            Text(address)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text("\(location.activeReminderCount)件")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(.primary)
                        }
                    }
                }
            }
            .navigationTitle("新しいリマインダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        Task {
                            guard let location = selectedLocation else { return }
                            await viewModel.addReminder(
                                title: title,
                                note: note.isEmpty ? nil : note,
                                location: location,
                                triggerOnEntry: triggerOnEntry,
                                triggerOnExit: triggerOnExit,
                                isRepeating: isRepeating
                            )
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || selectedLocation == nil)
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    dataService: dataService,
                    onSelect: { location in
                        selectedLocation = location
                        showLocationPicker = false
                    }
                )
            }
        }
    }
}
