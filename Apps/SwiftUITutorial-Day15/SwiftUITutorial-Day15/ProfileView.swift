import SwiftUI

struct ProfileView: View {
    @State private var profile = Profile.default

    var body: some View {
        VStack {
            Text("プロフィール")
                .font(.title)
            TextField("ユーザー名", text: $profile.username)
                .textFieldStyle(.roundedBorder)
                .padding()
            Toggle("通知を有効にする", isOn: $profile.prefersNotifications)
                .padding()
                .tint(.blue)

            Picker("季節の写真", selection: $profile.seasonalPhoto) {
                ForEach(Profile.Season.allCases) { season in
                    Text(season.rawValue).tag(season)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            Text("選択された季節: \(profile.seasonalPhoto.rawValue)")
                .font(.subheadline)
            
            DatePicker("目標日", selection: $profile.goalDate, displayedComponents: .date)
                   .padding()
                   .accentColor(.blue)
            
            Button(action: {
                   print("プロフィールを保存: \(profile.username), 通知: \(profile.prefersNotifications), 季節: \(profile.seasonalPhoto.rawValue), 目標日: \(profile.goalDate)")
               }) {
                   Text("プロフィールを保存")
                       .font(.headline)
                       .foregroundColor(.white)
                       .padding()
                       .frame(maxWidth: .infinity)
                       .background(Color.blue)
                       .cornerRadius(10)
               }
               .padding()
            Text("こんにちは、\(profile.username.isEmpty ? "ゲスト" : profile.username)！")
                .font(.title2)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ProfileView()
}
