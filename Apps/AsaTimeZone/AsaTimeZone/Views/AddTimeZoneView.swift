import SwiftUI
import AsaUIKit

struct AddTimeZoneView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TimeZoneViewModel.self) private var viewModel
    @State private var searchText = ""
    @State private var selectedTimeZone: TimeZoneItem?

    private let popularTimeZones = [
        TimeZoneItem(identifier: "Asia/Tokyo", cityName: "東京", countryName: "日本"),
        TimeZoneItem(identifier: "Asia/Seoul", cityName: "ソウル", countryName: "韓国"),
        TimeZoneItem(identifier: "Asia/Shanghai", cityName: "上海", countryName: "中国"),
        TimeZoneItem(identifier: "Asia/Singapore", cityName: "シンガポール", countryName: "シンガポール"),
        TimeZoneItem(identifier: "Asia/Dubai", cityName: "ドバイ", countryName: "UAE"),
        TimeZoneItem(identifier: "Europe/London", cityName: "ロンドン", countryName: "イギリス"),
        TimeZoneItem(identifier: "Europe/Paris", cityName: "パリ", countryName: "フランス"),
        TimeZoneItem(identifier: "Europe/Berlin", cityName: "ベルリン", countryName: "ドイツ"),
        TimeZoneItem(identifier: "Europe/Rome", cityName: "ローマ", countryName: "イタリア"),
        TimeZoneItem(identifier: "Europe/Moscow", cityName: "モスクワ", countryName: "ロシア"),
        TimeZoneItem(identifier: "America/New_York", cityName: "ニューヨーク", countryName: "アメリカ"),
        TimeZoneItem(identifier: "America/Los_Angeles", cityName: "ロサンゼルス", countryName: "アメリカ"),
        TimeZoneItem(identifier: "America/Chicago", cityName: "シカゴ", countryName: "アメリカ"),
        TimeZoneItem(identifier: "America/Toronto", cityName: "トロント", countryName: "カナダ"),
        TimeZoneItem(identifier: "America/Mexico_City", cityName: "メキシコシティ", countryName: "メキシコ"),
        TimeZoneItem(identifier: "America/Sao_Paulo", cityName: "サンパウロ", countryName: "ブラジル"),
        TimeZoneItem(identifier: "Australia/Sydney", cityName: "シドニー", countryName: "オーストラリア"),
        TimeZoneItem(identifier: "Pacific/Auckland", cityName: "オークランド", countryName: "ニュージーランド"),
        TimeZoneItem(identifier: "Pacific/Honolulu", cityName: "ホノルル", countryName: "ハワイ"),
    ]

    private var filteredTimeZones: [TimeZoneItem] {
        if searchText.isEmpty {
            return popularTimeZones
        } else {
            return popularTimeZones.filter {
                $0.cityName.localizedCaseInsensitiveContains(searchText) ||
                $0.countryName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTimeZones) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.cityName)
                                .font(.headline)
                                .foregroundColor(AsaColors.darkSlate)

                            Text(item.countryName)
                                .font(.caption)
                                .foregroundColor(AsaColors.mutedSage)
                        }

                        Spacer()

                        Text(item.offset)
                            .font(.caption)
                            .foregroundColor(AsaColors.mutedSage)

                        if viewModel.timeZoneItems.contains(where: { $0.identifier == item.identifier }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AsaColors.coffeeBrown)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !viewModel.timeZoneItems.contains(where: { $0.identifier == item.identifier }) {
                            viewModel.addTimeZone(item)
                            dismiss()
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "都市名で検索")
            .navigationTitle("タイムゾーンを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
    }
}