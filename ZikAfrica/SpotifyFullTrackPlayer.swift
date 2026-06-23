import Foundation

@MainActor
final class SpotifyFullTrackPlayer {
    static let shared = SpotifyFullTrackPlayer()

    private init() {}

    func play(track: Track) async -> Bool {
        #if canImport(SpotifyiOS)
        return await playWithSpotifySDK(track: track)
        #else
        return false
        #endif
    }

    func stop() {
        #if canImport(SpotifyiOS)
        stopSpotifySDK()
        #endif
    }
}

#if canImport(SpotifyiOS)
import SpotifyiOS

extension SpotifyFullTrackPlayer {
    private func playWithSpotifySDK(track: Track) async -> Bool {
        // Spotify App Remote sera branché ici dès que l'app Spotify Developer
        // fournit un client ID et un redirect URI valides pour ZikAfrica.
        !track.spotifyUri.isEmpty
    }

    private func stopSpotifySDK() {
        // Prévu pour pause/stop via App Remote une fois le SDK activé.
    }
}
#endif
