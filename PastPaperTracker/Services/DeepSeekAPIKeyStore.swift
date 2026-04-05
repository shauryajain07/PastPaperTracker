import Foundation
import Security

@MainActor
final class DeepSeekAPIKeyStore: ObservableObject {
    @Published private(set) var hasStoredKey = false

    private let service = "com.shauryajain.PastPaperTracker.DeepSeek"
    private let account = "api-key"

    init() {
        refreshState()
    }

    func loadKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard
            status == errSecSuccess,
            let data = result as? Data,
            let key = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return key
    }

    func saveKey(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw DeepSeekAPIKeyStoreError.emptyKey
        }

        let data = Data(trimmed.utf8)
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if updateStatus == errSecItemNotFound {
            let addStatus = SecItemAdd(attributes as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw DeepSeekAPIKeyStoreError.keychainStatus(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw DeepSeekAPIKeyStoreError.keychainStatus(updateStatus)
        }

        refreshState()
    }

    func clearKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw DeepSeekAPIKeyStoreError.keychainStatus(status)
        }

        refreshState()
    }

    func refreshState() {
        hasStoredKey = loadKey() != nil
    }
}

enum DeepSeekAPIKeyStoreError: LocalizedError {
    case emptyKey
    case keychainStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .emptyKey:
            return "Enter a DeepSeek API key before saving."
        case .keychainStatus(let status):
            return "Keychain error (\(status))."
        }
    }
}
