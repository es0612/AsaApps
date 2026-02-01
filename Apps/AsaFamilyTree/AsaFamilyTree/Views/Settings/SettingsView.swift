import SwiftUI
import AsaFamilyTreeKit
import AsaUIKit

struct SettingsView: View {
    // MARK: - Environment

    @Environment(FamilyTreeViewModel.self) private var viewModel

    // MARK: - State

    @State private var showingCreateTreeSheet = false
    @State private var showingExportSheet = false
    @State private var showingDeleteTreeConfirmation = false
    @State private var treeToDelete: FamilyTree?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // 家系図管理
                Section("家系図") {
                    ForEach(viewModel.familyTrees, id: \.id) { tree in
                        TreeRowView(
                            tree: tree,
                            isSelected: tree.id == viewModel.currentTree?.id,
                            onSelect: {
                                viewModel.selectTree(tree)
                            },
                            onDelete: {
                                treeToDelete = tree
                                showingDeleteTreeConfirmation = true
                            }
                        )
                    }

                    Button {
                        showingCreateTreeSheet = true
                    } label: {
                        Label("新しい家系図を作成", systemImage: "plus.circle")
                    }
                }

                // エクスポート
                if viewModel.currentTree != nil {
                    Section("エクスポート") {
                        Button {
                            showingExportSheet = true
                        } label: {
                            Label("画像としてエクスポート", systemImage: "photo")
                        }

                        Button {
                            showingExportSheet = true
                        } label: {
                            Label("PDFとしてエクスポート", systemImage: "doc.richtext")
                        }
                    }
                }

                // iCloud同期
                Section("データ") {
                    HStack {
                        Label("iCloud同期", systemImage: "icloud")
                        Spacer()
                        Text("有効")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("最終更新", systemImage: "clock")
                        Spacer()
                        if let tree = viewModel.currentTree {
                            Text(tree.updatedAt, style: .relative)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("-")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // アプリ情報
                Section("アプリについて") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("開発者")
                        Spacer()
                        Text("AsaApps")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $showingCreateTreeSheet) {
                CreateTreeSheet()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportSheet()
            }
            .alert("家系図を削除", isPresented: $showingDeleteTreeConfirmation) {
                Button("削除", role: .destructive) {
                    if let tree = treeToDelete {
                        deleteTree(tree)
                    }
                }
                Button("キャンセル", role: .cancel) {
                    treeToDelete = nil
                }
            } message: {
                if let tree = treeToDelete {
                    Text("\"\(tree.name)\"を削除しますか？\n\(tree.memberCount)人のメンバーがすべて削除されます。この操作は取り消せません。")
                }
            }
        }
    }

    // MARK: - Methods

    private func deleteTree(_ tree: FamilyTree) {
        Task {
            try? await viewModel.deleteTree(tree)
            treeToDelete = nil
        }
    }
}

// MARK: - Tree Row View

struct TreeRowView: View {
    let tree: FamilyTree
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tree.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("\(tree.memberCount)人のメンバー")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AsaColors.coffeeBrown)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(FamilyTreeViewModel())
}
