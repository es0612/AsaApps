import SwiftUI
import AsaUIKit

struct SettingsView: View {
    @Bindable var viewModel: BudgetAIViewModel
    @State private var settingsVM: SettingsViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = settingsVM {
                    SettingsContent(viewModel: vm, mainViewModel: viewModel)
                } else {
                    ProgressView()
                        .onAppear {
                            initializeSettingsVM()
                        }
                }
            }
            .navigationTitle("設定")
        }
    }

    private func initializeSettingsVM() {
        do {
            let container = try DataService.createContainer()
            let dataService = DataService(modelContainer: container)
            settingsVM = SettingsViewModel(dataService: dataService)
        } catch {
            print("Failed to initialize SettingsViewModel: \(error)")
        }
    }
}

// MARK: - Settings Content

struct SettingsContent: View {
    @Bindable var viewModel: SettingsViewModel
    @Bindable var mainViewModel: BudgetAIViewModel
    @State private var showBudgetSheet = false
    @State private var showCategorySheet = false
    @State private var showResetConfirmation = false
    @State private var showSampleDataConfirmation = false

    var body: some View {
        List {
            // 予算設定
            Section("予算") {
                if let budget = mainViewModel.currentBudget {
                    HStack {
                        Text("現在の予算")
                        Spacer()
                        Text(budget.formattedTotalAmount)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("期間")
                        Spacer()
                        Text(budget.period.displayName)
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    showBudgetSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AsaColors.coffeeBrown)
                        Text("新しい予算を作成")
                    }
                }
            }

            // AI分析重み設定
            Section {
                NavigationLink {
                    AIWeightsSettingsView(viewModel: viewModel)
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(AsaColors.coffeeBrown)
                        Text("AI分析の重み設定")
                    }
                }
            } header: {
                Text("AI設定")
            } footer: {
                Text("各要因の重要度を調整してAI分析をカスタマイズできます")
            }

            // AI設定
            Section {
                Toggle("LLM分析を有効化", isOn: $viewModel.settings.llmAnalysisEnabled)

                Toggle("自動異常検知", isOn: $viewModel.settings.autoAnomalyDetection)

                HStack {
                    Text("異常検知閾値")
                    Spacer()
                    Text("\(Int(viewModel.settings.anomalyThreshold * 100))%")
                        .foregroundColor(.secondary)
                }

                Slider(value: $viewModel.settings.anomalyThreshold, in: 0.3...0.9, step: 0.05)
                    .tint(AsaColors.coffeeBrown)
            }

            // 予算警告設定
            Section("予算警告") {
                Toggle("70%到達時に通知", isOn: $viewModel.settings.budgetWarningAt70)
                Toggle("90%到達時に通知", isOn: $viewModel.settings.budgetWarningAt90)
                Toggle("100%到達時に通知", isOn: $viewModel.settings.budgetWarningAt100)
            }

            // 通知設定
            Section("通知") {
                Toggle("日次レポート", isOn: $viewModel.settings.dailyReportEnabled)

                if viewModel.settings.dailyReportEnabled {
                    Picker("レポート時間", selection: $viewModel.settings.dailyReportHour) {
                        ForEach(6..<23) { hour in
                            Text("\(hour):00").tag(hour)
                        }
                    }
                }

                Toggle("異常検知通知", isOn: $viewModel.settings.anomalyNotificationEnabled)
                Toggle("予算超過通知", isOn: $viewModel.settings.budgetExceededNotificationEnabled)
            }

