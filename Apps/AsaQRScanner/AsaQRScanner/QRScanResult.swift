//
//  QRScanResult.swift
//  AsaQRScanner
//  
//  Created on 2025/07/15
//

import Foundation
import SwiftData

@Model
final class QRScanResult {
    var content: String
    var timestamp: Date
    var scanType: String
    
    init(content: String, timestamp: Date = Date(), scanType: String = "QR") {
        self.content = content
        self.timestamp = timestamp
        self.scanType = scanType
    }
}
