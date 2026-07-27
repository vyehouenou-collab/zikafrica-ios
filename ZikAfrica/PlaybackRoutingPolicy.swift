import Foundation

struct InstalledMusicApps {
    let appleMusic: Bool
    let spotify: Bool
    let deezer: Bool

    static var current: InstalledMusicApps {
        InstalledMusicApps(
            appleMusic: MusicAppDetector.isAppleMusicInstalled(),
            spotify: MusicAppDetector.isSpotifyInstalled(),
            deezer: MusicAppDetector.isDeezerInstalled()
        )
    }
}

enum PlaybackAttempt: Equatable {
    case fullTrack(MusicPlatform)
    case deezerPreview
    case external(MusicPlatform)
}

struct PlaybackRoutingPolicy {
    static func fullTrackPlatforms(
        track: Track,
        installedApps: InstalledMusicApps,
        preferredPlatform: MusicPlatform? = nil
    ) -> [MusicPlatform] {
        let appleMusicAvailable = installedApps.appleMusic
        let spotifyAvailable = installedApps.spotify && !track.spotifyUri.isEmpty

        if preferredPlatform == .spotify && spotifyAvailable {
            // L'utilisateur a explicitement choisi Spotify : on respecte ce choix et on
            // le tente en premier. Apple Music reste en repli dans le même palier (avant
            // l'extrait Deezer) si Spotify échoue malgré tout pour cette carte.
            var platforms: [MusicPlatform] = [.spotify]
            if appleMusicAvailable {
                platforms.append(.appleMusic)
            }
            return platforms
        }

        // Ordre par défaut — inchangé pour "aucune préférence", "Apple Music" et
        // "Deezer" (Deezer n'a de toute façon pas de lecture complète, voir plus bas).
        var platforms: [MusicPlatform] = []

        if appleMusicAvailable {
            platforms.append(.appleMusic)
        }

        if spotifyAvailable {
            platforms.append(.spotify)
        }

        return platforms
    }

    static func externalFallbackPlatform(
        preferredPlatform: MusicPlatform?,
        track: Track,
        installedApps: InstalledMusicApps
    ) -> MusicPlatform? {
        if installedApps.spotify,
           canOpenExternally(platform: .spotify, track: track) {
            return .spotify
        }

        if installedApps.deezer,
           canOpenExternally(platform: .deezer, track: track) {
            return .deezer
        }

        return nil
    }

    static func attempts(
        preferredPlatform: MusicPlatform?,
        track: Track,
        installedApps: InstalledMusicApps
    ) -> [PlaybackAttempt] {
        var result = fullTrackPlatforms(
            track: track,
            installedApps: installedApps,
            preferredPlatform: preferredPlatform
        )
            .map { PlaybackAttempt.fullTrack($0) }

        result.append(.deezerPreview)

        if let externalPlatform = externalFallbackPlatform(
            preferredPlatform: preferredPlatform,
            track: track,
            installedApps: installedApps
        ) {
            result.append(.external(externalPlatform))
        }

        return result
    }

    private static func canOpenExternally(platform: MusicPlatform, track: Track) -> Bool {
        switch platform {
        case .spotify:
            return !track.spotifyUri.isEmpty
        case .deezer:
            return !track.deezerId.isEmpty
        case .appleMusic:
            return false
        }
    }
}
