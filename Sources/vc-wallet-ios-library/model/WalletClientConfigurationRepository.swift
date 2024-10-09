//
//  WalletClientConfigurationRepository.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/09.
//

public protocol WalletClientConfigurationRepository {
  func register(issuer: String, configuration: ClientConfiguration) throws

  func find(issuer: String) throws -> ClientConfiguration?
}
