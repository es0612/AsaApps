import SwiftUI

public struct AsaButton: View {
    let title: String
    let action: () -> Void
    let color: Color
    let isEnabled: Bool

    // MARK: - Init
    public init(
        title: String, 
        action: @escaping () -> Void, 
        color: Color = AsaColors.coffeeBrown, 
        isEnabled: Bool = true
    ) {
        self.title = title
        self.action = action
        self.color = color
        self.isEnabled = isEnabled
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isEnabled ? color : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 2)
                .scaleEffect(isEnabled ? 1.0 : 0.95)
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

#Preview {
    VStack(spacing: 16) {
        AsaButton(title: "テストボタン", action: {})
        AsaButton(title: "無効ボタン", action: {}, isEnabled: false)
        AsaButton(title: "カスタムカラー", action: {}, color: AsaColors.mocha)
    }
    .padding()
}