import SwiftUI

struct AsaCard<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(
        backgroundColor: Color = Color("AsaSoftCream"),
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 2,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    var body: some View {
        content
            .padding()
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(radius: shadowRadius)
    }
}

#Preview {
    AsaCard {
        VStack {
            Text("カードの例")
                .font(.headline)
            Text("ここにコンテンツが入ります")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    .padding()
}