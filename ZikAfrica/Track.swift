import Foundation

struct Track: Codable, Identifiable {
    var id: String { qrCode }

    let qrCode: String
    let title: String
    let artist: String
    let year: String
    let spotifyUri: String
    let deezerId: String
    let appleMusicId: String

    init(
        qrCode: String,
        title: String,
        artist: String,
        year: String,
        spotifyUri: String,
        deezerId: String,
        appleMusicId: String = ""
    ) {
        self.qrCode = qrCode
        self.title = title
        self.artist = artist
        self.year = year
        self.spotifyUri = spotifyUri
        self.deezerId = deezerId
        self.appleMusicId = appleMusicId
    }

    enum CodingKeys: String, CodingKey {
        case qrCode
        case title
        case artist
        case year
        case spotifyUri
        case deezerId
        case appleMusicId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        qrCode = try container.decode(String.self, forKey: .qrCode)
        title = try container.decode(String.self, forKey: .title)
        artist = try container.decode(String.self, forKey: .artist)
        year = try container.decode(String.self, forKey: .year)
        spotifyUri = try container.decodeIfPresent(String.self, forKey: .spotifyUri) ?? ""
        deezerId = try container.decodeIfPresent(String.self, forKey: .deezerId) ?? ""
        appleMusicId = try container.decodeIfPresent(String.self, forKey: .appleMusicId) ?? ""
    }
}
