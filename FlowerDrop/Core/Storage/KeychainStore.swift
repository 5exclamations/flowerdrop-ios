import Foundation
import Security

/// Токен живёт в Keychain, а не в UserDefaults: UserDefaults — это plist
/// в песочнице, он уезжает в бэкапы и читается с разлоченного устройства.
struct KeychainStore {
    let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.texa.flowerdrop") {
        self.service = service
    }

    func string(for account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard
            SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
            let data = item as? Data
        else { return nil }

        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    func set(_ value: String, for account: String) -> Bool {
        let data = Data(value.utf8)
        let query = baseQuery(account: account)

        let attributes: [String: Any] = [kSecValueData as String: data]
        let updated = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updated == errSecSuccess { return true }

        var insert = query
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
    }

    @discardableResult
    func removeValue(for account: String) -> Bool {
        SecItemDelete(baseQuery(account: account) as CFDictionary) == errSecSuccess
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
