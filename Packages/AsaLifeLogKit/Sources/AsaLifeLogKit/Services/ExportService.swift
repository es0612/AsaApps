import Foundation

// MARK: - ExportService

/// ライフログデータのエクスポートサービス
///
/// JSON / CSV 形式でエントリーをエクスポートする。
@MainActor
@Observable
public final class ExportService {

    // MARK: - Init

    public init() {}

    // MARK: - JSON エクスポート

    /// エントリーを JSON データとしてエクスポートする
    public func exportAsJSON(entries: [LifeLogEntry]) throws -> Data {
        let exportItems = entries.map { ExportableEntry(from: $0) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            return try encoder.encode(exportItems)
        } catch {
            throw LifeLogError.exportFailed
        }
    }

    // MARK: - CSV エクスポート

    /// エントリーを CSV データとしてエクスポートする
    public func exportAsCSV(entries: [LifeLogEntry]) throws -> Data {
        var lines: [String] = []

        // ヘッダー行
        let header = [
            "日時", "種別", "タイトル", "内容", "気分",
            "タグ", "場所", "ソース", "お気に入り",
        ].joined(separator: ",")
        lines.append(header)

        // データ行
        let formatter = ISO8601DateFormatter()
        for entry in entries {
            let fields = [
                formatter.string(from: entry.timestamp),
                entry.entryType.displayName,
                escapeCSV(entry.title),
                escapeCSV(entry.content ?? ""),
                entry.moodScore?.displayName ?? "",
                escapeCSV(entry.tags.joined(separator: ";")),
                escapeCSV(entry.locationName ?? ""),
                entry.source.displayName,
                entry.isFavorite ? "はい" : "いいえ",
            ]
            lines.append(fields.joined(separator: ","))
        }

        guard let data = lines.joined(separator: "\n").data(using: .utf8) else {
            throw LifeLogError.exportFailed
        }
        return data
    }

    // MARK: - Private

    /// CSV 用のエスケープ処理
    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
}

// MARK: - ExportableEntry

/// エクスポート用のエントリー構造体
private struct ExportableEntry: Codable, Sendable {
    let id: UUID
    let timestamp: Date
    let entryType: String
    let title: String
    let content: String?
    let moodScore: String?
    let tags: [String]
    let locationName: String?
    let source: String
    let isFavorite: Bool

    init(from entry: LifeLogEntry) {
        self.id = entry.id
        self.timestamp = entry.timestamp
        self.entryType = entry.entryType.rawValue
        self.title = entry.title
        self.content = entry.content
        self.moodScore = entry.moodScore?.rawValue
        self.tags = entry.tags
        self.locationName = entry.locationName
        self.source = entry.source.rawValue
        self.isFavorite = entry.isFavorite
    }
}
