import SwiftUI
import UserNotifications
import AVFoundation
import AudioToolbox
import UIKit

struct ContentView: View {

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var connectedGame = ConnectedGameSession()

    @State private var scannedCode = ""
    @State private var selectedTrack: Track?
    @State private var lastTrack: Track?
    @State private var showSplash = true
    @State private var showScanner = false
    @State private var showRules = false
    @State private var pulse = false
    @State private var selectedPlatform: MusicPlatform?
    @State private var showPlatformChoice = false
    @State private var scanCount = 0
    @State private var showPlaybackTransition = false
    @State private var showPlaybackReturn = false
    @State private var awaitingMusicAppReturn = false
    @State private var showMusicAppError = false
    @State private var showAppleMusicRecommendation = false
    @State private var showPlatformChoiceAfterAppleMusicRecommendation = false
    @State private var showConnectedGame = false
    @State private var showSettings = false
    @State private var scanSoundEnabled = false
    @State private var vibrationEnabled = true
    @State private var playbackSourceName = "ZikAfrica"

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                Image("home_zikafrica")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(pulse ? 1.035 : 0.99)
                    .ignoresSafeArea()

                backgroundOverlay
                ambientBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: geometry.size.height < 700 ? 10 : 14) {
                        topControlBar
                        gameButtons

                        Spacer(minLength: contentSpacerHeight(for: geometry.size.height))

                        platformStatus
                        scannerButton
                        actionCards
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 108)
                    .frame(maxWidth: 620)
                    .frame(maxWidth: .infinity)
                }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(10)
                }

                if showPlaybackTransition {
                    PlaybackTransitionView(sourceName: playbackSourceName)
                        .transition(.opacity)
                        .zIndex(20)
                }

                if showPlaybackReturn,
                   let track = lastTrack {
                    PlaybackReturnView(
                        sourceName: playbackSourceName,
                        onReplay: {
                            showPlaybackReturn = false
                            playTrack(track: track)
                        },
                        onReveal: {
                            showPlaybackReturn = false
                            selectedTrack = track
                        },
                        onScanNext: {
                            showPlaybackReturn = false
                            showScanner = true
                        },
                        onHome: {
                            DeezerPreviewPlayer.shared.stop()
                            AppleMusicFullTrackPlayer.shared.stop()
                            SpotifyFullTrackPlayer.shared.stop()
                            showPlaybackReturn = false
                            showPlaybackTransition = false
                            showScanner = false
                            selectedTrack = nil
                        }
                    )
                    .transition(.opacity)
                    .zIndex(20)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !showSplash && scanCount > 0 {
                scanCounter
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: $selectedTrack) { track in
            RevealView(track: track)
        }
        .sheet(isPresented: $showScanner) {
            QRCodeScannerView { code in
                scannedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
                showScanner = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    playScannedTrack()
                }
            }
        }
        .sheet(isPresented: $showRules) {
            RulesView()
        }
        .sheet(isPresented: $showConnectedGame) {
            ConnectedGameView(session: connectedGame)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                scanSoundEnabled: $scanSoundEnabled,
                vibrationEnabled: $vibrationEnabled,
                selectedPlatform: selectedPlatform,
                onChangePlatform: {
                    showSettings = false
                    showPlatformChoice = true
                }
            )
        }
        .sheet(isPresented: $showPlatformChoice) {
            PlatformChoiceView { platform in
                selectedPlatform = platform
                showPlatformChoice = false
            }
        }
        .onAppear {
            configureApp()
            UIApplication.shared.isIdleTimerDisabled = true
            PlaybackReturnNotification.requestAuthorization()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, awaitingMusicAppReturn else {
                return
            }

            awaitingMusicAppReturn = false
            PlaybackReturnNotification.cancel()
            withAnimation(.easeInOut(duration: 0.2)) {
                showPlaybackTransition = false
                showPlaybackReturn = true
            }
        }
        .alert("Apple Music recommandé", isPresented: $showAppleMusicRecommendation) {
            Button("Télécharger Apple Music") {
                openAppleMusicDownloadPage()
                showDeferredPlatformChoiceIfNeeded()
            }
            Button("Continuer", role: .cancel) {
                showDeferredPlatformChoiceIfNeeded()
            }
        } message: {
            Text("Pour une expérience ZikAfrica plus fluide sur iPhone, Apple Music permet de lancer les titres directement dans l’app et de garder tout le suspense du jeu. Tu peux continuer avec les options disponibles, mais Apple Music offrira le meilleur confort de jeu.")
        }
        .alert("Impossible d’ouvrir la plateforme", isPresented: $showMusicAppError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Vérifie que l’application musicale sélectionnée est installée.")
        }
    }

    private var backgroundOverlay: some View {
        ZStack {
            Color.black.opacity(0.22)

            LinearGradient(
                colors: [
                    .black.opacity(0.84),
                    .black.opacity(0.18),
                    .black.opacity(0.38),
                    .black.opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private var ambientBackground: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.13))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: pulse ? -120 : -70, y: pulse ? -280 : -220)

            Circle()
                .fill(Color.yellow.opacity(0.11))
                .frame(width: 280, height: 280)
                .blur(radius: 75)
                .offset(x: pulse ? 130 : 80, y: pulse ? 290 : 230)
        }
        .scaleEffect(pulse ? 1.06 : 0.94)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private var topControlBar: some View {
        HStack(spacing: 8) {
            TopControlButton(title: "RÈGLES", icon: "book.closed.fill", tint: .white) {
                showRules = true
            }

            TopControlButton(title: connectedGame.isActive ? "SCORES LIVE" : "SCORES", icon: "list.number", tint: .green) {
                showConnectedGame = true
            }

            TopControlButton(title: "AJUST.", icon: "slider.horizontal.3", tint: .yellow) {
                showSettings = true
            }
        }
    }

    private var gameButtons: some View {
        HStack(spacing: 8) {
            gameButton("Rejouer", icon: "arrow.counterclockwise", disabled: lastTrack == nil) {
                if let track = lastTrack {
                    playTrack(track: track)
                }
            }

            gameButton("Révéler", icon: "trophy.fill", disabled: lastTrack == nil) {
                selectedTrack = lastTrack
            }

            gameButton("Nouvelle partie", icon: "plus.circle.fill") {
                connectedGame.startNewSession()
                scannedCode = ""
                selectedTrack = nil
                lastTrack = nil
                scanCount = 0
            }
        }
    }

    private func gameButton(
        _ title: String,
        icon: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.headline)

                Text(title)
                    .font(.caption2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
        }
        .buttonStyle(.borderedProminent)
        .tint(.yellow)
        .foregroundColor(.black)
        .disabled(disabled)
    }

    @ViewBuilder
    private var platformStatus: some View {
        if let platform = selectedPlatform {
            Label(platform.rawValue, systemImage: "headphones")
                .foregroundColor(.green)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.82))
                .clipShape(Capsule())
        } else {
            Label("Aucune plateforme", systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.82))
                .clipShape(Capsule())
        }
    }

    private var scannerButton: some View {
        Button {
            #if targetEnvironment(simulator)
            scannedCode = "ZA-0001"
            playScannedTrack()
            #else
            showScanner = true
            #endif
        } label: {
            ZStack {
                VStack(spacing: 1) {
                    Text("SCANNER")
                        .foregroundColor(.white)
                    Text("UNE CARTE")
                        .foregroundColor(.yellow)
                }
                .font(.system(size: 21, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)

                HStack {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 33, weight: .bold))
                        .scaleEffect(pulse ? 1.10 : 0.94)

                    Spacer()

                    Image(systemName: "sparkles")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundColor(.yellow)
                        .rotationEffect(.degrees(pulse ? 10 : -10))
                }
                .padding(.horizontal, 22)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 86)
            .background(
                LinearGradient(
                    colors: [.green.opacity(0.9), .black, .yellow.opacity(0.82)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.7), lineWidth: 2)
            }
            .shadow(
                color: pulse ? .yellow.opacity(0.55) : .green.opacity(0.4),
                radius: pulse ? 15 : 8
            )
            .scaleEffect(pulse ? 1.01 : 0.99)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
    }

    private var actionCards: some View {
        HStack(spacing: 8) {
            ActionCard(emoji: "▣", title: "SCANNE", subtitle: "Scanne une carte")
            ActionCard(emoji: "🎧", title: "ÉCOUTE", subtitle: "La musique se lance")
            ActionCard(emoji: "🏆", title: "DEVINE", subtitle: "Trouve le titre")
        }
    }

    private var scanCounter: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.title3)

            Text("\(scanCount) carte\(scanCount > 1 ? "s" : "") jouée\(scanCount > 1 ? "s" : "")")
                .font(.subheadline.bold())
        }
        .foregroundColor(.yellow)
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .background(Color.black.opacity(0.92))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Color.yellow.opacity(0.8), lineWidth: 1.5)
        }
    }

    private func contentSpacerHeight(for screenHeight: CGFloat) -> CGFloat {
        min(max(screenHeight * 0.43, 245), 390)
    }

    private func playScannedTrack() {
        Task {
            guard let track = await TrackRepository.shared.findTrackOnlineIfNeeded(qrCode: scannedCode) else {
                return
            }

            await MainActor.run {
                if scanSoundEnabled {
                    AudioServicesPlaySystemSound(1108)
                }

                if vibrationEnabled {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }

                lastTrack = track
                withAnimation(.easeInOut(duration: 0.25)) {
                    scanCount += 1
                }

                playTrack(track: track, fallbackPlatform: selectedPlatform)
            }
        }
    }

    private func playTrack(track: Track, fallbackPlatform: MusicPlatform? = nil) {
        playbackSourceName = "ZikAfrica"
        showPlaybackReturn = false
        showPlaybackTransition = false

        Task {
            let fullTrackStarted = await playFullTrackIfAvailable(
                track: track,
                platform: fallbackPlatform ?? selectedPlatform
            )

            if fullTrackStarted {
                await MainActor.run {
                    showPlaybackTransition = false
                    showPlaybackReturn = true
                }
                return
            }

            let previewStarted = await DeezerPreviewPlayer.shared.playPreview(for: track)

            await MainActor.run {
                if previewStarted {
                    showPlaybackTransition = false
                    showPlaybackReturn = true
                    return
                }

                if let platform = externalFallbackPlatform(
                    preferredPlatform: fallbackPlatform ?? selectedPlatform,
                    track: track
                ) {
                    launchMusicApp(track: track, platform: platform)
                } else {
                    showPlaybackTransition = false
                    showMusicAppError = true
                }
            }
        }
    }

    private func playFullTrackIfAvailable(track: Track, platform: MusicPlatform?) async -> Bool {
        guard let platform else {
            return false
        }

        switch platform {
        case .appleMusic:
            playbackSourceName = "Apple Music"
            return await AppleMusicFullTrackPlayer.shared.play(track: track)

        case .spotify:
            playbackSourceName = "Spotify"
            return await SpotifyFullTrackPlayer.shared.play(track: track)

        case .deezer:
            return false
        }
    }

    private func externalFallbackPlatform(
        preferredPlatform: MusicPlatform?,
        track: Track
    ) -> MusicPlatform? {
        if let preferredPlatform,
           preferredPlatform != .appleMusic,
           canOpenExternally(platform: preferredPlatform, track: track) {
            return preferredPlatform
        }

        if MusicAppDetector.isSpotifyInstalled(),
           canOpenExternally(platform: .spotify, track: track) {
            return .spotify
        }

        if MusicAppDetector.isDeezerInstalled(),
           canOpenExternally(platform: .deezer, track: track) {
            return .deezer
        }

        return nil
    }

    private func canOpenExternally(platform: MusicPlatform, track: Track) -> Bool {
        switch platform {
        case .spotify:
            return !track.spotifyUri.isEmpty
        case .deezer:
            return !track.deezerId.isEmpty
        case .appleMusic:
            return false
        }
    }

    private func launchMusicApp(track: Track, platform: MusicPlatform) {
        withAnimation(.easeInOut(duration: 0.18)) {
            playbackSourceName = platform.rawValue
            showPlaybackReturn = false
            showPlaybackTransition = true
        }

        #if targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showPlaybackTransition = false
                showPlaybackReturn = true
            }
        }
        #else
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            MusicPlayerManager.play(track: track, platform: platform) { opened in
                DispatchQueue.main.async {
                    if opened {
                        awaitingMusicAppReturn = true
                        PlaybackReturnNotification.schedule(platform: platform)
                    } else {
                        showPlaybackTransition = false
                        showMusicAppError = true
                    }
                }
            }
        }
        #endif
    }

    private func configureApp() {
        showSplash = true

        withAnimation(.easeInOut(duration: 1.65).repeatForever(autoreverses: true)) {
            pulse = true
        }

        #if targetEnvironment(simulator)
        selectedPlatform = .appleMusic
        #else
        let hasAppleMusic = MusicAppDetector.isAppleMusicInstalled()
        let hasSpotify = MusicAppDetector.isSpotifyInstalled()
        let hasDeezer = MusicAppDetector.isDeezerInstalled()

        if hasAppleMusic {
            selectedPlatform = .appleMusic
            showPlatformChoice = false
        } else if hasSpotify && hasDeezer {
            selectedPlatform = nil
            showPlatformChoice = false
            showPlatformChoiceAfterAppleMusicRecommendation = true
            scheduleAppleMusicRecommendation()
        } else if hasSpotify {
            selectedPlatform = .spotify
            showPlatformChoice = false
            scheduleAppleMusicRecommendation()
        } else if hasDeezer {
            selectedPlatform = .deezer
            showPlatformChoice = false
            scheduleAppleMusicRecommendation()
        } else {
            selectedPlatform = nil
            showPlatformChoice = false
            showPlatformChoiceAfterAppleMusicRecommendation = true
            scheduleAppleMusicRecommendation()
        }
        #endif

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation {
                showSplash = false
            }
        }
    }

    private func scheduleAppleMusicRecommendation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.45) {
            guard !showAppleMusicRecommendation, !MusicAppDetector.isAppleMusicInstalled() else {
                return
            }

            showAppleMusicRecommendation = true
        }
    }

    private func showDeferredPlatformChoiceIfNeeded() {
        guard showPlatformChoiceAfterAppleMusicRecommendation else {
            return
        }

        showPlatformChoiceAfterAppleMusicRecommendation = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showPlatformChoice = true
        }
    }

    private func openAppleMusicDownloadPage() {
        guard let url = URL(string: "https://apps.apple.com/app/apple-music/id1108187390") else {
            return
        }

        UIApplication.shared.open(url)
    }
}

