import Observation
import SwiftUI
import PhotosUI

@Observable
class PhotoFrameViewModel {
    var selectedPhoto: PhotosPickerItem? = nil
    var photoImage: UIImage? = nil
    var frames: [PhotoFrame] = []
    var currentFrame: PhotoFrame = PhotoFrame()
    
    func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            photoImage = uiImage
            currentFrame.imageData = data
        }
    }
    
    func saveFrame() {
        guard currentFrame.imageData != nil else { return }
        frames.append(currentFrame)
        saveToUserDefaults()
        currentFrame = PhotoFrame()
        photoImage = nil
    }
    
    func saveToUserDefaults() {
        if let data = try? JSONEncoder().encode(frames) {
            UserDefaults.standard.set(data, forKey: "photoFrames")
        }
    }
    
    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: "photoFrames"),
           let savedFrames = try? JSONDecoder().decode([PhotoFrame].self, from: data) {
            frames = savedFrames
        }
    }
    }
