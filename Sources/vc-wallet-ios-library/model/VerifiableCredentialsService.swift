//
//  VerifiableCredentialsService.swift
//
//
//  Created by 小林弘和 on 2024/10/07.
//

import Foundation

public class VerifiableCredentialsService {

  private let walletClientConfigurationRepository: WalletClientConfigurationRepository
  private let verifiableCredentialRecordRepository: VerifiableCredentialRecordRepository
  private let httpClient: HttpClient

  public init(
    walletClientConfigurationRepository: WalletClientConfigurationRepository,
    verifiableCredentialRecordRepository: VerifiableCredentialRecordRepository
  ) {
    self.walletClientConfigurationRepository = walletClientConfigurationRepository
    self.verifiableCredentialRecordRepository = verifiableCredentialRecordRepository
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

  public func requestTokenWithPreAuthorizedCode(
    url: String,
    clientId: String,
    preAuthorizationCode: String,
    txCode: String?
  ) async throws -> TokenResponse {

    var tokenRequest =
      [
        "client_id": clientId,
        "grant_type": "urn:ietf:params:oauth:grant-type:pre-authorized_code",
        "pre-authorized_code": preAuthorizationCode,
      ]
    if let txCodeValue = txCode {
      tokenRequest["tx_code"] = txCodeValue
    }

    let tokenRequestHeaders: [String: String] = [
      "Content-Type": "application/x-www-form-urlencoded"
    ]

    return try await httpClient.post(
      url: url, headers: tokenRequestHeaders, body: tokenRequest, responseType: TokenResponse.self)
  }

  func requestCredential(
    url: String,
    dpopJwt: String? = nil,
    accessToken: String,
    verifiableCredentialType: VerifiableCredentialsType,
    vct: String? = nil,
    proof: [String: Any]? = nil
  ) async throws -> CredentialResponse {

    var credentialRequest: [String: Any] = [
      "format": verifiableCredentialType.rawValue,
      "doctype": verifiableCredentialType.doctype,
    ]

    if let vct = vct {
      credentialRequest["vct"] = vct
    }

    if let proof = proof {
      credentialRequest["proof"] = proof
    }

    var credentialRequestHeader: [String: String]
    if let dpopJwt = dpopJwt {
      credentialRequestHeader = [
        "Authorization": "DPoP \(accessToken)",
        "DPoP": dpopJwt,
      ]
    } else {
      credentialRequestHeader = [
        "Authorization": "Bearer \(accessToken)"
      ]
    }

    credentialRequestHeader["Content-Type"] = "application/json"

    return try await httpClient.post(
      url: url,
      headers: credentialRequestHeader,
      body: credentialRequest,
      responseType: CredentialResponse.self
    )
  }

  public func getJwksConfiguration(jwtVcIssuerEndpoint: String) async throws -> JwtVcConfiguration {
    return try await httpClient.get(url: jwtVcIssuerEndpoint, responseType: JwtVcConfiguration.self)
  }

  public func getJwks(jwtVcConfiguration: JwtVcConfiguration) async throws -> String {
    if let jwks = jwtVcConfiguration.jwks {
      return jwks
    }
    if let jwksUri = jwtVcConfiguration.jwksUri {
      return try await httpClient.get(url: jwksUri, responseType: String.self)
    }
    throw VerifiableCredentialsError.invalidJwtVcConfiguration("found neither jwks nor jwksUri")
  }

  public func registerCredential(
    subject: String,
    verifiableCredentialsRecord: VerifiableCredentialsRecord
  ) {

    verifiableCredentialRecordRepository.register(sub: subject, record: verifiableCredentialsRecord)
  }

  func registerClientConfiguration(oidcMetadata: OidcMetadata) async -> ClientConfiguration {
    do {
      //FIXME dynamic setting
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
