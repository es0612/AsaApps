import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - ImageProcessingService
/// Core Imageを使用した画像処理サービス
/// actor で非同期処理を分離し、スレッドセーフな画像処理を提供
actor ImageProcessingService {
    // MARK: - Properties

    /// CIContextのインスタンス（再利用して効率化）
    private let context: CIContext

    // MARK: - Initializer

    init() {
        // Metal対応デバイスでパフォーマンス向上
        if let device = MTLCreateSystemDefaultDevice() {
            context = CIContext(mtlDevice: device)
        } else {
            context = CIContext()
        }
    }

    // MARK: - Public Methods

    /// 画像に調整を適用
    func applyAdjustments(to image: UIImage, adjustment: ImageAdjustment) -> UIImage? {
        guard let inputImage = CIImage(image: image) else { return nil }

        var currentImage = inputImage

        // 明るさ・コントラスト・彩度を適用
        if let colorControls = applyColorControls(
            to: currentImage,
            brightness: adjustment.brightness,
            contrast: adjustment.contrast,
            saturation: adjustment.saturation
        ) {
            currentImage = colorControls
        }

        // 露出を適用
        if adjustment.exposure != 0 {
            if let exposureImage = applyExposure(to: currentImage, value: adjustment.exposure) {
                currentImage = exposureImage
            }
        }

        // シャープネスを適用
        if adjustment.sharpness > 0 {
            if let sharpImage = applySharpness(to: currentImage, value: adjustment.sharpness) {
                currentImage = sharpImage
            }
        }

        // ハイライト・シャドウを適用
        if adjustment.highlights != 0 || adjustment.shadows != 0 {
            if let highlightShadowImage = applyHighlightShadow(
                to: currentImage,
                highlights: adjustment.highlights,
                shadows: adjustment.shadows
            ) {
                currentImage = highlightShadowImage
            }
        }

        return createUIImage(from: currentImage)
    }

    /// フィルターを適用
    func applyFilter(to image: UIImage, filter: FilterPreset, intensity: Double = 1.0) -> UIImage? {
        guard filter != .none else { return image }
        guard let inputImage = CIImage(image: image) else { return nil }

        let filteredImage: CIImage?

        switch filter {
        case .none:
            return image

        case .sepia:
            filteredImage = applySepia(to: inputImage, intensity: intensity)

        case .noir:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectNoir")

        case .vintage:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectInstant")

        case .vivid:
            filteredImage = applyVivid(to: inputImage, intensity: intensity)

        case .dramatic:
            filteredImage = applyDramatic(to: inputImage)

        case .mono:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectMono")

        case .tonal:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectTonal")

        case .fade:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectFade")

        case .chrome:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectChrome")

        case .process:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectProcess")

        case .transfer:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectTransfer")

        case .blur:
            filteredImage = applyBlur(to: inputImage, radius: intensity)

        case .pixellate:
            filteredImage = applyPixellate(to: inputImage, scale: intensity)
        }

        guard let outputImage = filteredImage else { return nil }
        return createUIImage(from: outputImage)
    }

    /// クロップ・回転を適用
    func applyCropAndRotation(to image: UIImage, settings: CropSettings) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        var currentImage = image

        // 回転を適用
        if settings.rotationAngle != 0 {
            currentImage = rotateImage(currentImage, angle: settings.rotationAngle) ?? currentImage
        }

        // 反転を適用
        if settings.isFlippedHorizontally {
            currentImage = flipImage(currentImage, horizontal: true) ?? currentImage
        }
        if settings.isFlippedVertically {
            currentImage = flipImage(currentImage, horizontal: false) ?? currentImage
        }

        // クロップを適用
        if settings.cropRect != CGRect(x: 0, y: 0, width: 1, height: 1) {
            currentImage = cropImage(currentImage, rect: settings.cropRect) ?? currentImage
        }

        return currentImage
    }

    /// プレビュー用にリサイズ
    func resizeForPreview(_ image: UIImage, targetSize: CGSize = CGSize(width: 300, height: 300)) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// すべての編集を適用（調整 + フィルター + クロップ）
    func applyAllEdits(
        to image: UIImage,
        adjustment: ImageAdjustment,
        filterSettings: FilterSettings,
        cropSettings: CropSettings
    ) -> UIImage? {
        var result = image

        // 1. クロップ・回転を適用
        if !cropSettings.isDefault {
            result = applyCropAndRotation(to: result, settings: cropSettings) ?? result
        }

        // 2. 調整を適用
        if !adjustment.isDefault {
            result = applyAdjustments(to: result, adjustment: adjustment) ?? result
        }

        // 3. フィルターを適用
        if !filterSettings.isDefault {
            result = applyFilter(to: result, filter: filterSettings.preset, intensity: filterSettings.intensity) ?? result
        }

        return result
    }

    // MARK: - Private Methods - Filters

    private func applyColorControls(
        to image: CIImage,
        brightness: Double,
        contrast: Double,
        saturation: Double
    ) -> CIImage? {
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter?.setValue(contrast, forKey: kCIInputContrastKey)
        filter?.setValue(saturation, forKey: kCIInputSaturationKey)
        return filter?.outputImage
    }

    private func applyExposure(to image: CIImage, value: Double) -> CIImage? {
        let filter = CIFilter(name: "CIExposureAdjust")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(value, forKey: kCIInputEVKey)
        return filter?.outputImage
    }

    private func applySharpness(to image: CIImage, value: Double) -> CIImage? {
        let filter = CIFilter(name: "CISharpenLuminance")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(value * 2.0, forKey: kCIInputSharpnessKey)
        return filter?.outputImage
    }

    private func applyHighlightShadow(to image: CIImage, highlights: Double, shadows: Double) -> CIImage? {
        let filter = CIFilter(name: "CIHighlightShadowAdjust")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(1.0 - highlights, forKey: "inputHighlightAmount")
        filter?.setValue(shadows + 1.0, forKey: "inputShadowAmount")
        return filter?.outputImage
    }

    private func applySepia(to image: CIImage, intensity: Double) -> CIImage? {
        let filter = CIFilter(name: "CISepiaTone")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(intensity, forKey: kCIInputIntensityKey)
        return filter?.outputImage
    }

    private func applyPhotoEffect(to image: CIImage, filterName: String) -> CIImage? {
        let filter = CIFilter(name: filterName)
        filter?.setValue(image, forKey: kCIInputImageKey)
        return filter?.outputImage
    }

    private func applyVivid(to image: CIImage, intensity: Double) -> CIImage? {
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(0, forKey: kCIInputBrightnessKey)
        filter?.setValue(1.1, forKey: kCIInputContrastKey)
        filter?.setValue(intensity, forKey: kCIInputSaturationKey)
        return filter?.outputImage
    }

    private func applyDramatic(to image: CIImage) -> CIImage? {
        // コントラストを上げてドラマチックな効果
        var currentImage = image

        let contrastFilter = CIFilter(name: "CIColorControls")
        contrastFilter?.setValue(currentImage, forKey: kCIInputImageKey)
        contrastFilter?.setValue(1.3, forKey: kCIInputContrastKey)
        contrastFilter?.setValue(0.9, forKey: kCIInputSaturationKey)

        if let output = contrastFilter?.outputImage {
            currentImage = output
        }

        // ビネット効果を追加
        let vignetteFilter = CIFilter(name: "CIVignette")
        vignetteFilter?.setValue(currentImage, forKey: kCIInputImageKey)
        vignetteFilter?.setValue(0.5, forKey: kCIInputIntensityKey)
        vignetteFilter?.setValue(1.5, forKey: kCIInputRadiusKey)

        return vignetteFilter?.outputImage ?? currentImage
    }

    private func applyBlur(to image: CIImage, radius: Double) -> CIImage? {
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)

        // ブラー後のエッジをクロップ
        guard let output = filter?.outputImage else { return nil }
        return output.cropped(to: image.extent)
    }

    private func applyPixellate(to image: CIImage, scale: Double) -> CIImage? {
        let filter = CIFilter(name: "CIPixellate")
        filter?.setValue(image, forKey: kCIInputImageKey)
        filter?.setValue(scale, forKey: kCIInputScaleKey)
        return filter?.outputImage
    }

    // MARK: - Private Methods - Transform

    private func rotateImage(_ image: UIImage, angle: Double) -> UIImage? {
        let radians = angle * .pi / 180
        var newSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .size
        newSize = CGSize(width: floor(newSize.width), height: floor(newSize.height))

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            cgContext.rotate(by: radians)
            image.draw(in: CGRect(
                x: -image.size.width / 2,
                y: -image.size.height / 2,
                width: image.size.width,
                height: image.size.height
            ))
        }
    }

    private func flipImage(_ image: UIImage, horizontal: Bool) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            let cgContext = context.cgContext

            if horizontal {
                cgContext.translateBy(x: image.size.width, y: 0)
                cgContext.scaleBy(x: -1, y: 1)
            } else {
                cgContext.translateBy(x: 0, y: image.size.height)
                cgContext.scaleBy(x: 1, y: -1)
            }

            image.draw(at: .zero)
        }
    }

    private func cropImage(_ image: UIImage, rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        let cropRect = CGRect(
            x: rect.origin.x * imageWidth,
            y: rect.origin.y * imageHeight,
            width: rect.width * imageWidth,
            height: rect.height * imageHeight
        )

        guard let croppedCGImage = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Private Methods - Utility

    private func createUIImage(from ciImage: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
