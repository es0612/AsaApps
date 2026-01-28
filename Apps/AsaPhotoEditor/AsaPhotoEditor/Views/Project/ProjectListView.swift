import SwiftUI
import SwiftData

// MARK: - ProjectListView
struct ProjectListView: View {
    // MARK: - Properties

    @Bindable var viewModel: PhotoEditorViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \EditProject.updatedAt, order: .reverse) private var projects: [EditProject]

    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    @State private var projectToDelete: EditProject?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    emptyState
                } else {
                    projectList
                }
            }
            .navigationTitle("プロジェクト")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "プロジェクトを検索")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .alert("プロジェクトを削除", isPresented: $showingDeleteConfirmation) {
                Button("削除", role: .destructive) {
                    if let project = projectToDelete {
                        modelContext.delete(project)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("このプロジェクトを削除しますか？この操作は取り消せません。")
            }
        }
    }

    // MARK: - Views

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.asaSoftCream.opacity(0.5))

            Text("プロジェクトがありません")
                .font(.headline)
                .foregroundColor(.asaSoftCream)

            Text("写真を編集すると\nプロジェクトとして保存できます")
                .font(.subheadline)
                .foregroundColor(.asaSoftCream.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private var projectList: some View {
        List {
            ForEach(filteredProjects) { project in
                ProjectRow(project: project) {
                    viewModel.loadProject(project)
                    dismiss()
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        projectToDelete = project
                        showingDeleteConfirmation = true
                    } label: {
                        Label("削除", systemImage: "trash")
                    }

                    Button {
                        duplicateProject(project)
                    } label: {
                        Label("複製", systemImage: "doc.on.doc")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Computed Properties

    private var filteredProjects: [EditProject] {
        if searchText.isEmpty {
            return projects
        }
        return projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Methods

    private func duplicateProject(_ project: EditProject) {
        let newProject = project.duplicate()
        modelContext.insert(newProject)
    }
}

// MARK: - ProjectRow
struct ProjectRow: View {
    let project: EditProject
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // サムネイル
                if let thumbnailData = project.thumbnailData,
                   let thumbnail = UIImage(data: thumbnailData) {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.asaMocha.opacity(0.5))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.asaSoftCream.opacity(0.5))
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(project.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // 編集状態インジケーター
                    if project.hasEdits {
                        HStack(spacing: 4) {
                            if !project.adjustment.isDefault {
                                EditBadge(icon: "slider.horizontal.3", label: "調整")
                            }
                            if !project.filterSettings.isDefault {
                                EditBadge(icon: "camera.filters", label: "フィルター")
                            }
                            if !project.cropSettings.isDefault {
                                EditBadge(icon: "crop", label: "クロップ")
                            }
                            if !project.textLayers.isEmpty {
                                EditBadge(icon: "textformat", label: "テキスト")
                            }
                            if !project.drawingLayers.isEmpty && project.drawingLayers.contains(where: { !$0.isEmpty }) {
                                EditBadge(icon: "pencil.tip", label: "描画")
                            }
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - EditBadge
struct EditBadge: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(label)
                .font(.system(size: 8))
        }
        .foregroundColor(.asaCoffeeBrown)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color.asaCoffeeBrown.opacity(0.2))
        .clipShape(Capsule())
    }
}

// MARK: - Preview
#Preview {
    ProjectListView(viewModel: PhotoEditorViewModel())
        .modelContainer(for: EditProject.self, inMemory: true)
}
