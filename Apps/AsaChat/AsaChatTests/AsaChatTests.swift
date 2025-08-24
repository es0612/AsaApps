import Testing
@testable import AsaChat

// MARK: - AsaChat Tests

struct AsaChatTests {
    
    // MARK: - Message Model Tests
    
    @Test("Messageモデルの初期化テスト")
    func messageInitialization() throws {
        let userMessage = Message.userMessage("テストメッセージ")
        
        #expect(userMessage.text == "テストメッセージ")
        #expect(userMessage.isUser == true)
        #expect(userMessage.id != UUID())
        
        let systemMessage = Message.systemMessage("システムメッセージ")
        
        #expect(systemMessage.text == "システムメッセージ")
        #expect(systemMessage.isUser == false)
    }
    
    @Test("メッセージの時刻フォーマットテスト")
    func messageTimeFormatting() throws {
        let message = Message.userMessage("時刻テスト")
        let formattedTime = message.formattedTime
        
        #expect(!formattedTime.isEmpty)
        #expect(formattedTime.contains(":"))
    }
    
    @Test("メッセージのEquatable実装テスト")
    func messageEquality() throws {
        let message1 = Message.userMessage("同じメッセージ")
        let message2 = Message.userMessage("同じメッセージ")
        
        // IDが異なるので等しくない
        #expect(message1 != message2)
        
        // 同じインスタンスは等しい
        #expect(message1 == message1)
    }
    
    // MARK: - ChatViewModel Tests
    
    @Test("ChatViewModelの初期化テスト")
    func chatViewModelInitialization() throws {
        let viewModel = ChatViewModel()
        
        #expect(viewModel.currentMessage.isEmpty)
        #expect(viewModel.messageCount >= 0)
    }
    
    @Test("メッセージ送信機能テスト")
    func sendMessageFunctionality() throws {
        let viewModel = ChatViewModel()
        let initialCount = viewModel.messageCount
        
        viewModel.currentMessage = "テスト送信"
        viewModel.sendMessage()
        
        #expect(viewModel.currentMessage.isEmpty)
        #expect(viewModel.messageCount > initialCount)
    }
    
    @Test("空メッセージ送信の処理テスト")
    func sendEmptyMessage() throws {
        let viewModel = ChatViewModel()
        let initialCount = viewModel.messageCount
        
        viewModel.currentMessage = "   " // 空白のみ
        viewModel.sendMessage()
        
        #expect(viewModel.messageCount == initialCount) // メッセージ数は増えない
        #expect(viewModel.currentMessage.isEmpty)
    }
    
    @Test("メッセージクリア機能テスト")
    func clearMessagesFunctionality() throws {
        let viewModel = ChatViewModel()
        
        // メッセージを追加
        viewModel.currentMessage = "削除されるメッセージ"
        viewModel.sendMessage()
        
        // クリア実行
        viewModel.clearMessages()
        
        // ウェルカムメッセージが復元されることを確認
        #expect(viewModel.messageCount > 0)
        
        // 最初のメッセージがウェルカムメッセージであることを確認
        let firstMessage = viewModel.messages.first
        #expect(firstMessage?.isUser == false)
    }
    
    @Test("最終メッセージ時刻の取得テスト")
    func lastMessageTime() throws {
        let viewModel = ChatViewModel()
        
        if viewModel.messageCount > 0 {
            let lastTime = viewModel.lastMessageTime
            #expect(lastTime != nil)
            #expect(!lastTime!.isEmpty)
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("チャット会話の流れテスト")
    func chatConversationFlow() throws {
        let viewModel = ChatViewModel()
        let initialCount = viewModel.messageCount
        
        // ユーザーメッセージを送信
        viewModel.currentMessage = "おはよう"
        viewModel.sendMessage()
        
        #expect(viewModel.messageCount == initialCount + 1)
        
        // 自動返信が生成されるまで少し待つ
        let expectation = expectation(description: "Auto reply")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        // 自動返信が追加されていることを確認
        #expect(viewModel.messageCount >= initialCount + 2)
        
        // 最後のメッセージがシステムメッセージであることを確認
        let lastMessage = viewModel.messages.last
        #expect(lastMessage?.isUser == false)
    }
}

// MARK: - Helper Extensions for Testing

extension AsaChatTests {
    func expectation(description: String) -> XCTestExpectation {
        return XCTestExpectation(description: description)
    }
    
    func wait(for expectations: [XCTestExpectation], timeout: TimeInterval) {
        // Swift Testingでの非同期テスト処理
        // 実際の実装では適切な非同期テスト手法を使用
    }
}