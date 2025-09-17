import SwiftUI
import AsaUIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TimeZoneViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section("表示設定") {
                    HStack {
                        Text("時計スタイル")
                        Spacer()
                        Picker("時計スタイル", selection: $viewModel.globalClockStyle) {
                            Text("アナログ").tag(ClockStyle.analog)
                            Text("デジタル").tag(ClockStyle.digital)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                    }

                    Button("すべての時計に適用") {
                        viewModel.toggleGlobalClockStyle()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }

                Section("タイムゾーン管理") {
                    if viewModel.timeZoneItems.isEmpty {
                        Text("タイムゾーンが登録されていません")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.timeZoneItems) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.cityName)
                                        .font(.headline)
                                    Text(item.countryName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(item.offset)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete(perform: viewModel.removeTimeZone)
                        .onMove(perform: viewModel.moveTimeZone)
                    }
                }

                Section("アプリ情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("登録可能タイムゾーン数")
                        Spacer()
                        Text("最大6個")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(AsaColors.coffeeBrown)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .foregroundColor(AsaColors.coffeeBrown)
                }
            }
        }
    }
}