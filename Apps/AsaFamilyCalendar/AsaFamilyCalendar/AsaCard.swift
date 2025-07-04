import SwiftUI

struct AsaCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color = .white
    var shadowRadius: CGFloat = 4
    var cornerRadius: CGFloat = 10
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    init(backgroundColor: Color = .white, shadowRadius: CGFloat = 4, cornerRadius: CGFloat = 10, @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.shadowRadius = shadowRadius
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: shadowRadius, x: 0, y: 2)
    }
}

#Preview {
    AsaCard {
        VStack(alignment: .leading, spacing: 10) {
            Text("カードタイトル")
                .font(.headline)
                .foregroundColor(Color("AsaCoffeeBrown"))
            
            Text("これはカードの内容です。AsaCardコンポーネントを使用してコンテンツを美しく表示できます。")
                .font(.body)
                .foregroundColor(Color("AsaDarkSlate"))
        }
        .padding()
    }
    .padding()
}