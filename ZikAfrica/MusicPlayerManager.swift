import UIKit

class MusicPlayerManager {

    static func play(
        track: Track,
        platform: MusicPlatform,
        completion: ((Bool) -> Void)? = nil
    ) {
        switch platform {
        case .spotify:
            openSpotify(uri: track.spotifyUri, completion: completion)

        case .appleMusic:
            completion?(false)

        case .deezer:
            openDeezer(id: track.deezerId, completion: completion)
        }
    }

    private static func openSpotify(
        uri: String,
        completion: ((Bool) -> Void)?
    ) {
        guard !uri.isEmpty,
              let url = URL(string: uri)
        else {
            completion?(false)
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: completion)
    }

    private static func openDeezer(
        id: String,
        completion: ((Bool) -> Void)?
    ) {
        guard !id.isEmpty,
              let url = URL(string: "deezer://www.deezer.com/track/\(id)")
        else {
            completion?(false)
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: completion)
    }
}
