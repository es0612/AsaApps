import SwiftUI

struct ProfileView: View {
    @State private var username = ""

    var body: some View {
        VStack {
            Text("プロフィール")
                .font(.title)
            TextField("ユーザー名", text: $username)
                .textFieldStyle(.roundedBorder)
                .padding()
            Text("こんにちは、\(username.isEmpty ? "ゲスト" : username)！")
                .font(.title2)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ProfileView()
}
