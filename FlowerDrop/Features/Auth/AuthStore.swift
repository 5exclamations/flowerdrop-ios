import Foundation

/// Состояние входа. Токен лежит в Keychain, номер — в UserDefaults:
/// номер не секрет, а токен даёт доступ к резервам пользователя.
@MainActor
@Observable
final class AuthStore {

    /// Азербайджанский номер без кода страны.
    nonisolated static let phoneLength = 9
    nonisolated static let countryCode = "+994"

    private enum Key {
        static let phone = "auth.phoneDigits"
        static let token = "auth.token"
    }

    private let client: any APIClient
    private let defaults: UserDefaults
    private let keychain: KeychainStore
    /// Префикс ключей. Демо-режим живёт в своём пространстве, иначе вход
    /// на показе затирал бы настоящий токен, а выход из демо — уносил его.
    private let namespace: String

    private(set) var phoneDigits: String
    private(set) var token: String?

    var isSignedIn: Bool {
        token != nil
    }

    /// Номер в человеческом виде: +994 XX XXX XX XX.
    var formattedPhone: String {
        "\(Self.countryCode) \(Self.mask(phoneDigits))"
    }

    init(
        client: any APIClient,
        namespace: String = "",
        defaults: UserDefaults = .standard,
        keychain: KeychainStore = KeychainStore()
    ) {
        self.client = client
        self.namespace = namespace
        self.defaults = defaults
        self.keychain = keychain
        self.phoneDigits = defaults.string(forKey: namespace + Key.phone) ?? ""
        self.token = keychain.string(for: namespace + Key.token)
    }

    /// Стереть сессию пространства целиком — нужно при выходе из демо-режима.
    static func clear(
        namespace: String,
        defaults: UserDefaults = .standard,
        keychain: KeychainStore = KeychainStore()
    ) {
        defaults.removeObject(forKey: namespace + Key.phone)
        keychain.removeValue(for: namespace + Key.token)
    }

    /// Шаг 1: попросить код. Сервер сам нормализует номер.
    @discardableResult
    func requestCode(phoneDigits: String) async throws -> OTPChallenge {
        let challenge = try await client.requestCode(phone: Self.countryCode + phoneDigits)
        self.phoneDigits = phoneDigits
        defaults.set(phoneDigits, forKey: namespace + Key.phone)
        return challenge
    }

    /// Шаг 2: обменять код на токен.
    func verify(code: String) async throws {
        let session = try await client.verifyCode(
            phone: Self.countryCode + phoneDigits,
            code: code
        )
        token = session.token
        keychain.set(session.token, for: namespace + Key.token)
    }

    func signOut() {
        token = nil
        keychain.removeValue(for: namespace + Key.token)
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