enum PlaybackReturnNotification {
    private static let identifier = "zikafrica.playback.return"

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func schedule(platform: MusicPlatform) {
        let content = UNMutableNotificationContent()
        content.title = "Retourne dans ZikAfrica"
        content.body = "La musique joue sur \(platform.rawValue). Reviens dans ZikAfrica pour deviner la carte."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().add(request)
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}

@MainActor
final class DeezerPreviewPlayer {
    static let shared = DeezerPreviewPlayer()

    private var player: AVPlayer?

    private init() {}

    func stop() {
        player?.pause()
        player = nil
    }

    func playPreview(for track: Track) async -> Bool {
        guard !track.deezerId.isEmpty else {
            return false
        }

        do {
            let previewURL = try await fetchPreviewURL(deezerId: track.deezerId)
            try configureAudioSession()
            player?.pause()
            let player = AVPlayer(url: previewURL)
            self.player = player
            player.play()
            return true
        } catch {
            print("Lecture preview Deezer impossible :", error)
            return false
        }
    }

    private func fetchPreviewURL(deezerId: String) async throws -> URL {
        guard let apiURL = URL(string: "https://api.deezer.com/track/\(deezerId)") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: apiURL)
        let response = try JSONDecoder().decode(DeezerTrackPreviewResponse.self, from: data)

