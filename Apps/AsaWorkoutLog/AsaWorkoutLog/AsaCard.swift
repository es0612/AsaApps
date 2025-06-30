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
                Text("カード タイトル")
                    .font(.headline)
                    .foregroundColor(Color("AsaCoffeeBrown"))
                Text("カードのコンテンツがここに表示されます。")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        
        AsaCard(backgroundColor: Color("AsaSoftCream").opacity(0.3)) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundColor(Color("AsaCoffeeBrown"))
                VStack(alignment: .leading) {
                    Text("ランニング")
                        .font(.headline)
                    Text("30分")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
    .padding()
}