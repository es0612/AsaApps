import SwiftUI
import AsaUIKit
import AsaPhotoStoryKit

/// ストーリープレビュー画面
/// フルスクリーンでスライドショー形式のプレビューを表示する
struct StoryPreviewView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    let story: PhotoStory
    @State private var currentPageIndex = 0
    @State private var isPlaying = true
    @State private var timer: Timer?

    private let autoPlayInterval: TimeInterval = 3.0

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()

            // ページ表示
            TabView(selection: $currentPageIndex) {
                ForEach(Array(story.sortedPages.enumerated()), id: \.offset) { index, page in
                    PreviewPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // オーバーレイUI
            VStack {
                // プログレスバー
                progressBar

                Spacer()

                // コントロール
                controlBar
            }
        }
        .statusBarHidden()
        .onAppear {
            startAutoPlay()
        }
        .onDisappear {
            stopAutoPlay()
        }
        .onChange(of: currentPageIndex) { _, _ in
            if isPlaying {
                restartAutoPlay()
            }
        }
    }

    // MARK: - Subviews

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<story.sortedPages.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= currentPageIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.3), value: currentPageIndex)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
    }

    private var controlBar: some View {
        HStack(spacing: 32) {
            // 前のページ
            Button {
                withAnimation {
                    if currentPageIndex > 0 {
                        currentPageIndex -= 1
                    }
                }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .disabled(currentPageIndex == 0)
            .opacity(currentPageIndex == 0 ? 0.3 : 1)

            // 再生/一時停止
            Button {
                isPlaying.toggle()
                if isPlaying {
                    startAutoPlay()
                } else {
                    stopAutoPlay()
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(AsaColors.coffeeBrown.opacity(0.8))
                    .clipShape(Circle())
            }

            // 次のページ
            Button {
                withAnimation {
                    if currentPageIndex < story.sortedPages.count - 1 {
                        currentPageIndex += 1
                    }
                }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .disabled(currentPageIndex >= story.sortedPages.count - 1)
            .opacity(currentPageIndex >= story.sortedPages.count - 1 ? 0.3 : 1)

            Spacer()

            // 閉じるボタン
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Auto Play

    private func startAutoPlay() {
        stopAutoPlay()
        timer = Timer.scheduledTimer(withTimeInterval: autoPlayInterval, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                if currentPageIndex < story.sortedPages.count - 1 {
                    currentPageIndex += 1
                } else {
                    currentPageIndex = 0
                }
            }
        }
    }

    private func stopAutoPlay() {
        timer?.invalidate()
        timer = nil
    }

    private func restartAutoPlay() {
        stopAutoPlay()
        startAutoPlay()
    }
}

// MARK: - PreviewPageView

private struct PreviewPageView: View {
    let page: StoryPage

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // ページ背景
                if let bgHex = page.backgroundColorHex {
                    Color(hex: bgHex)
                } else {
                    Color.white
                }

                // 要素表示
                ForEach(page.sortedElements) { element in
                    previewElement(element, in: geometry.size)
                }
            }
        }
    }

    @ViewBuilder
    private func previewElement(_ element: StoryElement, in size: CGSize) -> some View {
        let width = element.width * size.width
        let height = element.height * size.height

        Group {
            switch element.elementType {
            case .photo:
                PhotoElementView(element: element)
            case .text:
                TextElementView(element: element)
            case .sticker:
                StickerElementView(element: element)
            case .drawing:
                DrawingElementView(element: element)
            }
        }
        .frame(width: width, height: height)
        .rotationEffect(.degrees(element.rotation))
        .opacity(element.opacity)
        .position(
            x: element.positionX * size.width,
            y: element.positionY * size.height
        )
        .transition(.opacity.combined(with: .scale))
    }
}

#Preview {
    StoryPreviewView(story: PhotoStory(title: "テスト", template: .blank, theme: .warm))
}
