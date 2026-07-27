import Foundation
import SwiftUI

/// Langues disponibles dans ZikAfrica. Le choix est indépendant de la langue système
/// de l'iPhone — l'utilisateur le change librement depuis "Ajust.".
enum AppLanguage: String, CaseIterable, Identifiable {
    case french = "fr"
    case english = "en"
    case arabic = "ar"
    case portuguese = "pt"
    case swahili = "sw"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .french: return "Français"
        case .english: return "English"
        case .arabic: return "العربية"
        case .portuguese: return "Português"
        case .swahili: return "Kiswahili"
        }
    }

    var flag: String {
        switch self {
        case .french: return "🇫🇷"
        case .english: return "🇬🇧"
        case .arabic: return "🇸🇦"
        case .portuguese: return "🇵🇹"
        case .swahili: return "🇰🇪"
        }
    }

    /// Seul l'arabe s'écrit de droite à gauche parmi ces 5 langues.
    var isRightToLeft: Bool {
        self == .arabic
    }
}

/// Source unique de vérité pour la langue actuelle. Persistée entre les lancements.
/// Injectée à la racine de l'app (voir ZikAfricaApp.swift) ; le `.id(...)` posé sur
/// ContentView force un rafraîchissement complet de l'interface au changement de langue,
/// sans avoir besoin de propager @EnvironmentObject dans chaque vue individuellement.
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    private static let storageKey = "zikafrica.language"

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.storageKey)
        }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: Self.storageKey),
           let language = AppLanguage(rawValue: saved) {
            currentLanguage = language
        } else {
            currentLanguage = .french
        }
    }

    func string(_ key: String) -> String {
        guard let entry = Translations.table[key] else {
            // Clé manquante : on préfère afficher la clé plutôt que planter,
            // ça reste visible et facile à repérer en test.
            return key
        }

        return entry[currentLanguage] ?? entry[.french] ?? key
    }
}

/// Raccourci global pour traduire une clé selon la langue actuellement choisie.
/// Exemple : Text(L("rules_title"))
func L(_ key: String) -> String {
    LocalizationManager.shared.string(key)
}
