import Foundation
import SwiftUI

struct Landmark: Identifiable {
    let id = UUID()
    let name: String
    let park: String
    let state: String
    let description: String
}

let landmarks = [
    Landmark(name: "Turtle Rock", park: "Joshua Tree", state: "California", description: "A big rock that looks like a turtle."),
    Landmark(name: "Silver Salmon Creek", park: "Lake Clark", state: "Alaska", description: "A great spot for bear watching."),
    Landmark(name: "Chilkoot Trail", park: "Klondike Gold Rush", state: "Alaska", description: "A historic trail with amazing views.")
]
