import Foundation

enum MusicPlatform: String, Identifiable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    case deezer = "Deezer"

    var id: String { rawValue }
}
