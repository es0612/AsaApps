//
//  AsaFamilyAlbumApp.swift
//  AsaFamilyAlbum
//
//  Created on 2025/09/05
//

import SwiftUI
import SwiftData

@main
struct AsaFamilyAlbumApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Album.self, Photo.self, Comment.self, FamilyMember.self])
        }
    }
}

