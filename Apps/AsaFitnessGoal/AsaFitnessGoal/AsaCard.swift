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

struct AsaCard_Previews: PreviewProvider {
    static var previews: some View {
        AsaCard {
            Text("サンプルテキスト")
                .font(.body.weight(.medium))
                .foregroundColor(.asaCoffeeBrown)
        }
        .padding()
        .background(.asaSoftCream)
    }
}
