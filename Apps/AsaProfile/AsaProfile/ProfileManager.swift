import SwiftUI

class ProfileManager: ObservableObject {
    @Published var profile: Profile = Profile(
        name: "Asa Papa",
        bio: "SwiftUI を使ってアプリ開発を楽しむパパ。100本ノックに挑戦中！",
        imageName: "profileImage"
    )
}
