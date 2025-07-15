import SwiftUI

struct AsaCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(radius: 2)
    }
}

#Preview {
    AsaCard {
        Text("為替レート変換")
            .font(.body.weight(.medium))
            .foregroundColor(.primary)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}