import SwiftUI

struct AsaButton: View {
    let title: String
    let action: () -> Void
    let color: Color
    let isEnabled: Bool

    // MARK: - Init
    init(title: String, action: @escaping () -> Void, color: Color, isEnabled: Bool = true) {
        self.title = title
        self.action = action
        self.color = color
        self.isEnabled = isEnabled
    }
    
    var body: some View {
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
        }
    }
}

#Preview {
    AsaButton(title: "Test Button", action: {}, color: Color("AsaCoffeeBrown"))
    AsaButton(title: "無効ボタン", action: {}, color: Color("AsaCoffeeBrown"), isEnabled: false)
}
