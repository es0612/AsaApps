import SwiftUI

// MARK: - ExportSheetView
struct ExportSheetView: View {
    // MARK: - Properties

    @Bindable var viewModel: PhotoEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedResolutions: Set<ExportService.ExportResolution> = [.original]
    @State private var selectedFormat: ExportService.ExportFormat = .jpeg
    @State private var isExporting = false
    @State private var exportResults: [ExportService.ExportResult] = []
    @State private var showingShareSheet = false
    @State private var exportError: String?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // 解像度選択
                Section {
                    ForEach(ExportService.ExportResolution.allCases) { resolution in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(resolution.rawValue)
                                    .font(.body)
                                Text(resolution.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedResolutions.contains(resolution) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.asaCoffeeBrown)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedResolutions.contains(resolution) {
                                if selectedResolutions.count > 1 {
                                    selectedResolutions.remove(resolution)
                                }
                            } else {
                                selectedResolutions.insert(resolution)
                            }
                        }
                    }
                } header: {
                    Text("解像度")
                } footer: {
                    Text("複数選択でバッチエクスポートができます")
                }

                // フォーマット選択
                Section("フォーマット") {
                    Picker("形式", selection: $selectedFormat) {
                        ForEach(ExportService.ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // エクスポート結果
                if !exportResults.isEmpty {
                    Section("エクスポート結果") {
                        ForEach(exportResults, id: \.resolution.id) { result in
                            ExportResultRow(result: result)
                        }
                    }
                }

                // エラー表示
                if let error = exportError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("エクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if exportResults.isEmpty {
                        Button("エクスポート") {
                            performExport()
                        }
                        .disabled(isExporting)
                    } else {
                        Button("共有") {
                            showingShareSheet = true
                        }
                    }
                }
            }
            .overlay {
                if isExporting {
                    ExportingOverlay()
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let firstResult = exportResults.first {
                    ShareSheet(items: [firstResult.data])
                }
            }
        }
    }

    // MARK: - Methods

    private func performExport() {
        guard let image = viewModel.previewImage else { return }

        isExporting = true
        exportError = nil
        exportResults = []

        Task {
            let exportService = ExportService()
            let resolutions = Array(selectedResolutions).sorted { r1, r2 in
                (r1.maxDimension ?? .infinity) > (r2.maxDimension ?? .infinity)
            }

            var results: [ExportService.ExportResult] = []

            for resolution in resolutions {
                if let result = await exportService.export(
                    image: image,
                    resolution: resolution,
                    format: selectedFormat
                ) {
                    results.append(result)
                }
            }

            await MainActor.run {
                if results.isEmpty {
                    exportError = "エクスポートに失敗しました"
                } else {
                    exportResults = results
                }
                isExporting = false
            }
        }
    }
}

// MARK: - ExportResultRow
struct ExportResultRow: View {
    let result: ExportService.ExportResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.resolution.rawValue)
                    .font(.body)

                Text("\(Int(result.size.width)) × \(Int(result.size.height))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(formatFileSize(result.fileSize))
                .font(.caption)
                .foregroundColor(.asaCoffeeBrown)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.asaCoffeeBrown.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - ExportingOverlay
struct ExportingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("エクスポート中...")
                    .font(.headline)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    ExportSheetView(viewModel: PhotoEditorViewModel())
}
