import Foundation
import CoreData
import CoreLocation
import Combine
import UIKit

/// 位置情報取得エラー
enum LocationError: Error, LocalizedError {
    case alreadyRequesting
    case permissionDenied
    case unavailable
    
    var errorDescription: String? {
        switch self {
        case .alreadyRequesting:
            return "位置情報の取得が既に実行中です"
        case .permissionDenied:
            return "位置情報の使用が許可されていません"
        case .unavailable:
            return "位置情報が利用できません"
        }
    }
}

/// 天気履歴管理サービス
@MainActor
class WeatherHistoryService: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - Singleton
    static let shared = WeatherHistoryService()
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdateDate: Date?
    @Published var weatherRecords: [WeatherRecord] = []
    @Published var currentWeatherData: WeatherData?
    
    // MARK: - Private Properties
    private let coreDataStack = CoreDataStack.shared
    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    nonisolated(unsafe) private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    // 自動更新タイマー（6時間毎）
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 6 * 60 * 60 // 6時間
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupLocationManager()
        loadRecentRecords()
        setupAutoUpdate()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// 現在地の天気を取得して履歴に保存
    func fetchAndSaveCurrentWeather() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 現在地を取得
            let location = try await getCurrentLocation()
            
            // 天気データを取得
            let weatherData = try await weatherService.fetchWeather(for: location)
            
            // 履歴に保存
            await saveWeatherData(weatherData, location: (location.coordinate.latitude, location.coordinate.longitude))
            
            // UI更新
            currentWeatherData = weatherData
            lastUpdateDate = Date()
            
            print("✅ 天気データを取得・保存しました: \(weatherData.name) \(weatherData.temperatureString)")
            
        } catch {
            errorMessage = "天気データの取得に失敗しました: \(error.localizedDescription)"
            print("❌ 天気データ取得エラー: \(error)")
        }
        
        isLoading = false
    }
    
    /// 指定した場所の天気を取得して履歴に保存
    func fetchAndSaveWeather(for cityName: String) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let weatherData = try await weatherService.fetchWeather(for: cityName)
            
            // ジオコーディングで座標を取得（簡易実装）
            let location = try await getLocationCoordinates(for: cityName)
            
            await saveWeatherData(weatherData, location: location)
            
            currentWeatherData = weatherData
            lastUpdateDate = Date()
            
            print("✅ 指定場所の天気データを取得・保存しました: \(cityName)")
            
        } catch {
            errorMessage = "天気データの取得に失敗しました: \(error.localizedDescription)"
            print("❌ 指定場所の天気データ取得エラー: \(error)")
        }
        
        isLoading = false
    }
    
    /// 履歴レコードを読み込み
    func loadRecentRecords(limit: Int = 50) {
        weatherRecords = WeatherRecord.fetchLatest(limit: limit, in: coreDataStack.context)
        print("📊 \(weatherRecords.count)件の履歴レコードを読み込みました")
    }
    
    /// 指定期間の履歴レコードを取得
    func loadRecords(from startDate: Date, to endDate: Date) -> [WeatherRecord] {
        return WeatherRecord.fetchRecords(from: startDate, to: endDate, in: coreDataStack.context)
    }
    
    /// 今日の履歴レコードを取得
    func loadTodaysRecords() -> [WeatherRecord] {
        return WeatherRecord.fetchTodaysRecords(in: coreDataStack.context)
    }
    
    /// 古いレコードを削除
    func cleanupOldRecords(olderThan days: Int = 90) {
        coreDataStack.performBackgroundTask { context in
            WeatherRecord.deleteOldRecords(olderThan: days, in: context)
            
            DispatchQueue.main.async {
                self.loadRecentRecords()
            }
        }
    }
    
    /// データベースの統計情報を取得
    func getDatabaseStatistics() -> (totalRecords: Int, todaysRecords: Int, oldestRecord: Date?, newestRecord: Date?) {
        return coreDataStack.getDatabaseStats()
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupAutoUpdate() {
        // 6時間毎に自動更新
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            Task {
                await self.fetchAndSaveCurrentWeather()
            }
        }
        
        // アプリがフォアグラウンドに戻った時の更新
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { _ in
                Task {
                    // 最後の更新から1時間以上経過している場合のみ更新
                    if let lastUpdate = self.lastUpdateDate,
                       Date().timeIntervalSince(lastUpdate) > 3600 {
                        await self.fetchAndSaveCurrentWeather()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func getCurrentLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            // 既に位置情報取得中の場合はエラー
            guard locationContinuation == nil else {
                continuation.resume(throwing: LocationError.alreadyRequesting)
                return
            }
            
            // 位置情報の許可状態をチェック
            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                // 許可済みの場合、位置情報を取得
                locationContinuation = continuation
                locationManager.requestLocation()
                
            case .denied, .restricted:
                // 拒否されている場合、デフォルト位置（東京）を返す
                print("⚠️ 位置情報が拒否されているため、デフォルト位置（東京）を使用します")
                let defaultLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
                continuation.resume(returning: defaultLocation)
                
            case .notDetermined:
                // 未決定の場合、許可を要求してからデフォルト位置を返す
                locationManager.requestWhenInUseAuthorization()
                print("⚠️ 位置情報の許可が未決定のため、デフォルト位置（東京）を使用します")
                let defaultLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
                continuation.resume(returning: defaultLocation)
                
            @unknown default:
                // 未知の状態の場合、デフォルト位置を返す
                let defaultLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
                continuation.resume(returning: defaultLocation)
            }
        }
    }
    
    private func getLocationCoordinates(for cityName: String) async throws -> (latitude: Double, longitude: Double) {
        // 簡易的な都市名→座標変換
        let cityCoordinates: [String: (Double, Double)] = [
            "東京": (35.6762, 139.6503),
            "大阪": (34.6937, 135.5023),
            "名古屋": (35.1815, 136.9066),
            "京都": (35.0116, 135.7681),
            "神戸": (34.6901, 135.1956),
            "福岡": (33.5904, 130.4017),
            "札幌": (43.0642, 141.3469),
            "仙台": (38.2682, 140.8694),
            "広島": (34.3853, 132.4553),
            "金沢": (36.5944, 136.6256)
        ]
        
        if let coordinates = cityCoordinates[cityName] {
            return coordinates
        } else {
            return (35.6762, 139.6503) // デフォルトは東京
        }
    }
    
    private func saveWeatherData(_ weatherData: WeatherData, location: (latitude: Double, longitude: Double)) async {
        await MainActor.run {
            coreDataStack.performBackgroundTask { context in
                let _ = weatherData.saveToRecord(context: context, location: location)
                
                DispatchQueue.main.async {
                    self.loadRecentRecords()
                }
            }
        }
    }
}

