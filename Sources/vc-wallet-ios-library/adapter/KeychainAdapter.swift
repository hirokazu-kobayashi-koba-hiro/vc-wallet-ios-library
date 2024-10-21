//
//  KeychainAdapter.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/16.
//

import Foundation
import Security

public class KeychainAdapter {

  func register(value: String, forKey key: String) throws {
    guard let data = value.data(using: .utf8) else {
      throw KeychainError.invalidData("failed to convert value to data")
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
    ]

    SecItemDelete(query as CFDictionary)

    let status = SecItemAdd(query as CFDictionary, nil)

    if status != errSecSuccess {
      throw KeychainError.failedRegistration("failed registration to keychain")
    }
  }

  // MARK: - Find (Retrieve) an item from the Keychain
  func find(forKey key: String) -> String? {
    // Create the query for retrieving the item
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var item: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    // Check if the item exists and convert it back to String
    if status == errSecSuccess, let data = item as? Data,
      let value = String(data: data, encoding: .utf8)
    {
      return value
    }

    return nil
  }

  // MARK: - Delete an item from the Keychain
  func delete(forKey key: String) -> Bool {
    // Create the query for deleting the item
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
    ]

    let status = SecItemDelete(query as CFDictionary)

    return status == errSecSuccess
  }
}

enum KeychainError: Error {
  case invalidData(_ description: String? = nil)
  case failedRegistration(_ description: String? = nil)
}
