import SwiftUI

/// Écran affiché uniquement quand AUCUNE app musicale compatible n'est installée.
/// Contrairement à PlatformChoiceView (qui laisse choisir entre des apps déjà
/// installées), celui-ci pousse clairement vers l'installation — proposer un choix
/// alors qu'il n'y a rien d'installé ne mène qu'à des échecs de lecture à répétition.
struct NoMusicAppInstalledView: View {
    let onOpenSpotify: () -> Void
    let onOpenAppleMusic: () -> Void
    let onOpenDeezer: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 22) {
                SpeakerBeatLogo(width: 260)

                Text(L("no_app_title"))
                    .foregroundColor(.yellow)
                    .font(.title2)
                    .fontWeight(.heavy)
                    .multilineTextAlignment(.center)

                Text(L("no_app_subtitle"))
                    .foregroundColor(.white.opacity(0.78))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                PlatformButton(title: "Spotify", icon: "🟢", action: onOpenSpotify)
                PlatformButton(title: "Apple Music", icon: "🍎", action: onOpenAppleMusic)
                PlatformButton(title: "Deezer", icon: "🎵", action: onOpenDeezer)

                Button(action: onDismiss) {
                    Text(L("later_button"))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 4)
            }
            .padding()
        }
    }
}
