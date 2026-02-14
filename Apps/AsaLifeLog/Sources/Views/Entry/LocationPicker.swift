import SwiftUI

// MARK: - LocationPicker

/// 位置情報選択ビュー
struct LocationPicker: View {
    @Binding var locationName: String?
    var onRequestLocation: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .foregroundStyle(.red)

            if let name = locationName {
                Text(name)
                    .font(.subheadline)

                Button {
                    locationName = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            } else {
                Button("現在地を取得") {
                    onRequestLocation()
                }
                .font(.subheadline)
            }
        }
    }
}
