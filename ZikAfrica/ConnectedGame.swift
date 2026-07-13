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
    @Published private(set) var buzzOpen = false
    @Published private(set) var buzzRound = 0
    @Published private(set) var firstBuzzPlayerName: String?
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var playerListener: ListenerRegistration?
    private var gameListener: ListenerRegistration?
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
                "buzzOpen": false,
                "buzzRound": 0,
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
        buzzOpen = false
        buzzRound = 0
        firstBuzzPlayerName = nil
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

    func removeTeam(_ team: ConnectedTeam) {
        guard !isFinished else { return }
        db.collection("games").document(gameCode).collection("players").document(team.id)
            .delete { [weak self] error in
                Task { @MainActor in
                    guard let self else { return }
                    if error != nil {
                        self.errorMessage = "Impossible de retirer ce joueur."
                    } else {
                        self.history.removeAll { $0.teamID == team.id }
                    }
                }
            }
    }

    func openBuzzerForPlayback() {
        guard isActive, !isFinished else { return }
        db.collection("games").document(gameCode).updateData([
            "buzzOpen": true,
            "buzzRound": FieldValue.increment(Int64(1)),
            "firstBuzzPlayerId": FieldValue.delete(),
            "firstBuzzPlayerName": FieldValue.delete(),
            "firstBuzzAt": FieldValue.delete(),
            "lastPlaybackActionAt": FieldValue.serverTimestamp()
        ])
    }

    func resetBuzzer() {
        guard isActive, !isFinished else { return }
        db.collection("games").document(gameCode).updateData([
            "buzzOpen": false,
            "firstBuzzPlayerId": FieldValue.delete(),
            "firstBuzzPlayerName": FieldValue.delete(),
            "firstBuzzAt": FieldValue.delete()
        ])
    }

    func listenForPlayers() {
        guard isActive else { return }

        if gameListener == nil {
            gameListener = db.collection("games").document(gameCode)
                .addSnapshotListener { [weak self] snapshot, error in
                    Task { @MainActor in
                        guard let self else { return }
                        if error != nil {
                            self.errorMessage = "Impossible de synchroniser le buzzer."
                            return
                        }

                        let data = snapshot?.data() ?? [:]
                        self.buzzOpen = data["buzzOpen"] as? Bool ?? false
                        if let buzzRound = data["buzzRound"] as? Int {
                            self.buzzRound = buzzRound
                        } else if let buzzRound = data["buzzRound"] as? NSNumber {
                            self.buzzRound = buzzRound.intValue
                        } else {
                            self.buzzRound = 0
                        }
                        self.firstBuzzPlayerName = data["firstBuzzPlayerName"] as? String
                    }
                }
        }

        guard playerListener == nil else { return }
        playerListener = db.collection("games").document(gameCode).collection("players")
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
        playerListener?.remove()
        playerListener = nil
        gameListener?.remove()
        gameListener = nil
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
    var onClose: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let panelWidth = min(geometry.size.width - 44, 620)
            let qrSize = min(geometry.size.width * 0.52, 250)

            ZStack {
                Color.black.opacity(0.58)
                    .ignoresSafeArea()
                    .onTapGesture { onClose() }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        Text(session.isFinished ? "CLASSEMENT FINAL" : "PARTIE CONNECTÉE")
                            .font(.system(size: 29, weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 1, green: 0.77, blue: 0))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.72)
                            .padding(.top, 8)

                        if !session.isActive {
                            Text("Crée une salle en ligne. Les joueurs rejoignent avec leur téléphone, sans installer l’application.")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.82))
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .padding(.horizontal, 8)

                            Button(session.isLoading ? "CRÉATION…" : "CRÉER LA PARTIE") {
                                session.createGame()
                            }
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(Color(red: 1, green: 0.77, blue: 0))
                            .clipShape(Capsule())
                            .disabled(session.isLoading)
                            .opacity(session.isLoading ? 0.65 : 1)
                        } else {
                            if !session.isFinished {
                                Text("Fais scanner ce QR Code")
                                    .font(.system(size: 25, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)

                                QRCodeImage(text: session.joinURL.absoluteString)
                                    .frame(width: qrSize, height: qrSize)
                                    .padding(8)
                                    .background(Color.white)
                            }

                            Text("Code : \(session.gameCode)   •   PIN : \(session.pin)")
                                .font(.system(size: 19, weight: .black, design: .rounded))
                                .foregroundStyle(Color(red: 1, green: 0.77, blue: 0))
                                .minimumScaleFactor(0.58)
                                .lineLimit(1)

                            Text("\(session.teams.count) joueur\(session.teams.count > 1 ? "s" : "") connecté\(session.teams.count > 1 ? "s" : "")")
                                .font(.system(size: 21, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(red: 0.3, green: 1, blue: 0.53))

                            ConnectedBuzzerStatus(session: session)

                            if session.teams.isEmpty {
                                Text("En attente des joueurs...")
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.68))
                            }

                            ForEach(Array(session.teams.enumerated()), id: \.element.id) { index, team in
                                ConnectedTeamRow(rank: index + 1, team: team, session: session)
                            }

                            if !session.isFinished {
                                Button("↶  ANNULER LE DERNIER POINT") { session.undoLastScore() }
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundStyle(Color(red: 1, green: 0.77, blue: 0))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 58)
                                    .background(Color.black.opacity(0.22))
                                    .clipShape(Capsule())
                                    .overlay {
                                        Capsule().stroke(.white.opacity(0.46), lineWidth: 1.5)
                                    }
                                    .disabled(!session.canUndo)
                                    .opacity(session.canUndo ? 1 : 0.42)

                                Button("TERMINER LA PARTIE") { session.finishGame() }
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 58)
                                    .background(Color(red: 1, green: 0.77, blue: 0))
                                    .clipShape(Capsule())
                            }
                        }

                        if let error = session.errorMessage {
                            Text(error)
                                .font(.footnote.bold())
                                .foregroundStyle(Color(red: 1, green: 0.45, blue: 0.45))
                                .multilineTextAlignment(.center)
                        }

                        Button("FERMER") { onClose() }
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.top, 4)
                            .padding(.bottom, 2)
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 22)
                }
                .frame(width: panelWidth)
                .frame(maxHeight: geometry.size.height * 0.74)
                .background(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .fill(Color.black.opacity(0.9))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color(red: 0.3, green: 1, blue: 0.53), lineWidth: 3)
                }
                .shadow(color: Color(red: 0.3, green: 1, blue: 0.53).opacity(0.22), radius: 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

private struct ConnectedTeamRow: View {
    let rank: Int
    let team: ConnectedTeam
    @ObservedObject var session: ConnectedGameSession

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(rank). \(team.name)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                Text("\(team.score) pts")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 1, green: 0.77, blue: 0))
            }
            if !session.isFinished {
                HStack {
                    scoreButton("-1", Color(red: 1, green: 0.4, blue: 0.4), -1)
                    scoreButton("+1", Color(red: 0.3, green: 1, blue: 0.53), 1)
                    scoreButton("+2", Color(red: 1, green: 0.77, blue: 0), 2)
                    scoreButton("+3", Color(red: 1, green: 0.77, blue: 0), 3)
                }

                Button("RETIRER") { session.removeTeam(team) }
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 1, green: 0.45, blue: 0.45))
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Color.black.opacity(0.22))
                    .clipShape(Capsule())
                    .overlay {
                        Capsule().stroke(Color(red: 1, green: 0.45, blue: 0.45).opacity(0.6), lineWidth: 1)
                    }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(red: 0.3, green: 1, blue: 0.53).opacity(0.6), lineWidth: 1)
        }
    }

    private func scoreButton(_ title: String, _ color: Color, _ delta: Int) -> some View {
        Button(title) { session.changeScore(for: team, by: delta) }
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(Color.black.opacity(0.24))
            .clipShape(Capsule())
            .overlay {
                Capsule().stroke(color.opacity(0.72), lineWidth: 1)
            }
    }
}