            // カテゴリ管理
            Section("カテゴリ") {
                NavigationLink {
                    CategoryManagementView(viewModel: viewModel)
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(AsaColors.coffeeBrown)
                        Text("カテゴリ管理")
                        Spacer()
                        Text("\(viewModel.categories.count)件")
                            .foregroundColor(.secondary)
                    }
                }
            }

            // データ管理
            Section("データ") {
                Button {
                    exportData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(AsaColors.coffeeBrown)
                        Text("データをエクスポート")
                    }
                }

                Button {
                    showSampleDataConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "tray.and.arrow.down.fill")
                            .foregroundColor(AsaColors.coffeeBrown)
                        Text("サンプルデータを投入")
                    }
                }

                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("すべてのデータを削除")
                    }
                }
            }

            // アプリ情報
            Section("アプリ情報") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("ビルド")
                    Spacer()
                    Text("1")
                        .foregroundColor(.secondary)
                }
            }
        }
        .onChange(of: viewModel.settings.dailyReportEnabled) { _, _ in
            viewModel.saveSettings()
        }
        .onChange(of: viewModel.settings.dailyReportHour) { _, _ in
            viewModel.saveSettings()
        }
        .onChange(of: viewModel.settings.anomalyNotificationEnabled) { _, _ in
            viewModel.saveSettings()
        }
        .onChange(of: viewModel.settings.budgetExceededNotificationEnabled) { _, _ in
            viewModel.saveSettings()
        }
        .onChange(of: viewModel.settings.llmAnalysisEnabled) { _, _ in
            viewModel.saveSettings()
        }
        .onChange(of: viewModel.settings.autoAnomalyDetection) { _, _ in
            viewModel.saveSettings()
        }
        .onChange(of: viewModel.settings.anomalyThreshold) { _, _ in
            viewModel.saveSettings()
        }
        .onChange(of: viewModel.settings.budgetWarningAt70) { _, _ in
            viewModel.saveSettings()
        }
        .onChange(of: viewModel.settings.budgetWarningAt90) { _, _ in
            viewModel.saveSettings()
        }
        .onChange(of: viewModel.settings.budgetWarningAt100) { _, _ in
            viewModel.saveSettings()
        }
        .sheet(isPresented: $showBudgetSheet) {
            CreateBudgetView(viewModel: mainViewModel)
        }
        .confirmationDialog(
            "サンプルデータを投入しますか？",
            isPresented: $showSampleDataConfirmation,
            titleVisibility: .visible
        ) {
            Button("投入") {
                viewModel.insertSampleData()
                mainViewModel.refreshData()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("3ヶ月分のデモ用家計データ（収入・支出・予算）が追加されます。")
        }
        .confirmationDialog(
            "すべてのデータを削除しますか？",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                viewModel.clearAllData()
                mainViewModel.refreshData()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("この操作は取り消せません。すべての取引と予算データが削除されます。")
        }
    }

    private func exportData() {
        guard let data = viewModel.exportData() else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = "AsaBudgetAI_\(formatter.string(from: Date())).json"

        // 共有シートを表示（実際の実装ではUIActivityViewControllerを使用）
        print("Exporting \(data.count) bytes to \(filename)")
    }
}

// MARK: - AI Weights Settings View

