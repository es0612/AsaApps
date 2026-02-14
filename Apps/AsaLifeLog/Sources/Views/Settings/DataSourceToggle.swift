import SwiftUI

// MARK: - DataSourceToggle

/// データソースのON/OFFトグル
struct DataSourceToggle: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
            }
        }
    }
}
