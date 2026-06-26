import Foundation
import MediaPlayer
import StoreKit

@MainActor
final class AppleMusicFullTrackPlayer {
    static let shared = AppleMusicFullTrackPlayer()

    private let player = MPMusicPlayerController.applicationMusicPlayer
    private let storefrontCountries: [String: String] = [
        "143442": "FR",
        "143441": "US",
        "143444": "GB",
        "143455": "CA",
        "143460": "AU",
        "143564": "CI",
        "143484": "SN",
        "143471": "GH",
        "143561": "NG",
        "143565": "BJ",
        "143566": "CM",
        "143573": "TG"
    ]

    private init() {}

    func play(track: Track) async -> Bool {
        guard await requestAuthorization() else {
            return false
        }

        guard await canPlayAppleMusicCatalog() else {
            return false
        }

        let storeId = await resolveStoreId(for: track)
        guard !storeId.isEmpty else {
            return false
        }

        player.setQueue(with: [storeId])
        player.play()
        return true
    }

    func stop() {
        player.stop()
    }

    private func canPlayAppleMusicCatalog() async -> Bool {
        await withCheckedContinuation { continuation in
            SKCloudServiceController().requestCapabilities { capabilities, error in
                if let error {
                    print("Apple Music indisponible :", error)
                    continuation.resume(returning: false)
                    return
                }

                continuation.resume(returning: capabilities.contains(.musicCatalogPlayback))
            }
        }
    }

    private func requestAuthorization() async -> Bool {
        let currentStatus = MPMediaLibrary.authorizationStatus()
        if currentStatus == .authorized {
            return true
        }

        return await withCheckedContinuation { continuation in
            MPMediaLibrary.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func resolveStoreId(for track: Track) async -> String {
        if !track.appleMusicId.isEmpty {
            return track.appleMusicId
        }

        do {
            return try await searchAppleMusicStoreId(track: track)
        } catch {
            print("Recherche Apple Music impossible :", error)
            return ""
        }
    }

    private func searchAppleMusicStoreId(track: Track) async throws -> String {
        let countries = await appleMusicSearchCountries()
        let terms = searchTerms(for: track)

        for country in countries {
            for term in terms {
                let response = try await searchAppleMusic(term: term, country: country)

                if let bestMatch = bestAppleMusicMatch(in: response.results, for: track) {
                    return String(bestMatch.trackId)
                }
            }
        }

        return ""
    }

    private func searchAppleMusic(term: String, country: String) async throws -> AppleMusicSearchResponse {
        var components = URLComponents(string: "https://itunes.apple.com/search")
        components?.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "limit", value: "10")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(AppleMusicSearchResponse.self, from: data)
    }

    private func bestAppleMusicMatch(in results: [AppleMusicSearchResult], for track: Track) -> AppleMusicSearchResult? {
        let normalizedTitle = normalize(track.title)
        let relaxedTitle = relaxedNormalize(track.title)
        let normalizedArtist = normalize(track.artist)
        let relaxedArtist = relaxedNormalize(track.artist)

        if let exactMatch = results.first(where: { result in
            let resultTitle = normalize(result.trackName)
            let resultArtist = normalize(result.artistName)

            return (resultTitle.contains(normalizedTitle) || normalizedTitle.contains(resultTitle))
                && (resultArtist.contains(normalizedArtist) || normalizedArtist.contains(resultArtist))
        }) {
            return exactMatch
        }

        if let relaxedMatch = results.first(where: { result in
            let resultTitle = relaxedNormalize(result.trackName)
            let resultArtist = relaxedNormalize(result.artistName)

            return (resultTitle.contains(relaxedTitle) || relaxedTitle.contains(resultTitle))
                && (resultArtist.contains(relaxedArtist) || relaxedArtist.contains(resultArtist))
        }) {
            return relaxedMatch
        }

        if let artistMatch = results.first(where: { result in
            relaxedNormalize(result.artistName).contains(relaxedArtist)
        }) {
            return artistMatch
        }

        return nil
    }

    private func appleMusicSearchCountries() async -> [String] {
        var countries: [String] = []

        if let storefrontCountry = await storefrontCountryCode() {
            countries.append(storefrontCountry)
        }

        if let localeCountry = Locale.current.region?.identifier {
            countries.append(localeCountry.uppercased())
        }

        countries.append(contentsOf: ["FR", "CI", "CM", "SN", "BJ", "TG", "GH", "NG", "US"])
        return Array(NSOrderedSet(array: countries)).compactMap { $0 as? String }
    }

    private func storefrontCountryCode() async -> String? {
        await withCheckedContinuation { continuation in
            SKCloudServiceController().requestStorefrontIdentifier { [storefrontCountries] storefrontIdentifier, _ in
                let numericStorefront = storefrontIdentifier?
                    .components(separatedBy: ",")
                    .first ?? ""

                continuation.resume(returning: storefrontCountries[numericStorefront])
            }
        }
    }

    private func searchTerms(for track: Track) -> [String] {
        let title = track.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = track.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let simplifiedTitle = title
            .replacingOccurrences(of: "%", with: " ")
            .replacingOccurrences(of: "&", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && Int($0) == nil }
            .joined(separator: " ")

        return [
            "\(title) \(artist)",
            "\(simplifiedTitle) \(artist)",
            "\(artist) \(title)",
            "\(artist) \(simplifiedTitle)",
            title,
            simplifiedTitle
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .reduce(into: [String]()) { result, term in
            if !result.contains(term) {
                result.append(term)
            }
        }
    }

    private func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func relaxedNormalize(_ value: String) -> String {
        normalize(value)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && Int($0) == nil }
            .joined(separator: " ")
    }
}

private struct AppleMusicSearchResponse: Decodable {
    let results: [AppleMusicSearchResult]
}

private struct AppleMusicSearchResult: Decodable {
    let trackId: Int
    let trackName: String
    let artistName: String
}
