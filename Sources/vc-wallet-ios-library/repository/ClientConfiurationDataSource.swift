//
//  ClientConfiurationDataSource.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/09.
//

import Foundation

public class ClientConfiurationDataSource: WalletClientConfigurationRepository {

  public func register(issuer: String, configuration: ClientConfiguration) throws {

    let value = writeToJson(configuration)
    guard let value else {
      throw VerifiableCredentialsError.invalidClientConfiguration(
        "client configuration is invalid. client configuration can not be parsed to json")
    }
    
    UserDefaults.standard.set(value, forKey: issuer)
  }

  public func find(issuer: String) throws -> ClientConfiguration? {

    guard let value = UserDefaults.standard.string(forKey: issuer) else {
      return nil
    }

    guard
      let data = value.data(using: .utf8),
      let client = readFromJson(
        data, responseType: ClientConfiguration.self, enableSnakeCase: false)
    else {
      throw VerifiableCredentialsError.invalidClientConfiguration(
        "client configuration is invalid. client configuration can not be parsed to json")
    }

    return client
  }

}
