import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            SpeakerBeatLogo(width: 330)
        }
    }
}

struct SpeakerBeatLogo: View {
    let width: CGFloat

    @State private var beat = false

    var body: some View {
        ZStack {
            Color.black

            Image("zikafrica_logo")
                .resizable()
                .scaledToFit()
                .frame(width: width * 1.12)
                .scaleEffect(beat ? 1.065 : 1.0)
                .offset(x: beat ? -2.5 : 1.4, y: beat ? 2.2 : -1.2)
        }
        .frame(width: width, height: width)
        .background(Color.black)
        .compositingGroup()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.52).repeatForever(autoreverses: true)) {
                beat = true
            }
        }
    }
}
