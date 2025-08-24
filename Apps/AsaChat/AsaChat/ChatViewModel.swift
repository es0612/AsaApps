import Foundation
import Observation

// MARK: - ChatViewModel

@Observable
class ChatViewModel {
    
    // MARK: - Properties
    
    private(set) var messages: [Message] = []
    var currentMessage: String = ""
    
    private let messagesKey = "AsaChat_Messages"
    
    // MARK: - Initialization
    
    init() {
        loadMessages()
        
        // 初回起動時にウェルカムメッセージを表示
        if messages.isEmpty {
            addWelcomeMessages()
        }
    }
    
    // MARK: - Public Methods
    
    /// メッセージを送信する
    func sendMessage() {
        let trimmedMessage = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedMessage.isEmpty else { return }
        
        // ユーザーメッセージを追加
        let userMessage = Message.userMessage(trimmedMessage)
        messages.append(userMessage)
        
        // 自動返信を生成
        generateAutoReply(to: trimmedMessage)
        
        // メッセージをリセット
        currentMessage = ""
        
        // 永続化
        saveMessages()
    }
    
    /// 全メッセージをクリアする
    func clearMessages() {
        messages.removeAll()
        saveMessages()
        addWelcomeMessages()
    }
    
    /// メッセージ履歴の件数を取得
    var messageCount: Int {
        messages.count
    }
    
    /// 最新メッセージの時刻を取得
    var lastMessageTime: String? {
        messages.last?.formattedTime
    }
    
    // MARK: - Private Methods
    
    private func addWelcomeMessages() {
        let welcomeMessages = [
            Message.systemMessage("AsaChatへようこそ！🌅"),
            Message.systemMessage("朝活パパエンジニアの皆さんとお話しましょう！"),
            Message.systemMessage("何かメッセージを送ってみてください。")
        ]
        
        for message in welcomeMessages {
            messages.append(message)
        }
        saveMessages()
    }
    
    private func generateAutoReply(to userMessage: String) {
        // 簡単な自動返信ロジック
        let reply: String
        
        let lowercased = userMessage.lowercased()
        
        if lowercased.contains("おはよう") || lowercased.contains("morning") {
            reply = "おはようございます！今日も素敵な朝活をお過ごしください☀️"
        } else if lowercased.contains("こんにちは") || lowercased.contains("hello") {
            reply = "こんにちは！今日はいかがお過ごしですか？"
        } else if lowercased.contains("ありがと") || lowercased.contains("thank") {
            reply = "どういたしまして！お役に立ててうれしいです😊"
        } else if lowercased.contains("元気") {
            reply = "はい！とても元気です！あなたはいかがですか？"
        } else if lowercased.contains("仕事") || lowercased.contains("work") {
            reply = "お疲れ様です！朝活で良いスタートが切れそうですね💪"
        } else if lowercased.contains("家族") || lowercased.contains("family") {
            reply = "家族との時間は大切ですね。温かい関係を築いていきましょう❤️"
        } else if lowercased.contains("アプリ") || lowercased.contains("app") {
            reply = "SwiftUIでのアプリ開発、楽しいですよね！一緒に学んでいきましょう🚀"
        } else {
            let randomReplies = [
                "なるほど、興味深いお話ですね！",
                "それは素晴らしいですね☺️",
                "詳しく教えていただけますか？",
                "そうなんですね！勉強になります。",
                "一緒に頑張りましょう！💪",
                "朝活でポジティブなスタートですね🌅"
            ]
            reply = randomReplies.randomElement() ?? "ありがとうございます！"
        }
        
        // 少し遅延を追加して自然な感じに
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let systemReply = Message.systemMessage(reply)
            self.messages.append(systemReply)
            self.saveMessages()
        }
    }
    
    // MARK: - Persistence
    
    private func saveMessages() {
        do {
            let data = try JSONEncoder().encode(messages)
            UserDefaults.standard.set(data, forKey: messagesKey)
        } catch {
            print("メッセージの保存に失敗しました: \(error)")
        }
    }
    
    private func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: messagesKey) else { return }
        
        do {
            messages = try JSONDecoder().decode([Message].self, from: data)
        } catch {
            print("メッセージの読み込みに失敗しました: \(error)")
            messages = []
        }
    }
}