private struct ConnectedBuzzerStatus: View {
    @ObservedObject var session: ConnectedGameSession

    private var title: String {
        if let name = session.firstBuzzPlayerName {
            return "Premier buzz : \(name)"
        }
        return session.buzzOpen ? "BUZZER OUVERT" : "Buzzer en attente"
    }

    private var subtitle: String {
        if session.firstBuzzPlayerName != nil {
            return "Attribue les points, puis relance une carte ou rejoue le son."
        }
        return session.buzzOpen ? "Les joueurs peuvent buzzer maintenant." : "Le buzzer s’active automatiquement au lancement du son."
    }

    private var tint: Color {
        if session.firstBuzzPlayerName != nil {
            return Color(red: 1, green: 0.77, blue: 0)
        }
        return session.buzzOpen ? Color(red: 0.3, green: 1, blue: 0.53) : .white.opacity(0.58)
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(tint)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)

            if session.buzzOpen || session.firstBuzzPlayerName != nil {
                Button("RÉINITIALISER LE BUZZER") {
                    session.resetBuzzer()
                }
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 1, green: 0.77, blue: 0))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Color.black.opacity(0.22))
                .clipShape(Capsule())
                .overlay {
                    Capsule().stroke(Color(red: 1, green: 0.77, blue: 0).opacity(0.65), lineWidth: 1)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(tint.opacity(0.72), lineWidth: 1.2)
        }
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
