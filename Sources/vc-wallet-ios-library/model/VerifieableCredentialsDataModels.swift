//
//  VerifieableCredentialsDataModel.swift
//
//
//  Created by 小林弘和 on 2024/10/07.
//

import Foundation

public struct CredentialOfferRequest {

  let scheme: String?
  let params: [String: String]

  public init(url: String) {
    self.scheme = extractScheme(url)
    self.params = extractQueriesAsSingleMap(url)
  }

  public func credentialOffer() -> String? {
    return params["credential_offer"]
  }

  public func credentialOfferUri() -> String? {
    return params["credential_offer_uri"]
  }
}

public struct CredentialOffer: Sendable {
  let credentialIssuer: String
  let credentialConfigurationIds: [String]
  let preAuthorizedCodeGrant: PreAuthorizedCodeGrant?
  let authorizedCodeGrant: AuthorizedCodeGrant?

  public init(
    credentialIssuer: String, credentialConfigurationIds: [String],
    preAuthorizedCodeGrant: PreAuthorizedCodeGrant? = nil,
    authorizedCodeGrant: AuthorizedCodeGrant? = nil
  ) {
    self.credentialIssuer = credentialIssuer
    self.credentialConfigurationIds = credentialConfigurationIds
    self.preAuthorizedCodeGrant = preAuthorizedCodeGrant
    self.authorizedCodeGrant = authorizedCodeGrant
  }

  func credentialIssuerMetadataEndpoint() -> String {
    return "\(credentialIssuer)/.well-known/openid-credential-issuer"
  }

  func oiddEndpoint() -> String {
    return "\(credentialIssuer)/.well-known/openid-configuration"
  }

  func jwtVcIssuerEndpoint() -> String {
    return "\(credentialIssuer)/.well-known/jwt-vc-issuer"
  }
}

public struct PreAuthorizedCodeGrant: Sendable {
  let preAuthorizedCode: String
  let length: Int?
  let inputMode: String?
  let description: String?

  public init(
    preAuthorizedCode: String, length: Int? = nil, inputMode: String? = nil,
    description: String? = nil
  ) {
    self.preAuthorizedCode = preAuthorizedCode
    self.length = length
    self.inputMode = inputMode
    self.description = description
  }
}

public struct AuthorizedCodeGrant: Sendable {
  let issuerState: String?
  let authorizationServer: String?
}

public struct CredentialIssuerMetadata: Codable {
  let credentialIssuer: String
  let authorizationServers: [String]?
  let credentialEndpoint: String
  let batchCredentialEndpoint: String?
  let deferredCredentialEndpoint: String?
  let notificationEndpoint: String?
  let credentialResponseEncryption: CredentialResponseEncryption?
  let credentialIdentifiersSupported: Bool?
  let signedMetadata: String?
  let display: [Display]?
  let credentialConfigurationsSupported: [String: CredentialConfiguration]

  // Find Credential Configuration
  func findCredentialConfiguration(credential: String) -> CredentialConfiguration? {
    return credentialConfigurationsSupported[credential]
  }

  // Get OpenID Configuration Endpoint
  func getOpenIdConfigurationEndpoint() -> String {
    if let authServers = authorizationServers, !authServers.isEmpty {
      return "\(authServers[0])/.well-known/openid-configuration"
    }
    return "\(credentialIssuer)/.well-known/openid-configuration"
  }

  // Get Verifiable Credentials Type
  func getVerifiableCredentialsType(credentialConfigurationId: String) throws
    -> VerifiableCredentialsType
  {

    guard let format = credentialConfigurationsSupported[credentialConfigurationId]?.format else {
      throw VerifiableCredentialsError.invalidCredentialIssuerMetadata(
        "not found credential configuration (\(credentialConfigurationId))")
    }
    return try VerifiableCredentialsType.of(format: format)
  }

  // Find VCT (Verifiable Credential Type)
  func findVct(credentialConfigurationId: String) -> String? {
    return credentialConfigurationsSupported[credentialConfigurationId]?.vct
  }

