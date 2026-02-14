import SwiftUI
import AsaUIKit
import AsaCommunityKit

/// 安全レポート作成シート
struct SafetyReportSheet: View {
    @Bindable var viewModel: SafetyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var reportDescription = ""
    @State private var alertLevel: SafetyAlertLevel = .info

    var body: some View {
        NavigationStack {
            Form {
                Section("レポート内容") {
                    TextField("タイトル", text: $title)
                    TextEditor(text: $reportDescription)
                        .frame(minHeight: 100)
                }

                Section("警戒レベル") {
                    Picker("レベル", selection: $alertLevel) {
                        ForEach(SafetyAlertLevel.allCases, id: \.self) { level in
                            Label(level.rawValue, systemImage: level.iconName)
                                .tag(level)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("安全レポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("送信") {
                        Task {
                            await viewModel.createReport(
                                title: title,
                                description: reportDescription,
                                alertLevel: alertLevel,
                                latitude: 0,
                                longitude: 0
                            )
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
