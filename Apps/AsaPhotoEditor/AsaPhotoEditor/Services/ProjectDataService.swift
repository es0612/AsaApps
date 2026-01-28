import Foundation
import SwiftData
import UIKit

// MARK: - ProjectDataService
/// SwiftDataを使用したプロジェクト管理サービス
@MainActor
final class ProjectDataService {
    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initializer

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    /// 新しいプロジェクトを作成
    func createProject(name: String, image: UIImage) -> EditProject {
        let project = EditProject(name: name)
        project.originalImageData = image.jpegData(compressionQuality: 0.9)
        project.thumbnailData = createThumbnail(from: image)?.jpegData(compressionQuality: 0.7)

        modelContext.insert(project)
        saveContext()

        return project
    }

    /// すべてのプロジェクトを取得
    func fetchAllProjects() -> [EditProject] {
        let descriptor = FetchDescriptor<EditProject>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("プロジェクトの取得に失敗: \(error)")
            return []
        }
    }

    /// IDでプロジェクトを取得
    func fetchProject(by id: UUID) -> EditProject? {
        let descriptor = FetchDescriptor<EditProject>(
            predicate: #Predicate { $0.id == id }
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("プロジェクトの取得に失敗: \(error)")
            return nil
        }
    }

    /// プロジェクトを更新
    func updateProject(_ project: EditProject) {
        project.updatedAt = Date()
        saveContext()
    }

    /// プロジェクトのサムネイルを更新
    func updateThumbnail(for project: EditProject, image: UIImage) {
        project.thumbnailData = createThumbnail(from: image)?.jpegData(compressionQuality: 0.7)
        project.updatedAt = Date()
        saveContext()
    }

    /// プロジェクトを削除
    func deleteProject(_ project: EditProject) {
        modelContext.delete(project)
        saveContext()
    }

    /// プロジェクトを複製
    func duplicateProject(_ project: EditProject, newName: String? = nil) -> EditProject {
        let newProject = project.duplicate(newName: newName)
        modelContext.insert(newProject)
        saveContext()
        return newProject
    }

    /// プロジェクト名を変更
    func renameProject(_ project: EditProject, newName: String) {
        project.name = newName
        project.updatedAt = Date()
        saveContext()
    }

    // MARK: - Private Methods

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("コンテキストの保存に失敗: \(error)")
        }
    }

    private func createThumbnail(from image: UIImage, maxSize: CGFloat = 200) -> UIImage? {
        let size = image.size
        let scale = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - ProjectDataService + Search
extension ProjectDataService {
    /// プロジェクトを検索
    func searchProjects(query: String) -> [EditProject] {
        let descriptor = FetchDescriptor<EditProject>(
            predicate: #Predicate { $0.name.localizedStandardContains(query) },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("プロジェクトの検索に失敗: \(error)")
            return []
        }
    }

    /// 最近のプロジェクトを取得
    func fetchRecentProjects(limit: Int = 5) -> [EditProject] {
        var descriptor = FetchDescriptor<EditProject>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("最近のプロジェクトの取得に失敗: \(error)")
            return []
        }
    }
}
