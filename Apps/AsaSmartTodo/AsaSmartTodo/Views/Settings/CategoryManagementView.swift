//
//  CategoryManagementView.swift
//  AsaSmartTodo
//
//  カテゴリ管理画面
//  システムカテゴリ表示とカスタムカテゴリのCRUD
//

import SwiftUI
import AsaUIKit

struct CategoryManagementView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showingAddCategory = false
    @State private var editingCategory: CustomCategory?

    var body: some View {
        List {
            Section("システムカテゴリ") {
                ForEach(TaskCategory.allCases) { category in
                    SystemCategoryRow(category: category)
                }
            }

            if !viewModel.customCategories.isEmpty {
                Section("カスタムカテゴリ") {
                    ForEach(viewModel.customCategories) { category in
                        CustomCategoryRow(category: category)
                            .onTapGesture {
                                editingCategory = category
                            }
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            viewModel.deleteCustomCategory(viewModel.customCategories[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("カテゴリカスタマイズ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddCategory = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCustomCategoryView(viewModel: viewModel)
        }
        .sheet(item: $editingCategory) { category in
            EditCustomCategoryView(viewModel: viewModel, category: category)
        }
    }
}

// MARK: - System Category Row

struct SystemCategoryRow: View {
    let category: TaskCategory

    var body: some View {
        HStack(spacing: 12) {
            Text(category.icon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.body)

                Text("重要度: \(Int(category.importanceWeight * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Custom Category Row

struct CustomCategoryRow: View {
    let category: CustomCategory

    var body: some View {
        HStack(spacing: 12) {
            Text(category.icon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.body)

                Text("重要度: \(Int(category.importanceWeight * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Circle()
                .fill(category.color)
                .frame(width: 16, height: 16)
        }
    }
}

// MARK: - Add Custom Category View

struct AddCustomCategoryView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "📁"
    @State private var importanceWeight = 0.5
    @State private var selectedColor = AsaColors.coffeeBrown

    var body: some View {
        NavigationStack {
            Form {
                Section("カテゴリ情報") {
                    TextField("カテゴリ名", text: $name)

                    HStack {
                        Text("アイコン")
                        Spacer()
                        TextField("", text: $icon)
                            .multilineTextAlignment(.trailing)
                            .font(.title2)
                    }
                }

                Section("重要度") {
                    HStack {
                        Text("重要度: \(Int(importanceWeight * 100))%")
                        Spacer()
                    }

                    Slider(value: $importanceWeight, in: 0...1, step: 0.1)
                        .tint(selectedColor)
                }

                Section("カラー") {
                    ColorPicker("カテゴリカラー", selection: $selectedColor)
                }
            }
            .navigationTitle("カテゴリを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        guard !name.isEmpty else { return }

                        viewModel.addCustomCategory(
                            name: name,
                            icon: icon,
                            importanceWeight: importanceWeight,
                            colorHex: selectedColor.toHex() ?? "#C68C53"
                        )
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Custom Category View

struct EditCustomCategoryView: View {
    @Bindable var viewModel: SettingsViewModel
    let category: CustomCategory
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = ""
    @State private var importanceWeight = 0.5
    @State private var selectedColor = AsaColors.coffeeBrown

    var body: some View {
        NavigationStack {
            Form {
                Section("カテゴリ情報") {
                    TextField("カテゴリ名", text: $name)

                    HStack {
                        Text("アイコン")
                        Spacer()
                        TextField("", text: $icon)
                            .multilineTextAlignment(.trailing)
                            .font(.title2)
                    }
                }

                Section("重要度") {
                    HStack {
                        Text("重要度: \(Int(importanceWeight * 100))%")
                        Spacer()
                    }

                    Slider(value: $importanceWeight, in: 0...1, step: 0.1)
                        .tint(selectedColor)
                }

                Section("カラー") {
                    ColorPicker("カテゴリカラー", selection: $selectedColor)
                }
            }
            .navigationTitle("カテゴリを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        guard !name.isEmpty else { return }

                        category.name = name
                        category.icon = icon
                        category.importanceWeight = importanceWeight
                        category.colorHex = selectedColor.toHex() ?? category.colorHex

                        viewModel.updateCustomCategory(category)
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                name = category.name
                icon = category.icon
                importanceWeight = category.importanceWeight
                selectedColor = category.color
            }
        }
    }
}
