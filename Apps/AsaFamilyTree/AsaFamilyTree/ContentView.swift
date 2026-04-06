import SwiftUI
import SwiftData
import AsaFamilyTreeKit
import AsaUIKit

struct ContentView: View {
    // MARK: - Environment

    @Environment(FamilyTreeViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    @State private var selectedTab: Tab = .tree
    @State private var showingCreateTreeSheet = false

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            TreeVisualizationView()
                .tabItem {
                    Label("家系図", systemImage: "tree")
                }
                .tag(Tab.tree)

            MemberListView()
                .tabItem {
                    Label("メンバー", systemImage: "person.3.fill")
                }
                .tag(Tab.members)

            StatisticsView()
                .tabItem {
                    Label("統計", systemImage: "chart.bar.fill")
                }
                .tag(Tab.statistics)

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(AsaColors.coffeeBrown)
        .task {
            await viewModel.loadInitialData()
            await loadSampleDataIfNeeded()
        }
        .sheet(isPresented: $showingCreateTreeSheet) {
            CreateTreeSheet()
        }
        .overlay {
            if viewModel.appState == .empty && !showingCreateTreeSheet {
                EmptyStateView(showingCreateTreeSheet: $showingCreateTreeSheet)
            }
        }
    }

    // MARK: - Sample Data Loading

    /// 初回起動時にデモ用サンプルデータを投入
    private func loadSampleDataIfNeeded() async {
        let key = "AsaFamilyTree_SampleDataLoaded_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let service = SampleDataService(modelContext: modelContext)
        do {
            try service.loadSampleData()
            UserDefaults.standard.set(true, forKey: key)
            await viewModel.loadInitialData()
        } catch {
            print("サンプルデータ投入エラー: \(error.localizedDescription)")
        }
    }
}

// MARK: - Tab Enum

enum Tab: Hashable {
    case tree
    case members
    case statistics
    case settings
}

// MARK: - Empty State View

struct EmptyStateView: View {
    @Binding var showingCreateTreeSheet: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "tree.fill")
                .font(.system(size: 80))
                .foregroundStyle(AsaColors.coffeeBrown)

            Text("家系図がありません")
                .font(.title2)
                .fontWeight(.semibold)

            Text("最初の家系図を作成して、\n家族の歴史を記録しましょう")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {
                showingCreateTreeSheet = true
            }) {
                Label("家系図を作成", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AsaColors.coffeeBrown)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Create Tree Sheet

struct CreateTreeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FamilyTreeViewModel.self) private var viewModel

    @State private var treeName = ""
    @State private var treeNotes = ""
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("家系図の名前") {
                    TextField("例：山田家の家系図", text: $treeName)
                }

                Section("メモ（任意）") {
                    TextField("メモを入力", text: $treeNotes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("新しい家系図")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        createTree()
                    }
                    .disabled(treeName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
        }
    }

    private func createTree() {
        isCreating = true
        errorMessage = nil

        Task {
            do {
                try await viewModel.createTree(
                    name: treeName.trimmingCharacters(in: .whitespaces),
                    notes: treeNotes.isEmpty ? nil : treeNotes
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCreating = false
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(FamilyTreeViewModel())
}