  // Get Scope
  func getScope(credentialConfigurationId: String) throws -> String {
    guard let scope = credentialConfigurationsSupported[credentialConfigurationId]?.scope else {
      throw VerifiableCredentialsError.invalidCredentialIssuerMetadata(
        "not found scope configuration, (\(credentialConfigurationId))")
    }
    return scope
  }
}

public enum VerifiableCredentialsType: String {
  case msoMdoc = "mso_mdoc"
  case sdJwt = "vc+sd-jwt"
  case jwtVcJson = "jwt_vc_json"
  case didJwtVc = "did_jwt_vc"
  case jwtVcJsonLd = "jwt_vc_json-ld"
  case ldpVc = "ldp_vc"

  var doctype: String {
    switch self {
    case .msoMdoc:
      return "org.iso.18013.5.1.mDL"
    case .sdJwt, .jwtVcJson, .didJwtVc, .jwtVcJsonLd, .ldpVc:
      return ""
    }
  }

  static func of(format: String) throws -> VerifiableCredentialsType {

    guard let type = VerifiableCredentialsType(rawValue: format) else {
      throw VerifiableCredentialsError.unsupportedCredentialFormat(
        "Not found format (\(format))"
      )
    }
    return type
  }
}

public struct CredentialResponseEncryption: Codable {
  let algValuesSupported: [String]
  let encValuesSupported: [String]
  let encryptionRequired: Bool
}

public struct Display: Codable {
  let name: String?
  let locale: String?
  let logo: Logo?
  let description: String?
  let backgroundColor: String?
  let backgroundImage: BackgroundImage?
  let textColor: String?
}

public struct BackgroundImage: Codable {
  let uri: String
}

public struct Logo: Codable {
  let uri: String
  let altText: String?
}

public struct CredentialConfiguration: Codable {
  let format: String
  let vct: String?
  let scope: String?
  let cryptographicBindingMethodsSupported: [String]?
  let proofTypesSupported: ProofTypesSupported?
  let display: [Display]?

  func getFirstDisplay() -> Display? {
    return display?.first
  }

  func getFirstLogo() -> Logo? {
    return display?.first?.logo
  }

  func findLogo(name: String) -> Logo? {
    return display?.first(where: { $0.name == name })?.logo
  }
}

public struct ProofTypesSupported: Codable {
  let proofSigningAlgValuesSupported: [String]
}

public struct OidcMetadata: Codable, Sendable {
  // OIDD
  let issuer: String
  let authorizationEndpoint: String
  let tokenEndpoint: String
  let userinfoEndpoint: String
  let jwksUri: String
  let registrationEndpoint: String?
  let scopesSupported: [String]?
  let responseTypesSupported: [String]
  let responseModesSupported: [String]?
  let grantTypesSupported: [String]?
  let acrValuesSupported: [String]?
  let subjectTypesSupported: [String]
  let idTokenSigningAlgValuesSupported: [String]
  let idTokenEncryptionAlgValuesSupported: [String]?
  let idTokenEncryptionEncValuesSupported: [String]?
  let userinfoSigningAlgValuesSupported: [String]?
  let userinfoEncryptionAlgValuesSupported: [String]?
  let userinfoEncryptionEncValuesSupported: [String]?
  let requestObjectSigningAlgValuesSupported: [String]?
  let requestObjectEncryptionAlgValuesSupported: [String]?
  let requestObjectEncryptionEncValuesSupported: [String]?
  let tokenEndpointAuthMethodsSupported: [String]?
  let tokenEndpointAuthSigningAlgValuesSupported: [String]?
  let displayValuesSupported: [String]?
  let claimTypesSupported: [String]?
  let claimsSupported: [String]?
  let serviceDocumentation: String?
  let claimsLocalesSupported: Bool?
  let claimsParameterSupported: Bool?
  let requestParameterSupported: Bool?
  let requestUriParameterSupported: Bool?
  let requireRequestUriRegistration: Bool?
  let opPolicyUri: String?
  let opTosUri: String?

