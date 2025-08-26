import SwiftUI

public struct AsaKanbanCard: View {
    let title: String
    let description: String?
    let priority: TaskPriority
    let dueDate: Date?
    let onTap: () -> Void
    
    public init(
        title: String,
        description: String? = nil,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        onTap: @escaping () -> Void = {}
    ) {
        self.title = title
        self.description = description
        self.priority = priority
        self.dueDate = dueDate
        self.onTap = onTap
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // タイトル
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(AsaColors.darkSlate)
                .multilineTextAlignment(.leading)
            
            // 説明
            if let description = description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(AsaColors.darkSlate.opacity(0.7))
                    .multilineTextAlignment(.leading)
            }
            
            HStack {
                // 優先度インジケータ
                priorityIndicator
                
                Spacer()
                
                // 期日表示
                if let dueDate = dueDate {
                    dueDateView(dueDate)
                }
            }
        }
        .padding()
        .background(AsaColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(priorityColor.opacity(0.3), lineWidth: 2)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private var priorityIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            Text(priority.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(priorityColor)
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .high:
            return Color.red
        case .medium:
            return AsaColors.coffeeBrown
        case .low:
            return AsaColors.mutedSage
        }
    }
    
    private func dueDateView(_ date: Date) -> some View {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        
        let isOverdue = date < Date()
        let textColor = isOverdue ? Color.red : AsaColors.darkSlate.opacity(0.7)
        
        return Text(formatter.string(from: date))
            .font(.caption2)
            .foregroundColor(textColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isOverdue ? Color.red.opacity(0.1) : AsaColors.softCream)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// 優先度の定義
public enum TaskPriority: String, CaseIterable, Identifiable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .high: return "高"
        case .medium: return "中"
        case .low: return "低"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AsaKanbanCard(
            title: "APIエンドポイントの実装",
            description: "RESTful APIの設計と実装を行う",
            priority: .high,
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
        )
        
        AsaKanbanCard(
            title: "UI改善",
            priority: .medium
        )
        
        AsaKanbanCard(
            title: "テストケース追加",
            description: "単体テストとUIテストを追加",
            priority: .low,
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) // 期限切れ
        )
    }
    .padding()
    .background(AsaColors.softCream)
}