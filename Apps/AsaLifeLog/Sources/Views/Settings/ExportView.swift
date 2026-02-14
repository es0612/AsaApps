import SwiftUI
import AsaLifeLogKit

// MARK: - ExportView

/// データエクスポートビュー
struct ExportView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showShareSheet = false

    var body: some View {
        Form {
            Section("エクスポート形式") {
                Button {
                    Task { await viewModel.exportDataAsJSON() }
                } label: {
                    Label("JSONでエクスポート", systemImage: "doc.text")
                }
                .disabled(viewModel.isLoading)

                Button {
                    Task { await viewModel.exportDataAsCSV() }
                } label: {
                    Label("CSVでエクスポート", systemImage: "tablecells")
                }
                .disabled(viewModel.isLoading)
            }

            if viewModel.isLoading {
                Section {
                    ProgressView("エクスポート中...")
                }
            }

            Section {
                Text("過去1年分のライフログデータをエクスポートします。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("データエクスポート")
        .onChange(of: viewModel.exportedData) {
            if viewModel.exportedData != nil {
                showShareSheet = true
            }
        }
    }
}
