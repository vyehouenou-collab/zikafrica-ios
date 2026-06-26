//
//  TrackRepository.swift
//  ZikAfrica
//
//  Created by Valérien YEHOUENOU on 09/06/2026.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class TrackRepository {

    static let shared = TrackRepository()

    private var tracksByCode: [String: Track] = [:]

    private init() {
        loadTracks()
    }

    private func loadTracks() {
        guard let url = Bundle.main.url(forResource: "tracks", withExtension: "json") else {
            print("tracks.json introuvable")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let tracks = try JSONDecoder().decode([Track].self, from: data)

            tracksByCode = Dictionary(
                uniqueKeysWithValues: tracks.map { ($0.qrCode.uppercased(), $0) }
            )

            print("Tracks chargés : \(tracksByCode.count)")
        } catch {
            print("Erreur chargement tracks.json : \(error)")
        }
    }

    func findTrack(qrCode: String) -> Track? {
        guard let cleanCode = extractZaCode(from: qrCode) else {
            print("QR Code non reconnu :", qrCode)
            return nil
        }

        print("Recherche :", cleanCode)
        print("Codes disponibles :", tracksByCode.keys)
        return tracksByCode[cleanCode]
    }

    func findTrackOnlineIfNeeded(qrCode: String) async -> Track? {
        guard let cleanCode = extractZaCode(from: qrCode) else {
            print("QR Code non reconnu :", qrCode)
            return nil
        }

        if let localTrack = tracksByCode[cleanCode] {
            return localTrack
        }

        do {
            if Auth.auth().currentUser == nil {
                _ = try await Auth.auth().signInAnonymously()
            }

            let document = try await Firestore.firestore()
                .collection("tracks")
                .document(cleanCode)
                .getDocument()

            guard document.exists, let data = document.data() else {
                return nil
            }

            let spotifyUri = stringValue(data["spotifyUri"])
                ?? stringValue(data["spotify_uri"])
                ?? ""
            let rawDeezerId = stringValue(data["deezerId"])
                ?? stringValue(data["deezer_id"])
                ?? ""
            let deezerId = rawDeezerId == "NOT_FOUND" ? "" : rawDeezerId
            let appleMusicId = stringValue(data["appleMusicId"])
                ?? stringValue(data["apple_music_id"])
                ?? stringValue(data["appleMusicTrackId"])
                ?? ""

            let track = Track(
                qrCode: stringValue(data["qrCode"])
                    ?? stringValue(data["zaId"])
                    ?? stringValue(data["za_id"])
                    ?? document.documentID,
                title: stringValue(data["title"]) ?? "",
                artist: stringValue(data["artist"]) ?? "",
                year: stringValue(data["year"]) ?? "",
                spotifyUri: spotifyUri,
                deezerId: deezerId,
                appleMusicId: appleMusicId
            )

            tracksByCode[track.qrCode.uppercased()] = track
            return track
        } catch {
            print("Erreur chargement piste distante :", error)
            return nil
        }
    }

    private func extractZaCode(from value: String) -> String? {
        let pattern = #"ZA-\d{4,6}"#
        guard let range = value.range(
            of: pattern,
            options: [.regularExpression, .caseInsensitive]
        ) else {
            return nil
        }

        return String(value[range]).uppercased()
    }

    private func stringValue(_ value: Any?) -> String? {
        if let value = value as? String {
            return value
        }

        if let value = value {
            return String(describing: value)
        }

        return nil
    }
}
