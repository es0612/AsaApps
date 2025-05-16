import Foundation

class ModelData: ObservableObject {
    @Published var landmarks: [Landmark] = landmarksdata
}

let landmarksdata = [
    Landmark(name: "Turtle Rock", park: "Joshua Tree", state: "California", description: "A big rock that looks like a turtle.", isFavorite: false),
    Landmark(name: "Silver Salmon Creek", park: "Lake Clark", state: "Alaska", description: "A great spot for bear watching.", isFavorite: true),
    Landmark(name: "Chilkoot Trail", park: "Klondike Gold Rush", state: "Alaska", description: "A historic trail with amazing views.", isFavorite: false)
]
