//
//  VerifiableCredentialRecordDataSource.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/13.
//

import Foundation

public final class VerifiableCredentialRecordDataSource: VerifiableCredentialRecordRepository,
  Sendable
{

  let keyPrefix = "verifiable_credential_"

  public init() {}

  // Register a new record
  public func register(sub: String, record: VerifiableCredentialsRecord) {
    let key = "\(keyPrefix)\(sub)"
    var records = find(sub: sub)?.values ?? []
    records.append(record)
    saveRecords(key: key, records: records)
  }

  // Find all records for a given subject
  public func find(sub: String) -> VerifiableCredentialsRecords? {
    let key = "\(keyPrefix)\(sub)"
    if let data = UserDefaults.standard.data(forKey: key),
      let records = try? JSONDecoder().decode([VerifiableCredentialsRecord].self, from: data)
    {
      return VerifiableCredentialsRecords(values: records)
    }
    return nil
  }

  // Find records by issuer
  public func find(sub: String, credentialIssuer: String) -> VerifiableCredentialsRecords? {
    if let records = find(sub: sub)?.values {
      let filteredRecords = records.filter { $0.issuer == credentialIssuer }
      return VerifiableCredentialsRecords(values: filteredRecords)
    }
    return nil
  }

  // Get all records as a collection
  public func getAllAsCollection(sub: String) -> VerifiableCredentialsRecords? {
    return find(sub: sub)
  }

  // Save records to UserDefaults
  private func saveRecords(key: String, records: [VerifiableCredentialsRecord]) {
    if let data = try? JSONEncoder().encode(records) {
      UserDefaults.standard.set(data, forKey: key)
      Logger.shared.debug("Saved records to UserDefaults: \(key)")
    }
  }
}
