import Foundation
import Security

protocol TokenStore: AnyObject {
    var tokens: AuthTokens? { get set }
}

/// Persists the auth token pair in the Keychain (this-device-only, after first unlock).
final class KeychainTokenStore: TokenStore {
    private let service: String
    private let account = "auth.tokens"

    init(service: String = "com.letsraffle.ios.auth") {
        self.service = service
    }

    /// In-memory copy so the session keeps working even if a Keychain write fails.
    private var cache: AuthTokens??

    var tokens: AuthTokens? {
        get {
            if let cache { return cache }
            let stored = Keychain.read(service: service, account: account)
                .flatMap { try? JSONDecoder().decode(AuthTokens.self, from: $0) }
            cache = .some(stored)
            return stored
        }
        set {
            cache = .some(newValue)
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                Keychain.write(data, service: service, account: account)
            } else {
                Keychain.delete(service: service, account: account)
            }
        }
    }
}

final class InMemoryTokenStore: TokenStore {
    var tokens: AuthTokens?

    init(tokens: AuthTokens? = nil) {
        self.tokens = tokens
    }
}

/// Minimal generic-password Keychain wrapper.
enum Keychain {
    static func read(service: String, account: String) -> Data? {
        var query = baseQuery(service: service, account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    static func write(_ data: Data, service: String, account: String) {
        let query = baseQuery(service: service, account: account)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert.merge(attributes) { $1 }
            SecItemAdd(insert as CFDictionary, nil)
        }
    }

    static func delete(service: String, account: String) {
        SecItemDelete(baseQuery(service: service, account: account) as CFDictionary)
    }

    private static func baseQuery(service: String, account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
