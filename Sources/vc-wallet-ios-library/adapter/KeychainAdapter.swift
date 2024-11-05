//
//  KeychainAdapter.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/11/06.
//

import Foundation
import Security

public class KeychainAdapter {

  public func register(key: String, data: Data) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
    ]

    let statusOfAdd = SecItemAdd(query as CFDictionary, nil)

    if statusOfAdd != errSecSuccess {
      Logger.shared.error("Failed to register keychain item. \(key)")
      throw KeychainError.failedRegister(
        "Failed to register keychain item.", cause: statusOfAdd.description)
    }
  }

  public func find(key: String) -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecReturnData as String: kCFBooleanTrue,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var object: AnyObject?

    let statusOfFind = SecItemCopyMatching(query as CFDictionary, &object)

    if statusOfFind == errSecSuccess && object as? Data != nil {
      return object as? Data
    }
    return nil
  }

  public func delete(key: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
    ]

    let statusOfDelete = SecItemDelete(query as CFDictionary)
    if statusOfDelete != errSecSuccess {
      Logger.shared.error("Failed to delete keychain item. \(key)")
      throw KeychainError.failedDelete(
        "Failed to register keychain item.", cause: statusOfDelete.description)
    }
  }
}

public enum KeychainError: Error {
  case failedRegister(_ description: String, cause: String)
  case failedDelete(_ description: String, cause: String)
}
