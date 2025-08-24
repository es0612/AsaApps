import SwiftUI
import PhotosUI
import Photos

@Observable
class FilterViewModel {
    var selectedPhotoItem: PhotosPickerItem?
    var originalImage: UIImage?
    var filteredImage: UIImage?
    var selectedFilter: FilterType = .none
    var filterIntensity: Double = 1.0
    var isProcessing = false
    var showingSaveAlert = false
    var saveMessage = ""
    
    private let filterService = ImageFilterService()
    
    init() {
        loadSettings()
    }
    
    func loadImageFromPhotoItem() async {
        guard let selectedPhotoItem else { return }
        
        isProcessing = true
        
        do {
            if let imageData = try await selectedPhotoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: imageData) {
                
                await MainActor.run {
                    self.originalImage = image
                    self.applyCurrentFilter()
                }
            }
        } catch {
            print("画像の読み込みに失敗しました: \(error)")
        }
        
        isProcessing = false
    }
    
    func applyCurrentFilter() {
        guard let originalImage else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let intensity = self.selectedFilter.supportsIntensity ? self.filterIntensity : 1.0
            let result = self.filterService.applyFilter(self.selectedFilter, to: originalImage, intensity: intensity)
            
            DispatchQueue.main.async {
                self.filteredImage = result
                self.isProcessing = false
            }
        }
    }
    
    func updateFilter(_ newFilter: FilterType) {
        selectedFilter = newFilter
        saveSettings()
        applyCurrentFilter()
    }
    
    func updateIntensity(_ newIntensity: Double) {
        filterIntensity = newIntensity
        saveSettings()
        applyCurrentFilter()
    }
    
    func saveToPhotoLibrary() {
        guard let imageToSave = filteredImage ?? originalImage else {
            saveMessage = "保存する画像がありません"
            showingSaveAlert = true
            return
        }
        
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self?.performSave(imageToSave)
                case .denied, .restricted:
                    self?.saveMessage = "写真ライブラリへのアクセス許可が必要です"
                    self?.showingSaveAlert = true
                case .notDetermined:
                    self?.saveMessage = "写真ライブラリへのアクセス許可を確認してください"
                    self?.showingSaveAlert = true
                @unknown default:
                    self?.saveMessage = "不明なエラーが発生しました"
                    self?.showingSaveAlert = true
                }
            }
        }
    }
    
    private func performSave(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.saveMessage = "写真ライブラリに保存しました！"
                } else {
                    self?.saveMessage = "保存に失敗しました: \(error?.localizedDescription ?? "不明なエラー")"
                }
                self?.showingSaveAlert = true
            }
        }
    }
    
    func resetToOriginal() {
        selectedFilter = .none
        filterIntensity = 1.0
        filteredImage = originalImage
        saveSettings()
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(selectedFilter.rawValue, forKey: "selectedFilter")
        UserDefaults.standard.set(filterIntensity, forKey: "filterIntensity")
    }
    
    private func loadSettings() {
        if let filterRawValue = UserDefaults.standard.object(forKey: "selectedFilter") as? String,
           let savedFilter = FilterType(rawValue: filterRawValue) {
            selectedFilter = savedFilter
        }
        
        filterIntensity = UserDefaults.standard.object(forKey: "filterIntensity") as? Double ?? 1.0
    }
}