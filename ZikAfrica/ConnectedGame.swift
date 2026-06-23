import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreImage.CIFilterBuiltins

struct ConnectedTeam: Identifiable {
    let id: String
    let name: String
    let score: Int
}

struct ScoreChange {
    let teamID: String
    let previousScore: Int
}

@MainActor
final class ConnectedGameSession: ObservableObject {
    @Published private(set) var gameCode: String
    @Published private(set) var pin: String
    @Published private(set) var isActive: Bool
    @Published private(set) var isFinished: Bool
    @Published private(set) var teams: [ConnectedTeam] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var history: [ScoreChange] = []

    init() {
        let defaults = UserDefaults.standard
        gameCode = defaults.string(forKey: "connectedGameCode") ?? Self.newCode()
        pin = defaults.string(forKey: "connectedGamePIN") ?? Self.newPIN()
        isActive = defaults.bool(forKey: "connectedGameActive")
        isFinished = defaults.bool(forKey: "connectedGameFinished")
        if isActive { listenForPlayers() }
    }

    var joinURL: URL {
        URL(string: "https://zikafrica-56a1e.web.app/?game=\(gameCode)")!
    }

    var canUndo: Bool { !history.isEmpty && !isFinished }

    func createGame() {
        guard !isActive, !isLoading else { return }
        isLoading = true
        errorMessage = nil

        authenticate { [weak self] uid in
            guard let self else { return }
            let expires = Date().addingTimeInterval(12 * 60 * 60)
            self.db.collection("games").document(self.gameCode).setData([
                "hostUid": uid,
                "pin": self.pin,
                "status": "open",
                "createdAt": FieldValue.serverTimestamp(),
                "expiresAt": Timestamp(date: expires)
            ]) { error in
                Task { @MainActor in
                    self.isLoading = false
                    if error != nil {
                        self.errorMessage = "Impossible de créer la partie en ligne."
                    } else {
                        self.isActive = true
                        self.isFinished = false
                        self.persist()
                        self.listenForPlayers()
                    }
                }
            }
        }
    }

    func startNewSession() {
        let recreate = isActive
        if isActive {
            db.collection("games").document(gameCode).updateData([
                "status": "closed",
                "closedAt": FieldValue.serverTimestamp()
            ])
        }
        stopListening()
        teams = []
        history = []
        gameCode = Self.newCode()
        pin = Self.newPIN()
        isActive = false
        isFinished = false
        errorMessage = nil
        persist()
        if recreate { createGame() }
    }

    func finishGame() {
        guard isActive, !isFinished else { return }
        db.collection("games").document(gameCode).updateData([
            "status": "finished",
            "finishedAt": FieldValue.serverTimestamp()
        ]) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if error == nil {
                    self.isFinished = true
                    self.persist()
                }
            }
        }
    }

    func changeScore(for team: ConnectedTeam, by delta: Int) {
        guard !isFinished else { return }
        let newScore = max(0, team.score + delta)
        db.collection("games").document(gameCode).collection("players").document(team.id)
            .updateData(["score": newScore]) { [weak self] error in
                Task { @MainActor in
                    if error == nil {
                        self?.history.append(ScoreChange(teamID: team.id, previousScore: team.score))
                    }
                }
            }
    }

    func undoLastScore() {
        guard let change = history.last else { return }
        db.collection("games").document(gameCode).collection("players").document(change.teamID)
            .updateData(["score": change.previousScore]) { [weak self] error in
                Task { @MainActor in
                    if error == nil { _ = self?.history.popLast() }
                }
            }
    }

    func listenForPlayers() {
        guard isActive, listener == nil else { return }
        listener = db.collection("games").document(gameCode).collection("players")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    if error != nil {
                        self.errorMessage = "Impossible de synchroniser les joueurs."
                        return
                    }
                    self.teams = snapshot?.documents.map {
                        ConnectedTeam(
                            id: $0.documentID,
                            name: $0.data()["name"] as? String ?? "Équipe",
                            score: $0.data()["score"] as? Int ?? 0
                        )
                    }.sorted { $0.score > $1.score } ?? []
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    private func authenticate(completion: @escaping (String) -> Void) {
        if let uid = Auth.auth().currentUser?.uid {
            completion(uid)
            return
        }
        Auth.auth().signInAnonymously { result, error in
            Task { @MainActor in
                if let uid = result?.user.uid {
                    completion(uid)
                } else {
                    self.isLoading = false
                    self.errorMessage = "Connexion Firebase impossible."
                }
            }
        }
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(gameCode, forKey: "connectedGameCode")
        defaults.set(pin, forKey: "connectedGamePIN")
        defaults.set(isActive, forKey: "connectedGameActive")
        defaults.set(isFinished, forKey: "connectedGameFinished")
    }

    private static func newCode() -> String { "ZA-\(Int.random(in: 100000...999999))" }
    private static func newPIN() -> String { "\(Int.random(in: 1000...9999))" }
}

