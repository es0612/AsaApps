import SwiftUI

struct ContentView: View {
    @StateObject private var profileManager = ProfileManager()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color(colorScheme == .dark ? "AsaDarkSlate" : "AsaSoftCream")
                .opacity(colorScheme == .dark ? 0.9 : 0.1)
                .ignoresSafeArea()
            Color(colorScheme == .dark ? "AsaSoftCream" : "AsaDarkSlate")
                .opacity(colorScheme == .dark ? 0.2 : 0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("AsaProfile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))

                // プロフィール画像
                Image(profileManager.profile.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray, lineWidth: 2)
                    )
                    .shadow(radius: 5)

                // 名前
                Text(profileManager.profile.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream") : Color("AsaCoffeeBrown"))

                // 紹介文
                Text(profileManager.profile.bio)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(colorScheme == .dark ? Color("AsaSoftCream").opacity(0.7) : Color("AsaCoffeeBrown").opacity(0.7))
                    .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.top)
        }
    }
}

#Preview {
    ContentView()
}