        guard let preview = response.preview,
              let previewURL = URL(string: preview) else {
            throw URLError(.fileDoesNotExist)
        }

        return previewURL
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
    }
}

private struct DeezerTrackPreviewResponse: Decodable {
    let preview: String?
}

struct ActionCard: View {
    let emoji: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 5) {
            Text(emoji)
                .font(.title3)

            Text(title)
                .font(.caption.bold())
                .foregroundColor(.green)

            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 78)
        .padding(.horizontal, 4)
        .background(Color.black.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.green.opacity(0.85), lineWidth: 1.5)
        }
    }
}

struct TopControlButton: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundColor(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.black.opacity(0.84))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(tint.opacity(0.72), lineWidth: 1.2)
                }
        }
        .buttonStyle(.plain)
    }
}

struct SettingsView: View {
    @Binding var scanSoundEnabled: Bool
    @Binding var vibrationEnabled: Bool
    let selectedPlatform: MusicPlatform?
    let onChangePlatform: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color(red: 0.04, green: 0.12, blue: 0.06), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Image("zikafrica_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 210)

                Text("AJUSTEMENTS")
                    .font(.title.bold())
                    .foregroundColor(.yellow)

                VStack(spacing: 14) {
                    Toggle("Son du scan", isOn: $scanSoundEnabled)
                    Toggle("Vibrations", isOn: $vibrationEnabled)

                    Button(action: onChangePlatform) {
                        HStack {
                            Label("Changer de plateforme", systemImage: "headphones")
                            Spacer()
                            Text(selectedPlatform?.rawValue ?? "Aucune")
                                .foregroundColor(.yellow)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.green.opacity(0.7), lineWidth: 1.4)
                }

                Button {
                    dismiss()
                } label: {
                    Text("FERMER")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
            .padding(24)
        }
    }
}

struct PlaybackTransitionView: View {
    let sourceName: String

    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Circle()
                .fill(Color.green.opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 55)
                .scaleEffect(pulse ? 1.12 : 0.88)

