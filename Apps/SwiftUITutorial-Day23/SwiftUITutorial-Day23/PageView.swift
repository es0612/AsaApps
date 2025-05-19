import SwiftUI

struct PageView<Page: View>: View {
    var view: Page

    var body: some View {
        ZStack {
            Color.gray
            view
        }
    }
}
