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
        static let phone = "auth.phone"
        static let token = "auth.token"
        static let name = "auth.name"
    }

    private let client: any APIClient
    private let defaults: UserDefaults
    private let keychain: KeychainStore
    /// Префикс ключей. Демо-режим живёт в своём пространстве, иначе вход
    /// на показе затирал бы настоящий токен, а выход из демо — уносил его.
    private let namespace: String

    /// Контакт для лавки. `nil` — человек его не указал, и это нормально.
    private(set) var phone: String?
    private(set) var name: String
    private(set) var token: String?

    var isSignedIn: Bool {
        token != nil
    }

    /// Номер в человеческом виде, или пусто, если его не давали.
    var formattedPhone: String {
        guard let phone, phone.hasPrefix(Self.countryCode) else { return phone ?? "" }
        return "\(Self.countryCode) \(Self.mask(String(phone.dropFirst(Self.countryCode.count))))"
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
        self.phone = defaults.string(forKey: namespace + Key.phone)
        self.name = defaults.string(forKey: namespace + Key.name) ?? ""
        self.token = keychain.string(for: namespace + Key.token)
    }

    /// Стереть сессию пространства целиком — нужно при выходе из демо-режима.
    static func clear(
        namespace: String,
        defaults: UserDefaults = .standard,
        keychain: KeychainStore = KeychainStore()
    ) {
        defaults.removeObject(forKey: namespace + Key.phone)
        defaults.removeObject(forKey: namespace + Key.name)
        keychain.removeValue(for: namespace + Key.token)
    }

    /// Обменять identity-токен провайдера на наш. Подпись проверяет сервер:
    /// приложение не разбирает токен и ничего в нём не решает.
    func signIn(provider: AuthProvider, identityToken: String, name: String) async throws {
        let session = try await client.signIn(
            provider: provider,
            identityToken: identityToken,
            name: name
        )
        apply(session)
    }

    /// Телефон как контакт: пустая строка стирает его.
    func updatePhone(_ value: String) async throws {
        guard let token else { throw APIError.notAuthenticated }
        apply(try await client.updatePhone(value, token: token))
    }

    private func apply(_ session: AuthSession) {
        token = session.token
        phone = session.phone
        name = session.name
        keychain.set(session.token, for: namespace + Key.token)
        if let phone = session.phone {
            defaults.set(phone, forKey: namespace + Key.phone)
        } else {
            defaults.removeObject(forKey: namespace + Key.phone)
        }
        defaults.set(session.name, forKey: namespace + Key.name)
    }

    func signOut() {
        token = nil
        phone = nil
        name = ""
        keychain.removeValue(for: namespace + Key.token)
        defaults.removeObject(forKey: namespace + Key.phone)
        defaults.removeObject(forKey: namespace + Key.name)
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
