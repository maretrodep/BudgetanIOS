import Security
import Foundation

class KeychainService {
    private let accessTokenKey = "com.budgetan.access_token"
    private let refreshTokenKey = "com.budgetan.refresh_token"

    func saveAccessToken(_ token: String) {
        save(token, forKey: accessTokenKey)
    }

    func getAccessToken() -> String? {
        get(forKey: accessTokenKey)
    }

    func saveRefreshToken(_ token: String) {
        save(token, forKey: refreshTokenKey)
    }

    func getRefreshToken() -> String? {
        get(forKey: refreshTokenKey)
    }

    func clearTokens() {
        delete(forKey: accessTokenKey)
        delete(forKey: refreshTokenKey)
    }

    private func save(_ value: String, forKey key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == noErr, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