struct ConnectedGameView: View {
    @ObservedObject var session: ConnectedGameSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if !session.isActive {
                        Text("Crée une salle en ligne. Les joueurs rejoignent avec leur téléphone, sans installer l’application.")
                            .foregroundStyle(.white.opacity(0.82))
                            .multilineTextAlignment(.center)

                        Button(session.isLoading ? "CRÉATION…" : "CRÉER LA PARTIE") {
                            session.createGame()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .foregroundStyle(.black)
                        .disabled(session.isLoading)
                    } else {
                        if !session.isFinished {
                            Text("Fais scanner ce QR Code")
                                .font(.headline.bold())
                            QRCodeImage(text: session.joinURL.absoluteString)
                                .frame(width: 180, height: 180)
                        }

                        Text("Code : \(session.gameCode)  •  PIN : \(session.pin)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.yellow)
                            .minimumScaleFactor(0.75)

                        Text("\(session.teams.count) joueur\(session.teams.count > 1 ? "s" : "") connecté\(session.teams.count > 1 ? "s" : "")")
                            .foregroundStyle(.green)

                        ForEach(Array(session.teams.enumerated()), id: \.element.id) { index, team in
                            ConnectedTeamRow(rank: index + 1, team: team, session: session)
                        }

                        if session.teams.isEmpty {
                            Text("En attente des joueurs…")
                                .foregroundStyle(.white.opacity(0.65))
                        }

                        if !session.isFinished {
                            Button("↶ ANNULER LE DERNIER POINT") { session.undoLastScore() }
                                .buttonStyle(.bordered)
                                .tint(.yellow)
                                .disabled(!session.canUndo)

                            Button("TERMINER LA PARTIE") { session.finishGame() }
                                .buttonStyle(.borderedProminent)
                                .tint(.yellow)
                                .foregroundStyle(.black)
                        }
                    }

                    if let error = session.errorMessage {
                        Text(error).foregroundStyle(.red).font(.footnote)
                    }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .foregroundStyle(.white)
            .navigationTitle(session.isFinished ? "Classement final" : "Partie connectée")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

private struct ConnectedTeamRow: View {
    let rank: Int
    let team: ConnectedTeam
    @ObservedObject var session: ConnectedGameSession

    var body: some View {
        VStack(spacing: 9) {
            HStack {
                Text("\(rank). \(team.name)").font(.headline.bold())
                Spacer()
                Text("\(team.score) pts").font(.title3.bold()).foregroundStyle(.yellow)
            }
            if !session.isFinished {
                HStack {
                    scoreButton("-1", .red, -1)
                    scoreButton("+1", .green, 1)
                    scoreButton("+2", .yellow, 2)
                    scoreButton("+3", .yellow, 3)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(Color.green.opacity(0.6)) }
    }

    private func scoreButton(_ title: String, _ color: Color, _ delta: Int) -> some View {
        Button(title) { session.changeScore(for: team, by: delta) }
            .buttonStyle(.bordered)
            .tint(color)
            .frame(maxWidth: .infinity)
    }
}

private struct QRCodeImage: View {
    let text: String
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        if let image = image {
            Image(uiImage: image).interpolation(.none).resizable().scaledToFit()
        }
    }

    private var image: UIImage? {
        filter.message = Data(text.utf8)
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
