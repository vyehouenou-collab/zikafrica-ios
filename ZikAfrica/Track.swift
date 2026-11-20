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

// Country metadata is an optional hint; it never changes playback or card lookup.
extension Track {
    var countryCode: String? { Self.artistCountries[qrCode] }

    var countryFlag: String? {
        guard let code = countryCode, code.count == 2,
              code.unicodeScalars.allSatisfy({ (65...90).contains($0.value) }) else { return nil }
        return code.unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }.map(String.init).joined()
    }

    private static let artistCountries: [String: String] = {
        guard let url = Bundle.main.url(forResource: "tracks", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [:] }
        var result: [String: String] = [:]
        for row in rows {
            if let id = row["qrCode"] as? String, let code = row["artistCountryCode"] as? String {
                result[id] = code
            }
        }
        return result
    }()
}
