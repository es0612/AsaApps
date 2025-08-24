import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @State private var chatViewModel = ChatViewModel()
    @State private var isShowingClearAlert = false
    @FocusState private var isInputFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - Chat Messages Area
                chatMessagesArea
                
                // MARK: - Input Area
                inputArea
            }
            .navigationTitle("AsaChat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarMenu
                }
            }
            .alert("チャット履歴をクリア", isPresented: $isShowingClearAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("クリア", role: .destructive) {
                    chatViewModel.clearMessages()
                }
            } message: {
                Text("すべてのメッセージが削除されます。この操作は元に戻せません。")
            }
            .background(
                LinearGradient(
                    colors: [
                        Color("AsaDarkSlate").opacity(0.05),
                        Color("AsaSoftCream").opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
    
    // MARK: - Chat Messages Area
    
    private var chatMessagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(chatViewModel.messages) { message in
                        ChatMessageView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: chatViewModel.messages.count) { _, _ in
                // 新しいメッセージが追加されたら自動スクロール
                if let lastMessage = chatViewModel.messages.last {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .onTapGesture {
            // チャット領域タップでキーボードを閉じる
            isInputFieldFocused = false
        }
    }
    
    // MARK: - Input Area
    
    private var inputArea: some View {
        VStack(spacing: 12) {
            // メッセージ統計表示
            if chatViewModel.messageCount > 0 {
                messageStatsView
            }
            
            // 入力フィールドと送信ボタン
            HStack(spacing: 12) {
                // テキスト入力フィールド
                TextField("メッセージを入力...", text: $chatViewModel.currentMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFieldFocused)
                    .lineLimit(1...4)
                    .onSubmit {
                        sendMessageAction()
                    }
                
                // 送信ボタン
                AsaButton(
                    title: "送信",
                    action: sendMessageAction,
                    color: Color("AsaCoffeeBrown")
                )
                .disabled(chatViewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(chatViewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color("AsaSoftCream")
                .opacity(0.3)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        )
    }
    
    // MARK: - Message Stats View
    
    private var messageStatsView: some View {
        AsaCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("メッセージ数: \(chatViewModel.messageCount)")
                        .font(.caption)
                        .foregroundColor(Color("AsaMutedSage"))
                    
                    if let lastTime = chatViewModel.lastMessageTime {
                        Text("最終メッセージ: \(lastTime)")
                            .font(.caption2)
                            .foregroundColor(Color("AsaMutedSage"))
                    }
                }
                
                Spacer()
                
                Text("🌅")
                    .font(.title2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color("AsaDarkSlate").opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Toolbar Menu
    
    private var toolbarMenu: some View {
        Menu {
            Button(action: {
                isShowingClearAlert = true
            }) {
                Label("チャット履歴をクリア", systemImage: "trash")
            }
            
            Button(action: {
                // キーボードの表示/非表示切り替え
                isInputFieldFocused.toggle()
            }) {
                Label(isInputFieldFocused ? "キーボードを閉じる" : "キーボードを表示", 
                      systemImage: isInputFieldFocused ? "keyboard.chevron.compact.down" : "keyboard")
            }
            
            Button(action: {}) {
                Label("アプリについて", systemImage: "info.circle")
            }
            
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(Color("AsaCoffeeBrown"))
        }
    }
    
    // MARK: - Actions
    
    private func sendMessageAction() {
        chatViewModel.sendMessage()
        // 送信後にキーボードフォーカスを維持
        isInputFieldFocused = true
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}