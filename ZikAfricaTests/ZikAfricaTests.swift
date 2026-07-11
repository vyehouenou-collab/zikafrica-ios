import XCTest
@testable import ZikAfrica

final class ZikAfricaTests: XCTestCase {
    private let completeTrack = Track(
        qrCode: "ZA-TEST",
        title: "Test Song",
        artist: "Test Artist",
        year: "2026",
        spotifyUri: "spotify:track:test",
        deezerId: "123456",
        appleMusicId: "987654"
    )

    func testGlobalPriorityIgnoresUserChoiceWhenAllPlatformsAreAvailable() {
        for preferredPlatform in [MusicPlatform.appleMusic, .spotify, .deezer, nil] {
            let attempts = PlaybackRoutingPolicy.attempts(
                preferredPlatform: preferredPlatform,
                track: completeTrack,
                installedApps: InstalledMusicApps(appleMusic: true, spotify: true, deezer: true)
            )

            XCTAssertEqual(
                attempts,
                [
                    .fullTrack(.appleMusic),
                    .fullTrack(.spotify),
                    .deezerPreview,
                    .external(.spotify)
                ]
            )
        }
    }

    func testSpotifyBecomesFirstFullTrackOptionWhenAppleMusicIsUnavailable() {
        let attempts = PlaybackRoutingPolicy.attempts(
            preferredPlatform: .appleMusic,
            track: completeTrack,
            installedApps: InstalledMusicApps(appleMusic: false, spotify: true, deezer: true)
        )

        XCTAssertEqual(
            attempts,
            [
                .fullTrack(.spotify),
                .deezerPreview,
                .external(.spotify)
            ]
        )
    }

    func testDeezerPreviewIsUsedBeforeExternalFallbackWhenFullTrackPlatformsAreUnavailable() {
        let attempts = PlaybackRoutingPolicy.attempts(
            preferredPlatform: .spotify,
            track: completeTrack,
            installedApps: InstalledMusicApps(appleMusic: false, spotify: false, deezer: true)
        )

        XCTAssertEqual(
            attempts,
            [
                .deezerPreview,
                .external(.deezer)
            ]
        )
    }

    func testExternalFallbackPrefersSpotifyOverDeezerRegardlessOfUserChoice() {
        let attempts = PlaybackRoutingPolicy.attempts(
            preferredPlatform: .deezer,
            track: completeTrack,
            installedApps: InstalledMusicApps(appleMusic: false, spotify: true, deezer: true)
        )

        XCTAssertEqual(attempts.last, .external(.spotify))
    }

    func testNoExternalOpeningWhenNoExternalLinksAreAvailable() {
        let trackWithoutExternalLinks = Track(
            qrCode: "ZA-NO-EXT",
            title: "No External",
            artist: "Test Artist",
            year: "2026",
            spotifyUri: "",
            deezerId: "",
            appleMusicId: "987654"
        )

        let attempts = PlaybackRoutingPolicy.attempts(
            preferredPlatform: .deezer,
            track: trackWithoutExternalLinks,
            installedApps: InstalledMusicApps(appleMusic: true, spotify: true, deezer: true)
        )

        XCTAssertEqual(
            attempts,
            [
                .fullTrack(.appleMusic),
                .deezerPreview
            ]
        )
    }
}
