import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreImage.CIFilterBuiltins

struct ConnectedTeam: Identifiable {
    let id: String
    let name: String
    let score: Int
}

struct ConnectedBuzz: Identifiable {
    let id: String
    let playerName: String
    let round: Int
    let createdAt: Date?
}

struct ScoreChange {
    let id = UUID()
    let appliedScore: Int
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
    @Published private(set) var synchronized = false
    @Published private(set) var buzzOpen = false
    @Published private(set) var buzzRound = 0
    @Published private(set) var firstBuzzPlayerName: String?
    @Published private(set) var firstBuzzAlertName: String?
    @Published private(set) var buzzes: [ConnectedBuzz] = []
    @Published var errorMessage: String?
    private let db = Firestore.firestore()
    private var playerListener: ListenerRegistration?
    private var gameListener: ListenerRegistration?
    private var buzzListener: ListenerRegistration?
    private var generation = 0
    private var receivedServerSnapshot = false
    private var lastAlertedBuzzRound = 0
    private var history: [ScoreChange] = []
    private var latestBuzzes: [ConnectedBuzz] = []
    private var expiryTask: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var retryCount = 0
    private var listening = false

    init() {
        let defaults = UserDefaults.standard
        gameCode = defaults.string(forKey: "connectedGameCode") ?? Self.newCode()
        pin = defaults.string(forKey: "connectedGamePIN") ?? Self.newPIN()
        isActive = defaults.bool(forKey: "connectedGameActive")
        isFinished = defaults.bool(forKey: "connectedGameFinished")
        if isActive { listenForPlayers() }
    }
    private(set) var playbackTicket: (code: String, round: Int)?
    var joinURL: URL { URL(string: "https://zikafrica-56a1e.web.app/?game=\(gameCode)")! }
    var canUndo: Bool { !history.isEmpty && !isFinished && !isLoading }
    func createGame() {
        guard !isActive, !isLoading else { return }
        isLoading = true; errorMessage = nil
        authenticate { [weak self] uid in self?.create(uid: uid, attempt: 0) }
    }
    private func create(uid: String, attempt: Int) {
        let ref = db.collection("games").document(gameCode)
        let data: [String: Any] = [
            "hostUid": uid, "pin": pin, "status": "open", "buzzOpen": false, "buzzRound": 0,
            "createdAt": FieldValue.serverTimestamp(), "expiresAt": Timestamp(date: Date().addingTimeInterval(43200))
        ]
        db.runTransaction({ tx, errorPointer -> Any? in
            do {
                guard try !tx.getDocument(ref).exists else { throw NSError(domain: "ZikAfrica.Collision", code: 1) }
                tx.setData(data, forDocument: ref)
            } catch { errorPointer?.pointee = error as NSError }
            return nil
        }) { [weak self] _, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    if ((error as NSError).code == FirestoreErrorCode.permissionDenied.rawValue || (error as NSError).domain == "ZikAfrica.Collision") && attempt < 4 {
                        self.gameCode = Self.newCode(); self.pin = Self.newPIN(); self.create(uid: uid, attempt: attempt + 1)
                    } else { self.isLoading = false; self.errorMessage = L("connected_error_create_game") }
                } else {
                    self.isLoading = false; self.isActive = true; self.isFinished = false
                    self.persist(); self.listenForPlayers()
                }
            }
        }
    }
    private func mutate(_ action: @escaping (FirebaseFirestore.Transaction, DocumentReference) throws -> Any?, success: @escaping (Any?) -> Void = { _ in }) {
        guard !isLoading else { errorMessage = L("connected_action_busy"); return }
        isLoading = true; errorMessage = nil
        let code = gameCode, ref = db.collection("games").document(gameCode)
        db.runTransaction({ tx, errorPointer -> Any? in
            do { return try action(tx, ref) }
            catch { errorPointer?.pointee = error as NSError; return nil }
        }) { [weak self] result, error in
            Task { @MainActor in
                guard let self, self.gameCode == code else { return }
                self.isLoading = false
                if error != nil { self.errorMessage = L("connected_action_failed") }
                else { success(result) }
            }
        }
    }
    nonisolated private static func requireOpen(_ snapshot: DocumentSnapshot) throws {
        guard let data = snapshot.data(), data["status"] as? String == "open",
              let expires = data["expiresAt"] as? Timestamp, expires.dateValue() > Date() else {
            throw NSError(domain: "ZikAfrica.Game", code: 1, userInfo: [NSLocalizedDescriptionKey: "Partie fermée ou expirée"])
        }
    }
    func startNewSession() {
        guard !isLoading else { return }
        let recreate = isActive
        let reset = { [self] in
            stopListening(); teams = []; history = []; buzzes = []; latestBuzzes = []
            buzzOpen = false; buzzRound = 0; firstBuzzPlayerName = nil; firstBuzzAlertName = nil
            receivedServerSnapshot = false; lastAlertedBuzzRound = 0
            gameCode = Self.newCode(); pin = Self.newPIN(); isActive = false; isFinished = false
            errorMessage = nil; persist()
            if recreate { createGame() }
        }
        if !isActive { reset(); return }
        mutate({ tx, ref in
            if try tx.getDocument(ref).exists {
                tx.updateData(["status": "closed", "buzzOpen": false, "closedAt": FieldValue.serverTimestamp()], forDocument: ref)
            }
            return nil
        }, success: { _ in reset() })
    }
    func finishGame() {
        guard isActive, !isFinished else { return }
        mutate({ tx, ref in
            tx.updateData(["status": "finished", "buzzOpen": false, "finishedAt": FieldValue.serverTimestamp()], forDocument: ref)
            return nil
        }, success: { [weak self] _ in self?.isFinished = true; self?.buzzOpen = false; self?.firstBuzzAlertName = nil; self?.persist() })
    }
    func changeScore(for team: ConnectedTeam, by delta: Int) {
        guard !isFinished else { return }
        mutate({ tx, ref in
            try Self.requireOpen(tx.getDocument(ref))
            let player = ref.collection("players").document(team.id), snapshot = try tx.getDocument(player)
            guard let data = snapshot.data(), data["removed"] as? Bool != true else { throw NSError(domain: "ZikAfrica.Game", code: 2) }
            let previous = data["score"] as? Int ?? 0, next = min(1000000, max(0, previous + delta))
            tx.updateData(["score": next], forDocument: player)
            return ["previous": previous, "next": next]
        }, success: { [weak self] result in
            guard let values = result as? [String: Int], let previous = values["previous"], let next = values["next"] else { return }
            self?.history.append(ScoreChange(appliedScore: next, teamID: team.id, previousScore: previous))
        })
    }
    func undoLastScore() {
        guard !isFinished, let change = history.last else { return }
        mutate({ tx, ref in
            try Self.requireOpen(tx.getDocument(ref))
            let player = ref.collection("players").document(change.teamID), data = try tx.getDocument(player).data()
            guard data?["removed"] as? Bool != true, data?["score"] as? Int == change.appliedScore else { throw NSError(domain: "ZikAfrica.Game", code: 3) }
            tx.updateData(["score": change.previousScore], forDocument: player); return nil
        }, success: { [weak self] _ in self?.history.removeAll { $0.id == change.id } })
    }
    func removeTeam(_ team: ConnectedTeam) {
        guard !isFinished else { return }
        mutate({ tx, ref in
            try Self.requireOpen(tx.getDocument(ref)); tx.updateData(["removed": true], forDocument: ref.collection("players").document(team.id)); return nil
        }, success: { [weak self] _ in self?.history.removeAll { $0.teamID == team.id } })
    }
    func openBuzzerForPlayback(onReady: @escaping () -> Void) {
        guard isActive else { onReady(); return }
        guard !isFinished else { errorMessage = L("connected_new_required"); return }
        let started = Date()
        mutate({ tx, ref in
            guard Date().timeIntervalSince(started) < 10 else { throw NSError(domain: "ZikAfrica.Game", code: 4) }
            let game = try tx.getDocument(ref); try Self.requireOpen(game)
            let round = game.data()?["buzzRound"] as? Int ?? 0
            tx.updateData(["buzzOpen": true, "buzzRound": round + 1,
                "firstBuzzPlayerId": FieldValue.delete(), "firstBuzzPlayerName": FieldValue.delete(), "firstBuzzAt": FieldValue.delete(),
                "lastPlaybackActionAt": FieldValue.serverTimestamp()], forDocument: ref)
            return round + 1
        }, success: { [weak self] result in
            guard let self, let round = result as? Int else { return }
            self.playbackTicket = (self.gameCode, round); onReady()
        })
    }
    func playbackFailed(_ ticket: (code: String, round: Int)?) {
        guard let ticket else { return }
        let ref = db.collection("games").document(ticket.code)
        db.runTransaction({ tx, errorPointer -> Any? in
            do {
                let game = try tx.getDocument(ref).data()
                if game?["buzzRound"] as? Int == ticket.round && game?["status"] as? String == "open" {
                    tx.updateData(["buzzOpen": false], forDocument: ref)
                }
            } catch { errorPointer?.pointee = error as NSError }
            return nil
        }) { [weak self] _, error in
            Task { @MainActor in
                if let self, self.gameCode == ticket.code, error != nil { self.errorMessage = L("connected_playback_failed") }
            }
        }
    }
    func resetBuzzer() {
        guard isActive, !isFinished else { return }
        mutate({ tx, ref in
            try Self.requireOpen(tx.getDocument(ref))
            tx.updateData(["buzzOpen": false, "firstBuzzPlayerId": FieldValue.delete(), "firstBuzzPlayerName": FieldValue.delete(), "firstBuzzAt": FieldValue.delete()], forDocument: ref)
            return nil
        }, success: { [weak self] _ in self?.firstBuzzAlertName = nil; self?.buzzes = [] })
    }
    func dismissFirstBuzzAlert() { firstBuzzAlertName = nil }
    func listenForPlayers() {
        guard isActive, gameListener == nil else { return }
        listening = true
        let epoch = generation, ref = db.collection("games").document(gameCode)
        gameListener = ref.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self, self.generation == epoch else { return }
                if error != nil { self.listenerFailed(); return }
                guard let snapshot else { return }
                self.synchronized = !snapshot.metadata.isFromCache && !snapshot.metadata.hasPendingWrites
                guard let data = snapshot.data() else {
                    if self.synchronized { self.isFinished = true; self.buzzOpen = false; self.persist(); self.errorMessage = L("connected_missing") }
                    return
                }
                if self.synchronized {
                    self.retryCount = 0
                    if self.errorMessage == L("connected_reconnecting") { self.errorMessage = nil }
                    let expiry = (data["expiresAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    self.isFinished = data["status"] as? String != "open" || expiry <= Date()
                    self.persist(); self.expiryTask?.cancel()
                    if !self.isFinished {
                        self.expiryTask = Task { [weak self] in
                            do { try await Task.sleep(nanoseconds: UInt64(max(0, min(86400, expiry.timeIntervalSinceNow)) * 1_000_000_000)) } catch { return }
                            guard let self else { return }
                            self.isFinished = true; self.buzzOpen = false; self.buzzes = []; self.firstBuzzAlertName = nil
                            self.errorMessage = L("connected_expired"); self.persist()
                        }
                    }
                }
                let round = data["buzzRound"] as? Int ?? 0
                if round != self.buzzRound { self.firstBuzzAlertName = nil }
                self.buzzRound = round; self.buzzOpen = !self.isFinished && data["buzzOpen"] as? Bool == true
                self.firstBuzzPlayerName = data["firstBuzzPlayerName"] as? String
                if self.synchronized {
                    if self.receivedServerSnapshot, !self.isFinished, let name = self.firstBuzzPlayerName, round > self.lastAlertedBuzzRound { self.firstBuzzAlertName = name }
                    if self.firstBuzzPlayerName != nil { self.lastAlertedBuzzRound = round }
                    self.receivedServerSnapshot = true
                }
                self.refreshBuzzOrder()
            }
        }
        playerListener = ref.collection("players").addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self, self.generation == epoch else { return }
                if error != nil { self.listenerFailed(); return }
                var updatedTeams: [ConnectedTeam] = []
                for document in snapshot?.documents ?? [] {
                    let data = document.data()
                    if data["removed"] as? Bool == true { continue }
                    let name = data["name"] as? String ?? "Équipe"
                    let score = data["score"] as? Int ?? 0
                    updatedTeams.append(ConnectedTeam(id: document.documentID, name: name, score: score))
                }
                updatedTeams.sort { left, right in
                    if left.score == right.score { return left.id < right.id }
                    return left.score > right.score
                }
                self.teams = updatedTeams
            }
        }
        buzzListener = ref.collection("buzzes").addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self, self.generation == epoch else { return }
                if error != nil { self.listenerFailed(); return }
                var updatedBuzzes: [ConnectedBuzz] = []
                for document in snapshot?.documents ?? [] {
                    let data = document.data()
                    let name = data["playerName"] as? String ?? "Joueur"
                    let round = data["round"] as? Int ?? -1
                    let date = (data["createdAt"] as? Timestamp)?.dateValue()
                    updatedBuzzes.append(ConnectedBuzz(id: document.documentID, playerName: name, round: round, createdAt: date))
                }
                self.latestBuzzes = updatedBuzzes
                self.refreshBuzzOrder()
            }
        }
    }
    private func refreshBuzzOrder() {
        buzzes = buzzOpen ? latestBuzzes.filter { $0.round == buzzRound }.sorted {
            let left = $0.createdAt ?? .distantFuture, right = $1.createdAt ?? .distantFuture
            return left == right ? $0.id < $1.id : left < right
        } : []
    }
    private func detach() {
        generation += 1; synchronized = false
        playerListener?.remove(); playerListener = nil; gameListener?.remove(); gameListener = nil; buzzListener?.remove(); buzzListener = nil
        retryTask?.cancel(); retryTask = nil
    }
    private func listenerFailed() {
        errorMessage = L("connected_reconnecting")
        detach()
        let delay = UInt64(min(30, pow(2, Double(min(retryCount, 5))))) * 1_000_000_000
        retryCount += 1
        retryTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: delay) } catch { return }
            guard let self, self.listening else { return }; self.listenForPlayers()
        }
    }
    func stopListening() { listening = false; detach(); expiryTask?.cancel() }
    private func authenticate(completion: @escaping (String) -> Void) {
        if let uid = Auth.auth().currentUser?.uid { completion(uid); return }
        Auth.auth().signInAnonymously { [weak self] result, error in
            Task { @MainActor in
                if let uid = result?.user.uid { completion(uid) }
                else { self?.isLoading = false; self?.errorMessage = L("connected_error_firebase_auth") }
            }
        }
    }
    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(gameCode, forKey: "connectedGameCode"); defaults.set(pin, forKey: "connectedGamePIN")
        defaults.set(isActive, forKey: "connectedGameActive"); defaults.set(isFinished, forKey: "connectedGameFinished")
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
                        Text(session.isFinished ? L("connected_final_ranking") : L("connected_game_title"))
                            .font(.system(size: 29, weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 1, green: 0.77, blue: 0))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.72)
                            .padding(.top, 8)

                        if !session.isActive {
                            Text(L("connected_intro"))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.82))
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .padding(.horizontal, 8)

                            Button(session.isLoading ? L("connected_creating") : L("connected_create_button")) {
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
                                Text(L("connected_scan_qr"))
                                    .font(.system(size: 25, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)

                                QRCodeImage(text: session.joinURL.absoluteString)
                                    .frame(width: qrSize, height: qrSize)
                                    .padding(8)
                                    .background(Color.white)
                            }

                            Text(String(format: L("connected_code_pin_format"), session.gameCode, session.pin))
                                .font(.system(size: 19, weight: .black, design: .rounded))
                                .foregroundStyle(Color(red: 1, green: 0.77, blue: 0))
                                .minimumScaleFactor(0.58)
                                .lineLimit(1)

                            Text(String(format: L("connected_registered_format"), session.teams.count))
                                .font(.system(size: 21, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(red: 0.3, green: 1, blue: 0.53))

                            ConnectedBuzzerStatus(session: session)

                            if session.teams.isEmpty {
                                Text(L("connected_waiting_players"))
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.68))
                            }

                            ForEach(Array(session.teams.enumerated()), id: \.element.id) { index, team in
                                ConnectedTeamRow(rank: index + 1, team: team, session: session)
                            }

                            if !session.isFinished {
                                Button(L("connected_undo_last_point")) { session.undoLastScore() }
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

                                Button(L("connected_finish_game")) { session.finishGame() }
                                    .disabled(session.isLoading)
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

                        Button(L("close_button")) { onClose() }
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
                Text(String(format: L("connected_points_suffix_format"), team.score))
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

                Button(L("connected_remove_button")) { session.removeTeam(team) }
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
            .disabled(session.isLoading)
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
        if session.isLoading { return L("connected_sync_pending") }
        if session.isFinished { return L("connected_status_finished") }
        if !session.synchronized { return L("connected_status_reconnecting") }
        if let name = session.firstBuzzPlayerName {
            return String(format: L("connected_first_buzz_format"), name)
        }
        return session.buzzOpen ? L("connected_buzzer_open") : L("connected_buzzer_waiting")
    }

    private var subtitle: String {
        if session.firstBuzzPlayerName != nil {
            return L("connected_buzzer_hint_assign")
        }
        return session.buzzOpen ? L("connected_buzzer_hint_open") : L("connected_buzzer_hint_idle")
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
                if !session.buzzes.isEmpty {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(L("connected_buzz_order"))
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                            .tracking(1.2)

                        ForEach(Array(session.buzzes.enumerated()), id: \.element.id) { index, buzz in
                            HStack(spacing: 8) {
                                Text("\(index + 1)")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundStyle(.black)
                                    .frame(width: 24, height: 24)
                                    .background(index == 0 ? Color(red: 1, green: 0.77, blue: 0) : Color.white.opacity(0.72))
                                    .clipShape(Circle())

                                Text(buzz.playerName)
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(index == 0 ? Color(red: 1, green: 0.77, blue: 0) : .white)
                                    .lineLimit(1)

                                Spacer()
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.26))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button(L("connected_reset_buzzer")) {
                    session.resetBuzzer()
                }
                .disabled(session.isLoading)
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
