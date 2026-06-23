import UIKit

class MusicAppDetector {
    static func isAppleMusicInstalled() -> Bool {
        guard let url = URL(string: "music://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    static func isSpotifyInstalled() -> Bool {
        guard let url = URL(string: "spotify://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    static func isDeezerInstalled() -> Bool {
        guard let url = URL(string: "deezer://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}
