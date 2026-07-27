import Foundation

@MainActor
final class SpotifyFullTrackPlayer: NSObject {
    static let shared = SpotifyFullTrackPlayer()

    private let clientID = "c8b5fc05287f43f1af8848cc562a7079"
    private let redirectURL = URL(string: "zikafrica://spotify-callback")!
    private let accessTokenKey = "zikafrica.spotify.accessToken"

    private override init() {}

    /// Préchauffage : à appeler dès le lancement de ZikAfrica. Si un token d'une
    /// autorisation précédente est déjà stocké, tente une connexion silencieuse
    /// (sans bascule vers l'app Spotify) pendant que le joueur est encore sur l'écran
    /// d'accueil, pour que le premier scan de la session tombe déjà sur une connexion
    /// prête. Sans effet s'il n'y a pas de token stocké ou si déjà connecté.
    func warmUp() {
        #if canImport(SpotifyiOS)
        warmUpSDK()
        #endif
    }

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

    /// Boîte de rangement pour la continuation d'une connexion silencieuse en cours,
    /// le cas échéant. Un simple objet de référence, pour rester dans le même schéma
    /// d'associated object que "appRemote" ci-dessus — un type valeur générique comme
    /// CheckedContinuation ne s'y prête pas de façon fiable.
    private var connectionBox: SpotifyConnectionBox {
        if let existing = objc_getAssociatedObject(self, &AssociatedKeys.connectionBox) as? SpotifyConnectionBox {
            return existing
        }

        let box = SpotifyConnectionBox()
        objc_setAssociatedObject(self, &AssociatedKeys.connectionBox, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return box
    }

    private func warmUpSDK() {
        guard let token = accessToken, !token.isEmpty,
              !appRemote.isConnected,
              connectionBox.continuation == nil else {
            return
        }

        appRemote.connectionParameters.accessToken = token
        Task {
            _ = await connectSilently()
        }
    }

    private func playWithSpotifySDK(uri: String) async -> Bool {
        if appRemote.isConnected {
            return await playConnected(uri: uri)
        }

        if let token = accessToken, !token.isEmpty, connectionBox.continuation == nil {
            appRemote.connectionParameters.accessToken = token
            if await connectSilently() {
                return await playConnected(uri: uri)
            }
            // Le token stocké a expiré ou la connexion silencieuse a échoué : on
            // retombe sur l'autorisation complète ci-dessous (seule vraie bascule
            // ponctuelle vers Spotify, comme au tout premier lancement).
        }

        return await withCheckedContinuation { continuation in
            appRemote.authorizeAndPlayURI(uri) { success in
                continuation.resume(returning: success)
            }
        }
    }

    /// Tentative de connexion SANS passer par l'écran d'autorisation Spotify (pas de
    /// bascule d'app). Ne fonctionne que s'il existe déjà un token valide.
    private func connectSilently() async -> Bool {
        guard connectionBox.continuation == nil else { return false }

        return await withCheckedContinuation { continuation in
            connectionBox.continuation = continuation
            appRemote.connect()
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
        connectionBox.continuation?.resume(returning: true)
        connectionBox.continuation = nil
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Spotify App Remote connection failed: \(error?.localizedDescription ?? "Unknown error")")
        connectionBox.continuation?.resume(returning: false)
        connectionBox.continuation = nil
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Spotify App Remote disconnected: \(error?.localizedDescription ?? "No error")")
    }
}

/// Simple objet de référence pour porter la continuation d'une connexion silencieuse
/// en cours — voir "connectionBox" ci-dessus.
private final class SpotifyConnectionBox {
    var continuation: CheckedContinuation<Bool, Never>?
}

private enum AssociatedKeys {
    static var appRemote = "zikafrica.spotify.appRemote"
    static var connectionBox = "zikafrica.spotify.connectionBox"
}
#endif
