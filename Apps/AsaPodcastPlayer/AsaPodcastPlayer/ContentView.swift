//
//  ContentView.swift
//  AsaPodcastPlayer
//
//  Created by AsaPapa on 2025-10-21.
//

import SwiftUI
import AsaUIKit

struct ContentView: View {
    // MARK: - Properties

    @State private var viewModel = PodcastPlayerViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            PodcastLibraryView(viewModel: viewModel)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
