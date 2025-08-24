import SwiftUI

// MARK: - ChatMessageView

struct ChatMessageView: View {
    let message: Message
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.isUser {
                Spacer()
                userMessageBubble
            } else {
                systemMessageBubble
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    // MARK: - User Message Bubble
    
    private var userMessageBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            AsaCard {
                Text(message.text)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .background(Color("AsaCoffeeBrown"))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Text(message.formattedTime)
                .font(.caption2)
                .foregroundColor(Color("AsaMutedSage"))
                .padding(.trailing, 4)
        }
        .frame(maxWidth: 280, alignment: .trailing)
    }
    
    // MARK: - System Message Bubble
    
    private var systemMessageBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            AsaCard {
                HStack(alignment: .top, spacing: 8) {
                    // アイコン
                    Circle()
                        .fill(Color("AsaSoftCream"))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("🌅")
                                .font(.title3)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AsaChat")
                            .font(.caption)
                            .foregroundColor(Color("AsaMutedSage"))
                        
                        Text(message.text)
                            .font(.body)
                            .foregroundColor(Color("AsaDarkSlate"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color("AsaSoftCream").opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Text(message.formattedTime)
                .font(.caption2)
                .foregroundColor(Color("AsaMutedSage"))
                .padding(.leading, 8)
        }
        .frame(maxWidth: 280, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ChatMessageView(message: Message.userMessage("おはようございます！今日も良い一日になりそうです。"))
        
        ChatMessageView(message: Message.systemMessage("おはようございます！今日も素敵な朝活をお過ごしください☀️"))
        
        ChatMessageView(message: Message.userMessage("ありがとう！"))
        
        ChatMessageView(message: Message.systemMessage("どういたしまして！お役に立ててうれしいです😊"))
    }
    .padding()
    .background(Color("AsaDarkSlate").opacity(0.1))
}