import Foundation
import SwiftUI

struct Landmark: Identifiable {
    let id = UUID()
    let name: String
    let park: String
    let state: String
    let description: String
    var isFavorite: Bool // いいね状態
}