            VStack(spacing: 22) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 82))
                    .foregroundStyle(.yellow, .green)
                    .scaleEffect(pulse ? 1.08 : 0.94)

                Text("LA MUSIQUE DÉMARRE")
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text(sourceName == "ZikAfrica" ? "Lecture dans ZikAfrica" : "Ouverture de \(sourceName)")
                    .font(.headline)
                    .foregroundColor(.yellow)

                Text(sourceName == "ZikAfrica" ? "L’extrait reste masqué dans l’app. À vous de deviner." : "Laisse la musique jouer, puis touche l’alerte iPhone pour revenir dans ZikAfrica et deviner.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct PlaybackReturnView: View {
    let sourceName: String
    let onReplay: () -> Void
    let onReveal: () -> Void
    let onScanNext: () -> Void
    let onHome: () -> Void

    @State private var secondsRemaining = 30
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button(action: onHome) {
                        Text("Accueil")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 18)
                    .padding(.trailing, 22)
                }
                Spacer()
            }
            .zIndex(2)

            VStack(spacing: 18) {
                timerBadge
                    .padding(.top, 18)

                Spacer(minLength: 10)

                SpeakerBeatLogo(width: min(geometry.size.width * 0.92, 390))

                Spacer(minLength: 8)

                VStack(spacing: 12) {
                    returnButton(
                        "SCANNER LA CARTE SUIVANTE",
                        icon: "qrcode.viewfinder",
                        tint: .green,
                        action: onScanNext
                    )

                    HStack(spacing: 10) {
                        returnButton(
                            "REJOUER",
                            icon: "arrow.counterclockwise",
                            tint: .yellow,
                            compact: true,
                            action: onReplay
                        )

                        returnButton(
                            "RÉVÉLER",
                            icon: "trophy.fill",
                            tint: .yellow,
                            compact: true,
                            action: onReveal
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        }
        .onAppear {
            secondsRemaining = 30
        }
        .onReceive(timer) { _ in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            }
        }
    }

    private var timerBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
            Text(String(format: "00:%02d", secondsRemaining))
        }
        .font(.system(size: 28, weight: .black, design: .rounded))
        .foregroundColor(secondsRemaining <= 5 ? .red : .yellow)
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.86))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(secondsRemaining <= 5 ? Color.red : Color.green, lineWidth: 2)
        }
    }

    private func returnButton(
        _ title: String,
        icon: String,
        tint: Color,
        compact: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: compact ? 13 : 16, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundColor(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 15 : 18)
                .background(Color.black.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(tint, lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
    }
}
