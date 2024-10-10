//
//  VerifiableCredentialsApi.swift
//
//
//  Created by 小林弘和 on 2024/09/28.
//

import Foundation

public final class VerifiableCredentialsApi: @unchecked Sendable {

  public static let shared = VerifiableCredentialsApi()
  private var verifiableCredentialsService: VerifiableCredentialsService?

  public func initialize(verifiableCredentialsService: VerifiableCredentialsService) {
    self.verifiableCredentialsService = verifiableCredentialsService
  }

  public func handlePreAuthorization(subject: String, url: String) async throws {
    guard let service = verifiableCredentialsService else {
      throw VerifiableCredentialsError.systemError(
        "VerifiableCredentialsService is not initialized.")
    }

    let credentialOfferRequest = CredentialOfferRequest(url: url)
    let credentialOfferRequestValidator = CredentialOfferRequestValidator(
      credentialOfferRequest: credentialOfferRequest)
    try credentialOfferRequestValidator.validate()

    let credentialOffer = try await service.getCredentialOffer(
      credentialOfferRequest: credentialOfferRequest)
    guard let preAuthorizedCodeGrant = credentialOffer.preAuthorizedCodeGrant else {
      throw VerifiableCredentialsError.invalidCredentialOffer(
        "PreAuthorizedCode in credential offer response is empty. It is required on pre-authorization-code flow"
      )
    }

    let credentialIssuerMetadata = try await service.getCredentialIssuerMetadata(
      url: credentialOffer.credentialIssuerMetadataEndpoint())
    let oidcMetadata =
      try await service.getOidcMetadata(
        url: credentialIssuerMetadata.getOpenIdConfigurationEndpoint())
    let clientConfiguration = try await service.getOrRegisterClientConfiguration(
      oidcMetadata: oidcMetadata)

  }
}
