//
//  VerifiableCredentialsService.swift
//
//
//  Created by 小林弘和 on 2024/10/07.
//

import Foundation

public class VerifiableCredentialsService {

  private let httpClient = HttpClient(sessionConfiguration: URLSessionConfiguration.ephemeral)

  public func getCredentialOffer(credentialOfferRequest: CredentialOfferRequest) async throws
    -> CredentialOffer
  {

    if let credentialOfferUri = credentialOfferRequest.credentialOfferUri() {
      let response = try await httpClient.get(url: credentialOfferUri)
      let creator = CredentialOfferCreator(response)
      return try creator.create()
    }

    if let credentialOffer = credentialOfferRequest.credentialOffer() {
      let data = credentialOffer.data(using: .utf8)!
      let jsonObject = readFromJson(data)
      guard let json = jsonObject else {
        throw VerifiableCredentialsError.invalidCredentialOffer(
          "CredentialOffer is invalid json format")
      }
      let creator = CredentialOfferCreator(json)
      return try creator.create()
    }

    Logger.shared.error("neither contain credentialOfferUri or credentialOffer")
    throw VerifiableCredentialsError.invalidCredentialOffer(
      "neither contain credentialOfferUri or credentialOffer")
  }

  public func getCredentialIssuerMetadata(url: String) async throws -> CredentialIssuerMetadata {

    return try await httpClient.get(url: url, responseType: CredentialIssuerMetadata.self)
  }

  public func getOidcMetadata(url: String) async throws -> OidcMetadata {

    return try await httpClient.get(url: url, responseType: OidcMetadata.self)
  }
}
