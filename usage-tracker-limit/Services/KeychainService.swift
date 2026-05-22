import Foundation
import Security

final class KeychainService {
    private let service = "com.rekhlitskiy.usage-tracker-limit"

    static let shared = KeychainService()
    private init() {}

    var sessionKey: String? {
        get { load(key: "sessionKey") }
        set {
            if let value = newValue { save(key: "sessionKey", value: value) }
            else { delete(key: "sessionKey") }
        }
    }

    var organizationId: String? {
        get { load(key: "organizationId") }
        set {
            if let value = newValue { save(key: "organizationId", value: value) }
            else { delete(key: "organizationId") }
        }
    }

    var organizationName: String? {
        get { load(key: "organizationName") }
        set {
            if let value = newValue { save(key: "organizationName", value: value) }
            else { delete(key: "organizationName") }
        }
    }

    var hasCredentials: Bool {
        guard let sk = sessionKey, let oid = organizationId else { return false }
        return !sk.isEmpty && !oid.isEmpty
    }

    func clearCredentials() {
        delete(key: "sessionKey")
        delete(key: "organizationId")
        delete(key: "organizationName")
    }

    // MARK: - Private

    @discardableResult
    private func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        let attributes = query.merging([kSecValueData as String: data]) { _, new in new }
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    private func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
