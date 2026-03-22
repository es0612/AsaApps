import SwiftUI
import SwiftData
import AsaUIKit

/// 設定ビュー
struct SettingsView: View {
    @Bindable var viewModel: PortfolioViewModel

    @State private var apiKey: String = ""
    @State private var showAPIKey = false
    @State private var isSavingAPIKey = false
    @State private var showSaveConfirmation = false

    @AppStorage("defaultCurrency") private var defaultCurrency = "USD"
    @AppStorage("refreshInterval") private var refreshInterval = 15

    var body: some View {
        NavigationStack {
            Form {
                // API設定セクション
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Alpha Vantage API Key")
                            .font(.subheadline.bold())

                        HStack {
                            if showAPIKey {
                                TextField("API Key", text: $apiKey)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("API Key", text: $apiKey)
                            }

                            Button {
                                showAPIKey.toggle()
                            } label: {
                                Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                    .foregroundStyle(AsaColors.mutedSage)
                            }
                        }

                        Button {
                            saveAPIKey()
                        } label: {
                            HStack {
                                if isSavingAPIKey {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text("保存")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(AsaColors.coffeeBrown)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(apiKey.isEmpty || isSavingAPIKey)
                    }
                } header: {
                    Text("API設定")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alpha Vantageの無料プラン: 1日500リクエスト")
                        Link("APIキーを取得", destination: URL(string: "https://www.alphavantage.co/support/#api-key")!)
                            .font(.caption)
                    }
                }

                // 表示設定セクション
                Section("表示設定") {
                    Picker("デフォルト通貨", selection: $defaultCurrency) {
                        Text("USD ($)").tag("USD")
                        Text("JPY (¥)").tag("JPY")
                        Text("EUR (€)").tag("EUR")
                    }

                    Picker("自動更新間隔", selection: $refreshInterval) {
                        Text("15分").tag(15)
                        Text("30分").tag(30)
                        Text("1時間").tag(60)
                        Text("手動のみ").tag(0)
                    }
                }

                // API状態セクション
                Section("API状態") {
                    HStack {
                        Text("残りリクエスト数")
                        Spacer()
                        Text("\(viewModel.remainingAPIRequests)")
                            .foregroundStyle(AsaColors.coffeeBrown)
                            .bold()
                    }

                    if let lastUpdated = viewModel.lastUpdated {
                        HStack {
                            Text("最終更新")
                            Spacer()
                            Text(lastUpdated, style: .relative)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // データ管理セクション
                Section("データ管理") {
                    Button {
                        Task {
                            await viewModel.refreshQuotes()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("株価を更新")
                            Spacer()
                            if viewModel.isRefreshing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.isRefreshing)

                    NavigationLink {
                        DataExportView()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("データエクスポート")
                        }
                    }
                }

                // アプリ情報セクション
                Section("アプリ情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("ビルド")
                        Spacer()
                        Text("1")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/asapapa")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("開発者サイト")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // クレジットセクション
                Section("クレジット") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("株価データ: Alpha Vantage")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("AsaApps - 朝活パパエンジニアの100アプリプロジェクト")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .onAppear {
                apiKey = AlphaVantageService.loadAPIKeyFromUserDefaults()
            }
            .alert("保存完了", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("APIキーを保存しました")
            }
        }
    }

    private func saveAPIKey() {
        isSavingAPIKey = true

        // APIキーを保存
        UserDefaults.standard.set(apiKey, forKey: "AlphaVantageAPIKey")

        // 少し遅延させてフィードバックを表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSavingAPIKey = false
            showSaveConfirmation = true
        }
    }
}

// MARK: - Data Export View

struct DataExportView: View {
    @State private var isExporting = false
    @State private var exportMessage: String?

    var body: some View {
        List {
            Section {
                Button {
                    exportPortfolioData()
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("ポートフォリオをCSVでエクスポート")
                    }
                }

                Button {
                    exportTransactionHistory()
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                        Text("取引履歴をCSVでエクスポート")
                    }
                }
            } header: {
                Text("エクスポート形式")
            } footer: {
                Text("エクスポートしたファイルは共有シートから保存できます")
            }

            if let message = exportMessage {
                Section {
                    Text(message)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("データエクスポート")
    }

    private func exportPortfolioData() {
        exportMessage = "ポートフォリオデータのエクスポート機能は今後実装予定です"
    }

    private func exportTransactionHistory() {
        exportMessage = "取引履歴のエクスポート機能は今後実装予定です"
    }
}

#Preview {
    SettingsView(viewModel: PortfolioViewModel(
        stockAPIService: MockStockAPIService(),
        dataService: PortfolioDataService(modelContext: try! ModelContext(ModelContainer(for: Portfolio.self)))
    ))
}
