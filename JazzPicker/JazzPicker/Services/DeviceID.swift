//
//  DeviceID.swift
//  JazzPicker
//

import Foundation
import Security

enum DeviceID {
    private static let keychainKey = "com.jazzpicker.device-id"

    /// Get or create a persistent device ID stored in Keychain.
    /// Persists across app reinstalls.
    static func getOrCreate() -> String {
        // Try to read existing ID from Keychain
        if let existingID = read() {
            return existingID
        }

        // Generate new ID and store it
        let newID = UUID().uuidString
        save(newID)
        return newID
    }

    private static func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let id = String(data: data, encoding: .utf8) else {
            return nil
        }

        return id
    }

    private static func save(_ id: String) {
        guard let data = id.data(using: .utf8) else { return }

        // Delete any existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
