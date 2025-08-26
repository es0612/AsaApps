import SwiftUI

public struct AsaCard<Content: View>: View {
    let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding()
            .background(AsaColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(radius: 2)
    }
}

#Preview {
    AsaCard {
        Text("サンプルテキスト")
            .font(.body.weight(.medium))
            .foregroundColor(AsaColors.coffeeBrown)
    }
    .padding()
    .background(AsaColors.softCream)
}