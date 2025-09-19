import SwiftUI
import AsaUIKit

struct AuthenticationView: View {
    @State private var isSignUp = false

    var body: some View {
        if isSignUp {
            SignUpView(isSignUp: $isSignUp)
        } else {
            LoginView(isSignUp: $isSignUp)
        }
    }
}