import SwiftUI

struct RulesView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {

        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {

                Text(L("rules_title"))
                    .foregroundColor(.yellow)
                    .font(.title2)
                    .fontWeight(.heavy)

                RuleLine(number: "1", text: L("rules_step1"))
                RuleLine(number: "2", text: L("rules_step2"))
                RuleLine(number: "3", text: L("rules_step3"))
                RuleLine(number: "4", text: L("rules_step4"))
                RuleLine(number: "5", text: L("rules_step5"))

                Spacer()

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
