import SwiftUI
import AsaUIKit

// MARK: - AddTransactionView

struct AddTransactionView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var expenseViewModel: ExpenseViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var amount: String = ""
    @State private var title: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategoryId: String?

    @State private var amountError: String?
    @State private var titleError: String?
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Transaction Type Selector
                    typeSelector

                    // Amount Input
                    amountSection

                    // Title Input
                    titleSection

                    // Category Selector
                    categorySection

                    // Date Picker
                    dateSection

                    // Note Input
                    noteSection
                }
                .padding()
            }
            .background(AsaColors.softCream.opacity(0.3))
            .navigationTitle("取引を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await saveTransaction()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(isLoading)
                }
            }
        }
    }

    // MARK: - Type Selector

    private var typeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedType = type
                        selectedCategoryId = nil
                    }
                }) {
                    HStack {
                        Image(systemName: type.iconName)
                        Text(type.rawValue)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedType == type ? (type == .income ? Color.green : Color.red) : Color.clear)
                    .foregroundColor(selectedType == type ? .white : AsaColors.darkSlate)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AsaColors.mutedSage.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("金額")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)

            HStack {
                Text("¥")
                    .font(.title)
                    .foregroundColor(AsaColors.darkSlate)

                TextField("0", text: $amount)
                    .font(.system(size: 32, weight: .bold))
                    .keyboardType(.numberPad)
                    .foregroundColor(AsaColors.darkSlate)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)

            if let error = amountError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("タイトル")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)

            TextField("例: スーパーで買い物", text: $title)
                .textFieldStyle(RoundedTextFieldStyle())

            if let error = titleError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("カテゴリ")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(currentCategories) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategoryId == category.id
                    ) {
                        selectedCategoryId = category.id
                    }
                }
            }
        }
    }

    private var currentCategories: [ExpenseCategory] {
        selectedType == .expense ? expenseViewModel.expenseCategories : expenseViewModel.incomeCategories
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("日付")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)

            DatePicker(
                "日付を選択",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
    }

    // MARK: - Note Section

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メモ（任意）")
                .font(.subheadline)
                .foregroundColor(AsaColors.mutedSage)

            TextField("メモを追加", text: $note, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(RoundedTextFieldStyle())
        }
    }

    // MARK: - Actions

    private func saveTransaction() async {
        guard validateForm() else { return }

        guard let userId = authViewModel.currentUser?.id else {
            return
        }

        isLoading = true

        await expenseViewModel.addTransaction(
            amount: Double(amount) ?? 0,
            type: selectedType,
            title: title,
            note: note.isEmpty ? nil : note,
            date: date,
            categoryId: selectedCategoryId,
            userId: userId,
            deviceId: authViewModel.currentDeviceId
        )

        isLoading = false
        dismiss()
    }

    private func validateForm() -> Bool {
        amountError = nil
        titleError = nil

        var isValid = true

        if amount.isEmpty || (Double(amount) ?? 0) <= 0 {
            amountError = "有効な金額を入力してください"
            isValid = false
        }

        if title.isEmpty {
            titleError = "タイトルを入力してください"
            isValid = false
        }

        return isValid
    }
}

// MARK: - CategoryButton

struct CategoryButton: View {
    let category: ExpenseCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color : category.color.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: category.iconName)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : category.color)
                }

                Text(category.name)
                    .font(.caption2)
                    .foregroundColor(AsaColors.darkSlate)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddTransactionView()
        .environmentObject(AuthViewModel(authService: MockAuthService()))
        .environmentObject(ExpenseViewModel(dataService: MockExpenseDataService()))
}
