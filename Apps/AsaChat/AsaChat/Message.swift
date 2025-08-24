import Foundation

// MARK: - Message Model

struct Message: Identifiable, Codable, Equatable {
    let id = UUID()
    let text: String
    let timestamp: Date
    let isUser: Bool
    
    // MARK: - Initialization
    
    init(text: String, isUser: Bool = true) {
        self.text = text
        self.timestamp = Date()
        self.isUser = isUser
    }
    
    // MARK: - Helper Properties
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    // MARK: - Static Factory Methods
    
    static func userMessage(_ text: String) -> Message {
        Message(text: text, isUser: true)
    }
    
    static func systemMessage(_ text: String) -> Message {
        Message(text: text, isUser: false)
    }
}

// MARK: - Message Extensions

extension Message {
    /// サンプルメッセージデータ
    static let sampleMessages: [Message] = [
        .systemMessage("AsaChatへようこそ！"),
        .userMessage("こんにちは！"),
        .systemMessage("今日も素敵な一日をお過ごしください！"),
        .userMessage("ありがとう！")
    ]
}