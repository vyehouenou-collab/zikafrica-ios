import SwiftUI

struct RulesView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {

        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {

                Text("🎮 RÈGLES DU JEU")
                    .foregroundColor(.yellow)
                    .font(.title2)
                    .fontWeight(.heavy)

                RuleLine(number: "1", text: "Scanne une carte ZikAfrica.")
                RuleLine(number: "2", text: "La musique se lance.")
                RuleLine(number: "3", text: "Devine le titre, l’artiste ou l’année.")
                RuleLine(number: "4", text: "Gagne 3, 2 ou 1 Beats.")
                RuleLine(number: "5", text: "Le meilleur score gagne.")

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("FERMER")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(18)
                }
            }
            .padding(28)
        }
    }
}

struct RuleLine: View {

    let number: String
    let text: String

    var body: some View {

        HStack {

            Text(number)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
                .background(Color.yellow)
                .clipShape(Circle())

            Text(text)
                .foregroundColor(.white)

            Spacer()
        }
    }
}
