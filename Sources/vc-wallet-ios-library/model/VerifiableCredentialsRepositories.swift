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

public protocol CredentialIssuanceResultRepository {
  func register(subject: String, credentialIssuanceResult: CredentialIssuanceResult)

  func find(subject: String) -> [CredentialIssuanceResult]

  func get(subject: String, id: String) throws -> CredentialIssuanceResult

  func update(subject: String, credentialIssuanceResult: CredentialIssuanceResult)

  func delete(subject: String, id: String)
}
