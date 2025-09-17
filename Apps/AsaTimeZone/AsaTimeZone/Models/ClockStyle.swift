import Foundation

enum ClockStyle: String, Codable {
    case analog
    case digital

    var displayName: String {
        switch self {
        case .analog:
            return "アナログ"
        case .digital:
            return "デジタル"
        }
    }

    mutating func toggle() {
        switch self {
        case .analog:
            self = .digital
        case .digital:
            self = .analog
        }
    }
}