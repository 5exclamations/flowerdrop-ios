import Foundation

/// Состояние входа. Переживает перезапуск: номер лежит в UserDefaults —
/// том же хранилище, что и `@AppStorage`.
///
/// `@AppStorage` — это `DynamicProperty`, он работает только внутри вью,
/// поэтому в наблюдаемом сторе используем UserDefaults напрямую.
@MainActor
@Observable
final class AuthStore {

    /// Мок вместо SMS, пока нет бэкенда.
    nonisolated static let mockCode = "1111"
    /// Азербайджанский номер без кода страны.
    nonisolated static let phoneLength = 9
    nonisolated static let countryCode = "+994"

    private enum Key {
        static let phone = "auth.phoneDigits"
    }

    private let defaults: UserDefaults

    private(set) var phoneDigits: String

    var isSignedIn: Bool {
        phoneDigits.count == Self.phoneLength
    }

    /// Номер в человеческом виде: +994 XX XXX XX XX.
    var formattedPhone: String {
        "\(Self.countryCode) \(Self.mask(phoneDigits))"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.phoneDigits = defaults.string(forKey: Key.phone) ?? ""
    }

    func signIn(phoneDigits: String) {
        self.phoneDigits = phoneDigits
        defaults.set(phoneDigits, forKey: Key.phone)
    }

    func signOut() {
        phoneDigits = ""
        defaults.removeObject(forKey: Key.phone)
    }

    func isValid(code: String) -> Bool {
        code == Self.mockCode
    }

    /// Маска ввода: XX XXX XX XX.
    nonisolated static func mask(_ digits: String) -> String {
        let groups = [2, 3, 2, 2]
        var rest = Substring(digits.prefix(phoneLength))
        var parts: [String] = []

        for size in groups where !rest.isEmpty {
            parts.append(String(rest.prefix(size)))
            rest = rest.dropFirst(size)
        }

        return parts.joined(separator: " ")
    }
}
