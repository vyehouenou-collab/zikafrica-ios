import Foundation
import MediaPlayer
import StoreKit

@MainActor
final class AppleMusicFullTrackPlayer {
    static let shared = AppleMusicFullTrackPlayer()

    private let player = MPMusicPlayerController.applicationMusicPlayer

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
        var components = URLComponents(string: "https://itunes.apple.com/search")
        components?.queryItems = [
            URLQueryItem(name: "term", value: "\(track.title) \(track.artist)"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "5")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(AppleMusicSearchResponse.self, from: data)

        let normalizedTitle = normalize(track.title)
        let normalizedArtist = normalize(track.artist)

        if let exactMatch = response.results.first(where: { result in
            normalize(result.trackName).contains(normalizedTitle)
                && normalize(result.artistName).contains(normalizedArtist)
        }) {
            return String(exactMatch.trackId)
        }

        return response.results.first.map { String($0.trackId) } ?? ""
    }

    private func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
