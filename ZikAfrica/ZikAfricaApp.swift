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
    @StateObject private var localization = LocalizationManager.shared

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(localization.currentLanguage)
                .environment(\.layoutDirection, localization.currentLanguage.isRightToLeft ? .rightToLeft : .leftToRight)
                .onOpenURL { url in
                    SpotifyFullTrackPlayer.shared.handleOpenURL(url)
                }
        }
    }
}
