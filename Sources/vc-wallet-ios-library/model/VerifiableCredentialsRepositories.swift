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

public protocol VerifiableCredentialRecordRepository {
  func register(sub: String, record: VerifiableCredentialsRecord)
  func find(sub: String) -> VerifiableCredentialsRecords?
  func getAllAsCollection(sub: String) -> VerifiableCredentialsRecords?
  func find(sub: String, credentialIssuer: String) -> VerifiableCredentialsRecords?
}
