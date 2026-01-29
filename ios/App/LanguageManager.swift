import SwiftUI

// MARK: - App Language

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case korean = "ko"
    case japanese = "ja"
    case chinese = "zh-Hans"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case russian = "ru"
    case dutch = "nl"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .korean: return "한국어"
        case .japanese: return "日本語"
        case .chinese: return "简体中文"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .russian: return "Русский"
        case .dutch: return "Nederlands"
        }
    }
}

// MARK: - Language Manager

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @AppStorage("appLanguage") private var storedLanguage: String = "en"
    @Published private(set) var currentLanguage: AppLanguage = .english

    private init() {
        if let lang = AppLanguage(rawValue: storedLanguage) {
            currentLanguage = lang
        }
    }

    func setLanguage(_ language: AppLanguage) {
        storedLanguage = language.rawValue
        currentLanguage = language
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()

        // Terminate the app - user will need to reopen it with new language
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            exit(0)
        }
    }
}
