import SwiftUI
import UIKit

struct RevealView: View {
    let track: Track

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color(red: 0.08, green: 0.03, blue: 0.0), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Image("zikafrica_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)

                Text(L("reveal_title"))
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundColor(.yellow)

                VStack(spacing: 14) {
                    RevealLine(icon: "🎵", label: L("reveal_track_label"), value: track.title, points: L("reveal_points_track"))
                    RevealLine(icon: "👤", label: L("reveal_artist_label"), value: track.artist, points: L("reveal_points_artist"))
                    RevealLine(icon: "📅", label: L("reveal_year_label"), value: track.year, points: L("reveal_points_year"))
                }
                .padding()
                .background(Color.black.opacity(0.72))
                .cornerRadius(28)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [.yellow, .green, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                )
                .padding(.horizontal, 18)

                Text(L("reveal_footer"))
                    .foregroundColor(.white.opacity(0.8))
                    .font(.footnote)

                Button {
                    dismiss()
                } label: {
                    Text(L("close_button"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(18)
                }
                .padding(.horizontal, 24)
            }
            .padding()
        }
        .onAppear {
            UINotificationFeedbackGenerator()
                .notificationOccurred(.success)
        }
    }
}

struct RevealLine: View {
    let icon: String
    let label: String
    let value: String
    let points: String

    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.largeTitle)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .foregroundColor(.yellow)
                    .font(.caption)
                    .fontWeight(.bold)

                Text(value)
                    .foregroundColor(.white)
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Spacer()

            Text(points)
                .foregroundColor(.green)
                .font(.caption)
                .fontWeight(.heavy)
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(18)
    }
}