// MARK: - Data Analysis Extensions
extension WeatherHistoryService {
    
    /// 温度推移データを取得（グラフ用）
    func getTemperatureTrend(days: Int = 7) -> [(Date, Double)] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let records = loadRecords(from: startDate, to: endDate)
        
        return records.map { ($0.recordDate, $0.temperature) }
            .sorted { $0.0 < $1.0 }
    }
    
    /// 天気統計を取得
    func getWeatherStatistics(days: Int = 30) -> [String: Int] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let records = loadRecords(from: startDate, to: endDate)
        
        var statistics: [String: Int] = [:]
        for record in records {
            let weatherType = record.weatherMain ?? "Unknown"
            statistics[weatherType, default: 0] += 1
        }
        
        return statistics
    }
    
    /// 平均気温を取得
    func getAverageTemperature(days: Int = 30) -> Double {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let records = loadRecords(from: startDate, to: endDate)
        
        guard !records.isEmpty else { return 0.0 }
        
        let totalTemperature = records.reduce(0.0) { $0 + $1.temperature }
        return totalTemperature / Double(records.count)
    }
    
    /// 最高・最低気温を取得
    func getTemperatureExtremes(days: Int = 30) -> (max: Double, min: Double)? {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let records = loadRecords(from: startDate, to: endDate)
        
        guard !records.isEmpty else { return nil }
        
        let temperatures = records.map { $0.temperature }
        return (max: temperatures.max() ?? 0, min: temperatures.min() ?? 0)
    }
}

// MARK: - LocationManager Delegate (簡易実装)
extension WeatherHistoryService {
    
    /// ユーザーの位置情報許可状態をチェック
    func checkLocationPermission() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    /// 位置情報の許可を要求
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    /// 位置情報取得成功時の処理
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
        
        print("✅ 位置情報を取得しました: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    /// 位置情報取得失敗時の処理
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
        
        print("❌ 位置情報取得エラー: \(error.localizedDescription)")
    }
    
    /// 位置情報許可状態変更時の処理（iOS 14以降）
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ 位置情報の使用が許可されました")
        case .denied, .restricted:
            print("❌ 位置情報の使用が拒否されました")
            // デフォルト位置（東京）を使用
            let defaultLocation = CLLocation(latitude: 35.6762, longitude: 139.6503)
            locationContinuation?.resume(returning: defaultLocation)
            locationContinuation = nil
        case .notDetermined:
            print("⏳ 位置情報の許可が未決定です")
        @unknown default:
            print("⚠️ 未知の位置情報許可状態です")
        }
    }
}