import SwiftUI
import AsaUIKit

struct AddTransactionView: View {
    @Bindable var viewModel: BudgetAIViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var amount: String = ""
    @State private var title: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var type: TransactionType = .expense
    @State private var selectedCategory: Category?
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // 取引種類
                Section {
                    Picker("種類", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // 金額
                Section("金額") {
                    HStack {
                        Text("¥")
                            .font(.title2)
                            .foregroundColor(.secondary)

                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .font(.title)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // 詳細
                Section("詳細") {
                    TextField("タイトル", text: $title)

                    Picker("カテゴリ", selection: $selectedCategory) {
                        Text("未分類").tag(nil as Category?)
                        ForEach(viewModel.categories) { category in
                            Label(category.name, systemImage: category.iconName)
                                .tag(category as Category?)
                        }
                    }

                    DatePicker("日付", selection: $date, displayedComponents: .date)

                    TextField("メモ（任意）", text: $note, axis: .vertical)
                        .lineLimit(3)
                }

                // プレビュー
                if !title.isEmpty && !amount.isEmpty {
                    Section("プレビュー") {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(selectedCategory?.color.opacity(0.2) ?? Color.gray.opacity(0.2))
                                    .frame(width: 40, height: 40)

                                Image(systemName: selectedCategory?.iconName ?? type.icon)
                                    .foregroundColor(selectedCategory?.color ?? .gray)
                            }

                            VStack(alignment: .leading) {
                                Text(title)
                                    .font(.headline)
                                Text(selectedCategory?.name ?? "未分類")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(type == .expense ? "-¥\(amount)" : "+¥\(amount)")
                                .font(.headline)
                                .foregroundColor(type == .expense ? .red : .green)
                        }
                    }
                }
            }
            .navigationTitle(type == .expense ? "支出を追加" : "収入を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveTransaction()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid || isLoading)
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isValid: Bool {
        !title.isEmpty && !amount.isEmpty && Double(amount) != nil && Double(amount)! > 0
    }

    private func saveTransaction() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "有効な金額を入力してください"
            showError = true
            return
        }

        isLoading = true

        Task {
            await viewModel.addTransaction(
                amount: amountValue,
                title: title,
                note: note.isEmpty ? nil : note,
                date: date,
                type: type,
                category: selectedCategory
            )

            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Transaction Detail View

struct TransactionDetailView: View {
    let transaction: Transaction
    @Bindable var viewModel: BudgetAIViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // 基本情報
                Section {
                    HStack {
                        Text("金額")
                        Spacer()
                        Text(transaction.type == .expense ? "-" : "+")
                            + Text(transaction.formattedAmount)
                            .foregroundColor(transaction.type == .expense ? .red : .green)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("種類")
                        Spacer()
                        Label(transaction.type.displayName, systemImage: transaction.type.icon)
                            .foregroundColor(transaction.type == .expense ? .red : .green)
                    }

                    HStack {
                        Text("カテゴリ")
                        Spacer()
                        if let category = transaction.category {
                            Label(category.name, systemImage: category.iconName)
                                .foregroundColor(category.color)
                        } else {
                            Text("未分類")
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("日付")
                        Spacer()
                        Text(formatDate(transaction.date))
                    }
                }

                // メモ
                if let note = transaction.note, !note.isEmpty {
                    Section("メモ") {
                        Text(note)
                            .foregroundColor(.secondary)
                    }
                }

                // 異常検知情報
                if transaction.isAnomaly {
                    Section("AI分析") {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("異常な支出として検出されました")
                                .foregroundColor(.orange)
                        }

                        if let score = transaction.anomalyScore {
                            HStack {
                                Text("異常スコア")
                                Spacer()
                                Text(String(format: "%.0f%%", score * 100))
                                    .fontWeight(.semibold)
                            }
                        }

                        if let reasons = transaction.anomalyReasons {
                            ForEach(reasons, id: \.self) { reason in
                                Text("• \(reason)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // メタデータ
                Section("詳細情報") {
                    HStack {
                        Text("作成日時")
                        Spacer()
                        Text(formatDateTime(transaction.createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("更新日時")
                        Spacer()
                        Text(formatDateTime(transaction.updatedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // 削除ボタン
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("取引を削除")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(transaction.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "この取引を削除しますか？",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    viewModel.deleteTransaction(transaction)
                    dismiss()
                }
                Button("キャンセル", role: .cancel) { }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

#Preview {
    AddTransactionView(viewModel: BudgetAIViewModel(dataService: DataService(modelContainer: try! DataService.createContainer())))
}
