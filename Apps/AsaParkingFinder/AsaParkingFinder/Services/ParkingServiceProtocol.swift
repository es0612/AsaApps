//
//  ParkingServiceProtocol.swift
//  AsaParkingFinder
//  
//  駐車場検索サービスの抽象化インターフェース
//

import Foundation
import CoreLocation

// MARK: - ParkingServiceProtocol

protocol ParkingServiceProtocol {
    
    /// 指定した地点周辺の駐車場を検索
    /// - Parameters:
    ///   - center: 検索中心座標
    ///   - radius: 検索半径（メートル）
    ///   - filter: 検索フィルター
    /// - Returns: 駐車場リスト
    func searchParking(
        center: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        filter: SearchFilter?
    ) async throws -> [ParkingLot]
    
    /// 駐車場の詳細情報を取得
    /// - Parameter id: 駐車場ID
    /// - Returns: 駐車場詳細情報
    func getParkingDetail(id: String) async throws -> ParkingLot?
    
    /// お気に入り駐車場の管理
    /// - Parameter ids: 駐車場IDリスト
    /// - Returns: お気に入り駐車場リスト
    func getFavoriteParkingLots(ids: [String]) async throws -> [ParkingLot]
    
    /// 駐車場の空き状況を更新
    /// - Parameter id: 駐車場ID
    /// - Returns: 更新された駐車場情報
    func updateAvailability(id: String) async throws -> ParkingLot?
}

// MARK: - ParkingServiceError

enum ParkingServiceError: LocalizedError {
    case networkError(String)
    case invalidCoordinates
    case noDataFound
    case apiLimitExceeded
    case invalidResponse
    case unauthorized
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "ネットワークエラー: \(message)"
        case .invalidCoordinates:
            return "無効な座標が指定されました"
        case .noDataFound:
            return "指定した条件の駐車場が見つかりません"
        case .apiLimitExceeded:
            return "API使用制限に達しました。しばらく時間をおいて再試行してください"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .unauthorized:
            return "API認証に失敗しました"
        case .serverError(let code):
            return "サーバーエラーが発生しました（コード: \(code)）"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "インターネット接続を確認してください"
        case .invalidCoordinates:
            return "位置情報を再取得してください"
        case .noDataFound:
            return "検索条件を変更するか、範囲を広げてください"
        case .apiLimitExceeded:
            return "しばらく時間をおいてから再試行してください"
        case .invalidResponse, .serverError:
            return "アプリを再起動するか、しばらく時間をおいてください"
        case .unauthorized:
            return "アプリを再インストールしてください"
        }
    }
}

// MARK: - ParkingServiceType

enum ParkingServiceType: String, CaseIterable {
    case mock = "モックデータ"
    case navitime = "NAVITIME API"
    case pppark = "PPPark API"
    case googlePlaces = "Google Places API"
    
    var requiresApiKey: Bool {
        switch self {
        case .mock:
            return false
        case .navitime, .pppark, .googlePlaces:
            return true
        }
    }
    
    var hasRealTimeData: Bool {
        switch self {
        case .mock:
            return false
        case .navitime, .pppark:
            return true
        case .googlePlaces:
            return false
        }
    }
}