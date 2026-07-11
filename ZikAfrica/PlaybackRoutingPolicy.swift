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
    static func fullTrackPlatforms(track: Track, installedApps: InstalledMusicApps) -> [MusicPlatform] {
        var platforms: [MusicPlatform] = []

        if installedApps.appleMusic {
            platforms.append(.appleMusic)
        }

        if installedApps.spotify, !track.spotifyUri.isEmpty {
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
        var result = fullTrackPlatforms(track: track, installedApps: installedApps)
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
