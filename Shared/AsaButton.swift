import SwiftUI

struct AsaButton: View {
    let title: String
    let action: () -> Void
    let color: Color

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .padding()
                .frame(maxWidth: .infinity)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(radius: 2)
        }
    }
}

#Preview {
    AsaButton(title: "Test Button", action: {}, color: Color("AsaBlue"))
}