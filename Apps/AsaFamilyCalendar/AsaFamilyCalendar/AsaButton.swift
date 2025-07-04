import SwiftUI

struct AsaButton: View {
    let title: String
    let action: () -> Void
    var style: ButtonStyle = .primary
    var size: ButtonSize = .medium
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(fontSize)
                .fontWeight(.medium)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, verticalPadding)
                .padding(.horizontal, horizontalPadding)
                .background(backgroundColor)
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color("AsaCoffeeBrown")
        case .secondary:
            return Color("AsaSoftCream")
        case .destructive:
            return Color.red
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return Color("AsaDarkSlate")
        case .destructive:
            return .white
        }
    }
    
    private var fontSize: Font {
        switch size {
        case .small:
            return .caption
        case .medium:
            return .body
        case .large:
            return .title3
        }
    }
    
    private var verticalPadding: CGFloat {
        switch size {
        case .small:
            return 8
        case .medium:
            return 12
        case .large:
            return 16
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small:
            return 12
        case .medium:
            return 16
        case .large:
            return 20
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AsaButton(title: "プライマリボタン", action: {})
        AsaButton(title: "セカンダリボタン", action: {}, style: .secondary)
        AsaButton(title: "削除ボタン", action: {}, style: .destructive)
    }
    .padding()
}