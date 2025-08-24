import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

class ImageFilterService {
    private let context = CIContext()
    
    func applyFilter(_ filterType: FilterType, to image: UIImage, intensity: Double = 1.0) -> UIImage? {
        guard let inputImage = CIImage(image: image) else {
            return nil
        }
        
        let filteredImage: CIImage?
        
        switch filterType {
        case .none:
            filteredImage = inputImage
        case .sepia:
            filteredImage = applySepia(to: inputImage, intensity: intensity)
        case .noir:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectNoir")
        case .vintage:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectInstant")
        case .vivid:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectVivid")
        case .dramatic:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectDramatic")
        case .mono:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectMono")
        case .tonal:
            filteredImage = applyPhotoEffect(to: inputImage, filterName: "CIPhotoEffectTonal")
        }
        
        guard let outputImage = filteredImage else {
            return nil
        }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func applySepia(to inputImage: CIImage, intensity: Double) -> CIImage? {
        let filter = CIFilter(name: "CISepiaTone")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter?.setValue(intensity, forKey: kCIInputIntensityKey)
        return filter?.outputImage
    }
    
    private func applyPhotoEffect(to inputImage: CIImage, filterName: String) -> CIImage? {
        let filter = CIFilter(name: filterName)
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        return filter?.outputImage
    }
}

extension ImageFilterService {
    func createFilterPreview(_ filterType: FilterType, sourceImage: UIImage, previewSize: CGSize = CGSize(width: 150, height: 150)) -> UIImage? {
        let resizedImage = resizeImageForPreview(sourceImage, targetSize: previewSize)
        return applyFilter(filterType, to: resizedImage, intensity: 1.0)
    }
    
    private func resizeImageForPreview(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
}