  // OAuth2.0 extension
  let revocationEndpoint: String?
  let revocationEndpointAuthMethodsSupported: [String]?
  let revocationEndpointAuthSigningAlgValuesSupported: [String]?
  let introspectionEndpoint: String?
  let introspectionEndpointAuthMethodsSupported: [String]?
  let introspectionEndpointAuthSigningAlgValuesSupported: [String]?
  let codeChallengeMethodsSupported: [String]?
  let tlsClientCertificateBoundAccessTokens: Bool?
  let requireSignedRequestObject: Bool?
  let authorizationResponseIssParameterSupported: Bool?

  // CIBA
  let backchannelTokenDeliveryModesSupported: [String]?
  let backchannelAuthenticationEndpoint: String?
  let backchannelAuthenticationRequestSigningAlgValuesSupported: [String]?
  let backchannelUserCodeParameterSupported: Bool?
  let authorizationDetailsTypesSupported: [String]?

  // JARM
  let authorizationSigningAlgValuesSupported: [String]?
  let authorizationEncryptionAlgValuesSupported: [String]?
  let authorizationEncryptionEncValuesSupported: [String]?

  // PAR
  let pushedAuthorizationRequestEndpoint: String?

  // Dpop
  let dpopSigningAlgValuesSupported: [String]?

  func scopesSupportedForVcAsString() -> String {
    return scopesSupported?
      .filter { $0 != "openid" && $0 != "offline_access" }
      .joined(separator: " ") ?? ""
  }
}

public struct ClientConfiguration: Codable, Sendable {
  let clientId: String
  let clientSecret: String?
  let redirectUris: [String]?
  let tokenEndpointAuthMethod: String?
  let grantTypes: [String]?
  let responseTypes: [String]?
  let clientName: String?
  let clientUri: String?
  let logoUri: String?
  let scope: String?
  let contacts: String?
  let tosUri: String?
  let policyUri: String?
  let jwksUri: String?
  let jwks: String?
  let softwareId: String?
  let softwareVersion: String?
  let requestUris: [String]?
  let backchannelTokenDeliveryMode: String?
  let backchannelClientNotificationEndpoint: String?
  let backchannelAuthenticationRequestSigningAlg: String?
  let backchannelUserCodeParameter: Bool?
  let applicationType: String?
  let idTokenEncryptedResponseAlg: String?
  let idTokenEncryptedResponseEnc: String?
  let authorizationDetailsTypes: [String]?
  let tlsClientAuthSubjectDn: String?
  let tlsClientAuthSanDns: String?
  let tlsClientAuthSanUri: String?
  let tlsClientAuthSanIp: String?
  let tlsClientAuthSanEmail: String?
  let tlsClientCertificateBoundAccessTokens: Bool?
  let authorizationSignedResponseAlg: String?
  let authorizationEncryptedResponseAlg: String?
  let authorizationEncryptedResponseEnc: String?
  let supportedJar: Bool?
  let issuer: String?

