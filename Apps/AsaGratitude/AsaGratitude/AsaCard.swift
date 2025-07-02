import SwiftUI

struct AsaCard<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    let borderColor: Color
    
    init(backgroundColor: Color = Color(.systemBackground), borderColor: Color = Color("AsaSoftCream"), @ViewBuilder content: () -> Content) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
    }
    
    var body: some View {
        content
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        AsaCard {
            VStack(alignment: .leading) {
                Text("感謝のカード")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                Text("今日も家族と一緒に過ごせることに感謝しています。")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        
        AsaCard(backgroundColor: Color("AsaSoftCream").opacity(0.3)) {
            HStack {
                Text("👨‍👩‍👧‍👦")
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text("家族")
                        .font(.headline)
                    Text("今日の感謝")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
    .padding()
}