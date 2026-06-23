import SwiftUI

struct PlatformChoiceView: View {
    let onChoose: (MusicPlatform) -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 22) {
                SpeakerBeatLogo(width: 300)

                Text("🎧 CHOISIS TA PLATEFORME")
                    .foregroundColor(.yellow)
                    .font(.title2)
                    .fontWeight(.heavy)

                PlatformButton(title: "Spotify", icon: "🟢") {
                    onChoose(.spotify)
                }

                PlatformButton(title: "Apple Music", icon: "🍎") {
                    onChoose(.appleMusic)
                }

                PlatformButton(title: "Deezer", icon: "🎵") {
                    onChoose(.deezer)
                }
            }
            .padding()
        }
    }
}

struct PlatformButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(icon).font(.largeTitle)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("›").font(.largeTitle)
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.white.opacity(0.08))
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.yellow, lineWidth: 1.5)
            )
        }
    }
}