  public init(
    clientId: String,
    clientSecret: String? = nil,
    redirectUris: [String]? = nil,
    tokenEndpointAuthMethod: String? = nil,
    grantTypes: [String]? = nil,
    responseTypes: [String]? = nil,
    clientName: String? = nil,
    clientUri: String? = nil,
    logoUri: String? = nil,
    scope: String? = nil,
    contacts: String? = nil,
    tosUri: String? = nil,
    policyUri: String? = nil,
    jwksUri: String? = nil,
    jwks: String? = nil,
    softwareId: String? = nil,
    softwareVersion: String? = nil,
    requestUris: [String]? = nil,
    backchannelTokenDeliveryMode: String? = nil,
    backchannelClientNotificationEndpoint: String? = nil,
    backchannelAuthenticationRequestSigningAlg: String? = nil,
    backchannelUserCodeParameter: Bool? = nil,
    applicationType: String? = nil,
    idTokenEncryptedResponseAlg: String? = nil,
    idTokenEncryptedResponseEnc: String? = nil,
    authorizationDetailsTypes: [String]? = nil,
    tlsClientAuthSubjectDn: String? = nil,
    tlsClientAuthSanDns: String? = nil,
    tlsClientAuthSanUri: String? = nil,
    tlsClientAuthSanIp: String? = nil,
    tlsClientAuthSanEmail: String? = nil,
    tlsClientCertificateBoundAccessTokens: Bool? = nil,
    authorizationSignedResponseAlg: String? = nil,
    authorizationEncryptedResponseAlg: String? = nil,
    authorizationEncryptedResponseEnc: String? = nil,
    supportedJar: Bool? = nil,
    issuer: String? = nil
  ) {
    self.clientId = clientId
    self.clientSecret = clientSecret
    self.redirectUris = redirectUris
    self.tokenEndpointAuthMethod = tokenEndpointAuthMethod
    self.grantTypes = grantTypes
    self.responseTypes = responseTypes
    self.clientName = clientName
    self.clientUri = clientUri
    self.logoUri = logoUri
    self.scope = scope
    self.contacts = contacts
    self.tosUri = tosUri
    self.policyUri = policyUri
    self.jwksUri = jwksUri
    self.jwks = jwks
    self.softwareId = softwareId
    self.softwareVersion = softwareVersion
    self.requestUris = requestUris
    self.backchannelTokenDeliveryMode = backchannelTokenDeliveryMode
    self.backchannelClientNotificationEndpoint = backchannelClientNotificationEndpoint
    self.backchannelAuthenticationRequestSigningAlg = backchannelAuthenticationRequestSigningAlg
    self.backchannelUserCodeParameter = backchannelUserCodeParameter
    self.applicationType = applicationType
    self.idTokenEncryptedResponseAlg = idTokenEncryptedResponseAlg
    self.idTokenEncryptedResponseEnc = idTokenEncryptedResponseEnc
    self.authorizationDetailsTypes = authorizationDetailsTypes
    self.tlsClientAuthSubjectDn = tlsClientAuthSubjectDn
    self.tlsClientAuthSanDns = tlsClientAuthSanDns
    self.tlsClientAuthSanUri = tlsClientAuthSanUri
    self.tlsClientAuthSanIp = tlsClientAuthSanIp
    self.tlsClientAuthSanEmail = tlsClientAuthSanEmail
    self.tlsClientCertificateBoundAccessTokens = tlsClientCertificateBoundAccessTokens
    self.authorizationSignedResponseAlg = authorizationSignedResponseAlg
    self.authorizationEncryptedResponseAlg = authorizationEncryptedResponseAlg
    self.authorizationEncryptedResponseEnc = authorizationEncryptedResponseEnc
    self.supportedJar = supportedJar
    self.issuer = issuer
  }

  func scopes() -> [String] {

    guard let scope else { return [] }
    return scope.split(separator: " ").map { String($0) }
  }
}

public struct TokenResponse: Codable {
  let accessToken: String
  let refreshToken: String?
  let idToken: String?
  let expiresIn: Int64
  let scope: String?
  let cNonce: String?
  let cNonceExpiresIn: Int?

  init(
    accessToken: String,
    refreshToken: String? = nil,
    idToken: String? = nil,
    expiresIn: Int64,
    scope: String? = nil,
    cNonce: String? = nil,
    cNonceExpiresIn: Int? = nil
  ) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.idToken = idToken
    self.expiresIn = expiresIn
    self.scope = scope
    self.cNonce = cNonce
    self.cNonceExpiresIn = cNonceExpiresIn
  }
}

public struct CredentialResponse: Codable {
  let credential: String?
  let transactionId: String?
  let cNonce: String?
  let cNonceExpiresIn: Int?
  let notificationId: String?

  init(
    credential: String? = nil,
    transactionId: String? = nil,
    cNonce: String? = nil,
    cNonceExpiresIn: Int? = nil,
    notificationId: String? = nil
  ) {
    self.credential = credential
    self.transactionId = transactionId
    self.cNonce = cNonce
    self.cNonceExpiresIn = cNonceExpiresIn
    self.notificationId = notificationId
  }
}

public struct JwtVcConfiguration: Codable {
  let issuer: String
  let jwksUri: String?
  let jwks: String?

  public init(issuer: String, jwksUri: String? = nil, jwks: String? = nil) {
    self.issuer = issuer
    self.jwksUri = jwksUri
    self.jwks = jwks
  }

}
