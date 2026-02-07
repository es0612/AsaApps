import SwiftUI
import AsaPhotoStoryKit

/// 写真要素ビュー
/// 写真画像とオプションのキャプションを表示する
struct PhotoElementView: View {
    let element: StoryElement

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                // 写真画像
                if let imageData = element.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: geometry.size.width,
                            height: captionHeight(geometry)
                        )
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // プレースホルダー
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(
                            width: geometry.size.width,
                            height: captionHeight(geometry)
                        )
                        .overlay {
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                }

                // キャプション
                if let caption = element.captionText, !caption.isEmpty {
                    Text(caption)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 4)
                }
            }
        }
    }

    private func captionHeight(_ geometry: GeometryProxy) -> CGFloat {
        let hasCaption = element.captionText != nil && !(element.captionText?.isEmpty ?? true)
        return hasCaption ? geometry.size.height * 0.85 : geometry.size.height
    }
}

#Preview {
    PhotoElementView(element: StoryElement(type: .photo))
        .frame(width: 200, height: 200)
}
