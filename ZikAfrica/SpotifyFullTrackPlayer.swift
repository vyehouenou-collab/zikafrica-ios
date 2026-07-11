import Foundation

@MainActor
final class SpotifyFullTrackPlayer: NSObject {
    static let shared = SpotifyFullTrackPlayer()

    private let clientID = "c8b5fc05287f43f1af8848cc562a7079"
    private let redirectURL = URL(string: "zikafrica://spotify-callback")!
    private let accessTokenKey = "zikafrica.spotify.accessToken"

    private override init() {}

    func play(track: Track) async -> Bool {
        guard !track.spotifyUri.isEmpty else { return false }

        #if canImport(SpotifyiOS)
        return await playWithSpotifySDK(uri: track.spotifyUri)
        #else
        return false
        #endif
    }

    func stop() {
        #if canImport(SpotifyiOS)
        stopSpotifySDK()
        #endif
    }

    func handleOpenURL(_ url: URL) {
        #if canImport(SpotifyiOS)
        handleSpotifyCallback(url)
        #endif
    }
}

#if canImport(SpotifyiOS)
import ObjectiveC
import SpotifyiOS

extension SpotifyFullTrackPlayer {
    private var accessToken: String? {
        get {
            UserDefaults.standard.string(forKey: accessTokenKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: accessTokenKey)
            appRemote.connectionParameters.accessToken = newValue
        }
    }

    private var configuration: SPTConfiguration {
        SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
    }

    private var appRemote: SPTAppRemote {
        if let existingRemote = objc_getAssociatedObject(self, &AssociatedKeys.appRemote) as? SPTAppRemote {
            return existingRemote
        }

        let remote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        remote.delegate = self
        remote.connectionParameters.accessToken = accessToken
        objc_setAssociatedObject(self, &AssociatedKeys.appRemote, remote, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return remote
    }

    private func playWithSpotifySDK(uri: String) async -> Bool {
        if appRemote.isConnected {
            return await playConnected(uri: uri)
        }

        appRemote.connectionParameters.accessToken = accessToken

        return await withCheckedContinuation { continuation in
            appRemote.authorizeAndPlayURI(uri) { success in
                continuation.resume(returning: success)
            }
        }
    }

    private func playConnected(uri: String) async -> Bool {
        await withCheckedContinuation { continuation in
            appRemote.playerAPI?.play(uri) { _, error in
                continuation.resume(returning: error == nil)
            }
        }
    }

    private func stopSpotifySDK() {
        guard appRemote.isConnected else { return }
        appRemote.playerAPI?.pause { _, _ in }
    }

    private func handleSpotifyCallback(_ url: URL) {
        guard let parameters = appRemote.authorizationParameters(from: url) else { return }

        if let token = parameters[SPTAppRemoteAccessTokenKey] as? String {
            accessToken = token
            appRemote.connectionParameters.accessToken = token
            appRemote.connect()
        } else if let errorDescription = parameters[SPTAppRemoteErrorDescriptionKey] {
            print("Spotify App Remote authorization failed: \(errorDescription)")
        }
    }
}

extension SpotifyFullTrackPlayer: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("Spotify App Remote connected")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Spotify App Remote connection failed: \(error?.localizedDescription ?? "Unknown error")")
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Spotify App Remote disconnected: \(error?.localizedDescription ?? "No error")")
    }
}

private enum AssociatedKeys {
    static var appRemote = "zikafrica.spotify.appRemote"
}
#endif
