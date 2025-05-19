//
//  ContentView.swift
//  SwiftUITutorial-Day23
//  
//  Created on 2025/05/19
//


import SwiftUI

struct ContentView: View {
    @State private var currentPage = 0
    let pages = [Text("Page 1"), Text("Page 2"), Text("Page 3")]

    var body: some View {
        VStack {
            PageViewController(pages: pages.map { PageView(view: $0) }, currentPage: $currentPage)
                .frame(height: 200)
            Text("Current Page: \(currentPage + 1)")
        }
    }
}

#Preview {
    ContentView()
}
