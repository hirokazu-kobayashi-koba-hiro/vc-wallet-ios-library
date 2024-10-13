//
//  CredentialIssuanceResultDataSource.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/13.
//

import Foundation

public final class CredentialIssuanceResultDataSource: CredentialIssuanceResultRepository, Sendable
{

  let keyPrefix = "credential_issuance_result_"

  public init() {}

  public func register(subject: String, credentialIssuanceResult: CredentialIssuanceResult) {
    var records = find(subject: subject)
    records.append(credentialIssuanceResult)
    saveRecords(subject: subject, records: records)
  }

  public func find(subject: String) -> [CredentialIssuanceResult] {
    let key = "\(keyPrefix)\(subject)"
    guard let data = UserDefaults.standard.data(forKey: key),
      let records = try? JSONDecoder().decode([CredentialIssuanceResult].self, from: data)
    else {
      return []
    }
    return records
  }

  public func get(subject: String, id: String) throws -> CredentialIssuanceResult {
    let records = find(subject: subject)
    guard let record = records.first(where: { $0.id == id }) else {
      throw VerifiableCredentialsError.notFoundCredentialIssuanceResult(
        "not found credential issuance result \(subject), \(id)")
    }
    return record
  }

  public func update(subject: String, credentialIssuanceResult: CredentialIssuanceResult) {
    var records = find(subject: subject)
    if let index = records.firstIndex(where: { $0.id == credentialIssuanceResult.id }) {
      records[index] = credentialIssuanceResult
      saveRecords(subject: subject, records: records)
    }
  }

  public func delete(subject: String, id: String) {
    var records = find(subject: subject)
    records.removeAll { $0.id == id }
    saveRecords(subject: subject, records: records)
  }

  private func saveRecords(subject: String, records: [CredentialIssuanceResult]) {
    let key = "\(keyPrefix)\(subject)"
    if let data = try? JSONEncoder().encode(records) {
      UserDefaults.standard.set(data, forKey: key)
    }
  }
}
