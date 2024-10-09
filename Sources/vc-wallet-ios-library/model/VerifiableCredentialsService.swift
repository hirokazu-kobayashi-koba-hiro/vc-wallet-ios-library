//
//  VerifiableCredentialsService.swift
//
//
//  Created by 小林弘和 on 2024/10/07.
//

import Foundation

public class VerifiableCredentialsService {

  private let walletClientConfigurationRepository: WalletClientConfigurationRepository
  private let httpClient: HttpClient

  public init(walletClientConfigurationRepository: WalletClientConfigurationRepository) {
    self.walletClientConfigurationRepository = walletClientConfigurationRepository
    self.httpClient = HttpClient(sessionConfiguration: URLSessionConfiguration.ephemeral)
  }

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

  public func getOrRegisterClientConfiguration(oidcMetadata: OidcMetadata) async throws
    -> ClientConfiguration
  {
    let walletClientConfiguration = try walletClientConfigurationRepository.find(
      issuer: oidcMetadata.issuer)
    if let walletClientConfiguration {
      return walletClientConfiguration
    }

    let clientConfiguration = await registerClientConfiguration(oidcMetadata: oidcMetadata)
    try walletClientConfigurationRepository.register(
      issuer: oidcMetadata.issuer, configuration: clientConfiguration)
    return clientConfiguration

  }

  func registerClientConfiguration(oidcMetadata: OidcMetadata) async -> ClientConfiguration {
    do {
      let redirectUris = [
        "org.idp.verifiable.credentials://dev-l6ns7qgdx81yv2rs.us.auth0.com/android/org.idp.wallet.app/callback"
      ]
      let grantTypes = oidcMetadata.grantTypesSupported ?? []
      let responseTypes: [String] = []
      let clientName = "verifiable_credentials_library"
      let scope = oidcMetadata.scopesSupportedForVcAsString()

      let requestBody: [String: Any] = [
        "redirect_uris": redirectUris,
        "grant_types": grantTypes,
        "response_types": responseTypes,
        "client_Uri": clientName,
        "scope": scope,
        "application_type": "native",
        "token_endpoint_auth_method": "none",
      ]

      guard let registrationEndpoint = oidcMetadata.registrationEndpoint else {
        throw VerifiableCredentialsError.vcIssuerUnsupportedDynamicClientRegistration(
          "Not configured registration endpoint for issuer: \(oidcMetadata.issuer)"
        )
      }

      let response = try await httpClient.post(url: registrationEndpoint, body: requestBody)

      return ClientConfiguration(
        clientId: response["client_id"] as? String ?? "",
        clientSecret: response["client_secret"] as? String ?? "",
        redirectUris: redirectUris,
        grantTypes: grantTypes,
        responseTypes: responseTypes,
        clientUri: clientName,
        scope: scope
      )
    } catch {
      Logger.shared.error("registerClientConfiguration failed: \(error.localizedDescription)")
      return ClientConfiguration(clientId: "218232426")
    }
  }
}
