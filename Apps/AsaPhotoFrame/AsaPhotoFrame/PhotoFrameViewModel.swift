import Observation
import SwiftUI
import PhotosUI

@Observable
class PhotoFrameViewModel {
    var selectedPhoto: PhotosPickerItem? = nil
    var photoImage: UIImage? = nil
    var frames: [PhotoFrame] = []
    var currentFrame: PhotoFrame = PhotoFrame()
    
    // カスタマイズ可能なプロパティ
    var selectedColorHex: String = "#C68C53" {
        didSet { currentFrame.frameColorHex = selectedColorHex }
    }
    var frameWidth: CGFloat = 5.0 {
        didSet { currentFrame.frameWidth = frameWidth }
    }
    var frameStyle: StrokeStyle = StrokeStyle(lineWidth: 5, dash: []) { // 実線
        didSet { updateFrameStyle() }
    }
    
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
    
    func frameColor() -> Color {
        Color(currentFrame.frameColorHex)
    }
    
    // 枠スタイルを更新
    private func updateFrameStyle() {
        // 現在の実装では直接適用しないが、後でUIで制御
    }
    
    // 破線スタイルをトグル（例）
    func toggleDashStyle() {
        frameStyle = frameStyle.dash.isEmpty ? StrokeStyle(lineWidth: 5, dash: [10, 5]) : StrokeStyle(lineWidth: 5, dash: [])
        updateFrameStyle()
    }
    
    func saveToPhotoLibrary() {
        guard let image = photoImage else { return }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300))
        let uiImage = renderer.image { context in
            let cgContext = context.cgContext
            // 画像を描画
            image.draw(in: CGRect(origin: .zero, size: CGSize(width: 300, height: 300)))
            // 枠の設定
            cgContext.setStrokeColor(frameColor().cgColor!)
            cgContext.setLineWidth(frameStyle.lineWidth)
            let rect = CGRect(origin: .zero, size: CGSize(width: 300, height: 300)).insetBy(dx: frameStyle.lineWidth / 2, dy: frameStyle.lineWidth / 2)
            cgContext.addRect(rect)
            cgContext.strokePath() // 枠を描画
        }
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
    }
}