struct AIWeightsSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                WeightSliderRow(
                    title: "カテゴリパターン",
                    subtitle: "カテゴリ別の通常支出との乖離度",
                    icon: "folder.fill",
                    color: .purple,
                    weight: $viewModel.settings.categoryPatternWeight
                )

                WeightSliderRow(
                    title: "金額偏差",
                    subtitle: "過去平均からの金額乖離",
                    icon: "yensign.circle.fill",
                    color: .red,
                    weight: $viewModel.settings.amountDeviationWeight
                )

                WeightSliderRow(
                    title: "時間パターン",
                    subtitle: "通常の支出時間帯との乖離",
                    icon: "clock.fill",
                    color: .blue,
                    weight: $viewModel.settings.timePatternWeight
                )

                WeightSliderRow(
                    title: "支出頻度",
                    subtitle: "通常の支出頻度との乖離",
                    icon: "chart.bar.fill",
                    color: .green,
                    weight: $viewModel.settings.frequencyWeight
                )

                WeightSliderRow(
                    title: "履歴トレンド",
                    subtitle: "過去の支出傾向との整合性",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange,
                    weight: $viewModel.settings.historicalTrendWeight
                )

                WeightSliderRow(
                    title: "季節変動",
                    subtitle: "季節的な支出パターンの考慮",
                    icon: "leaf.fill",
                    color: .teal,
                    weight: $viewModel.settings.seasonalWeight
                )
            } header: {
                Text("要因の重み付け")
            } footer: {
                Text("各要因の重要度を調整できます。合計が100%になるように自動調整されます。")
            }

            // 合計表示
            Section {
                HStack {
                    Text("合計")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.totalWeightsPercentage)%")
                        .font(.headline)
                        .foregroundColor(viewModel.isWeightsValid ? AsaColors.coffeeBrown : .red)
                }

                if !viewModel.isWeightsValid {
                    Button("正規化（100%に調整）") {
                        viewModel.normalizeWeights()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
            }

            // リセットボタン
            Section {
                Button("デフォルトに戻す") {
                    viewModel.resetWeightsToDefault()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("AI分析の重み設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    viewModel.saveSettings()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .alert("重みを正規化しました", isPresented: $viewModel.showWeightsNormalizationAlert) {
            Button("OK") { }
        }
    }
}

// MARK: - Weight Slider Row

struct WeightSliderRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var weight: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)

                VStack(alignment: .leading) {
                    Text(title)
                        .font(.subheadline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(weight * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 40, alignment: .trailing)
            }

            Slider(value: $weight, in: 0...0.5, step: 0.05)
                .tint(color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Management View

struct CategoryManagementView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryIcon = "folder.fill"
    @State private var newCategoryColor = "#C68C53"

    var body: some View {
        List {
            Section("デフォルトカテゴリ") {
                ForEach(viewModel.defaultCategories) { category in
                    CategoryRow(category: category)
                }
            }

            if !viewModel.customCategories.isEmpty {
                Section("カスタムカテゴリ") {
                    ForEach(viewModel.customCategories) { category in
                        CategoryRow(category: category)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            viewModel.deleteCategory(viewModel.customCategories[index])
                        }
                    }
                }
            }

            Section {
                Button {
                    showAddCategory = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AsaColors.coffeeBrown)
                        Text("カテゴリを追加")
                    }
                }
            }
        }
        .navigationTitle("カテゴリ管理")
        .sheet(isPresented: $showAddCategory) {
            NavigationStack {
                Form {
                    TextField("カテゴリ名", text: $newCategoryName)

                    Picker("アイコン", selection: $newCategoryIcon) {
                        ForEach(SettingsViewModel.availableIcons, id: \.self) { icon in
                            Image(systemName: icon).tag(icon)
                        }
                    }

                    Picker("カラー", selection: $newCategoryColor) {
                        ForEach(SettingsViewModel.availableColors, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(Color(hex: color) ?? .gray)
                                    .frame(width: 20, height: 20)
                                Text(color)
                            }
                            .tag(color)
                        }
                    }
                }
                .navigationTitle("新しいカテゴリ")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル") {
                            showAddCategory = false
                            resetNewCategory()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("追加") {
                            viewModel.addCategory(
                                name: newCategoryName,
                                iconName: newCategoryIcon,
                                colorHex: newCategoryColor
                            )
                            showAddCategory = false
                            resetNewCategory()
                        }
                        .disabled(newCategoryName.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func resetNewCategory() {
        newCategoryName = ""
        newCategoryIcon = "folder.fill"
        newCategoryColor = "#C68C53"
    }
}

struct CategoryRow: View {
    let category: Category

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: category.iconName)
                    .foregroundColor(category.color)
            }

            Text(category.name)

            Spacer()

            if category.isDefault {
                Text("デフォルト")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Create Budget View

struct CreateBudgetView: View {
    @Bindable var viewModel: BudgetAIViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = "月次予算"
    @State private var amount = ""
    @State private var period: BudgetPeriod = .monthly

    var body: some View {
        NavigationStack {
            Form {
                Section("予算名") {
                    TextField("予算名", text: $name)
                }

                Section("金額") {
                    HStack {
                        Text("¥")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .font(.title)
                    }
                }

                Section("期間") {
                    Picker("期間", selection: $period) {
                        ForEach(BudgetPeriod.allCases, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("新しい予算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作成") {
                        if let amountValue = Double(amount), amountValue > 0 {
                            viewModel.createBudget(
                                name: name,
                                amount: amountValue,
                                period: period
                            )
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || amount.isEmpty || Double(amount) == nil)
                }
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: BudgetAIViewModel(dataService: DataService(modelContainer: try! DataService.createContainer())))
}
