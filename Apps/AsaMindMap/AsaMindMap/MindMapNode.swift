import Foundation
import SwiftUI

// MARK: - MindMapNode Model

struct MindMapNode: Identifiable, Codable, Equatable {
    let id = UUID()
    var text: String
    var position: CGPoint
    var color: NodeColor
    var isEditing: Bool = false
    var createdAt: Date
    var modifiedAt: Date
    
    // MARK: - Initialization
    
    init(text: String, position: CGPoint = CGPoint(x: 200, y: 200), color: NodeColor = .asaCoffeeBrown) {
        self.text = text
        self.position = position
        self.color = color
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    // MARK: - Mutating Methods
    
    mutating func updateText(_ newText: String) {
        text = newText
        modifiedAt = Date()
    }
    
    mutating func updatePosition(_ newPosition: CGPoint) {
        position = newPosition
        modifiedAt = Date()
    }
    
    mutating func updateColor(_ newColor: NodeColor) {
        color = newColor
        modifiedAt = Date()
    }
    
    mutating func toggleEditing() {
        isEditing.toggle()
    }
    
    // MARK: - Static Factory Methods
    
    static func createNode(text: String, position: CGPoint) -> MindMapNode {
        MindMapNode(text: text, position: position)
    }
    
    static func createCentralNode(text: String) -> MindMapNode {
        MindMapNode(text: text, position: CGPoint(x: 200, y: 300), color: .asaMocha)
    }
}

// MARK: - NodeColor Enum

enum NodeColor: String, CaseIterable, Codable {
    case asaCoffeeBrown = "AsaCoffeeBrown"
    case asaMocha = "AsaMocha"
    case asaSoftCream = "AsaSoftCream"
    case asaDarkSlate = "AsaDarkSlate"
    case asaMutedSage = "AsaMutedSage"
    
    var color: Color {
        Color(self.rawValue)
    }
    
    var displayName: String {
        switch self {
        case .asaCoffeeBrown:
            return "コーヒーブラウン"
        case .asaMocha:
            return "モカ"
        case .asaSoftCream:
            return "ソフトクリーム"
        case .asaDarkSlate:
            return "ダークスレート"
        case .asaMutedSage:
            return "ミューテッドセージ"
        }
    }
}

// MARK: - MindMapNode Extensions

extension MindMapNode {
    var formattedCreatedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var displayText: String {
        text.isEmpty ? "新しいノード" : text
    }
    
    // MARK: - Sample Data for Preview
    
    static let sampleNodes: [MindMapNode] = [
        MindMapNode(text: "朝活アイデア", position: CGPoint(x: 200, y: 150)),
        MindMapNode(text: "SwiftUI学習", position: CGPoint(x: 100, y: 250)),
        MindMapNode(text: "健康管理", position: CGPoint(x: 300, y: 250)),
        MindMapNode(text: "アプリ開発", position: CGPoint(x: 50, y: 350))
    ]
}