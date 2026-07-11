//
//  ZikAfricaApp.swift
//  ZikAfrica
//
//  Created by Valérien YEHOUENOU on 09/06/2026.
//

import SwiftUI
import FirebaseCore

@main
struct ZikAfricaApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    SpotifyFullTrackPlayer.shared.handleOpenURL(url)
                }
        }
    }
}
