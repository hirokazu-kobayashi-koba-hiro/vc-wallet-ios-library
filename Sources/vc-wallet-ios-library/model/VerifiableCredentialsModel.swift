//
//  VerifiableCredentialsModel.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/12.
//

public class CredentialOfferRequestValidator {
  let scheme: String?
  let params: [String: String]

  public init(credentialOfferRequest: CredentialOfferRequest) {
    self.scheme = credentialOfferRequest.scheme
    self.params = credentialOfferRequest.params
  }

  public func validate() throws {
    try throwExceptionIfNotValidScheme()
    try throwExceptionIfRequiredParams()
    try throwExceptionIfDuplicatedParams()
  }

  func throwExceptionIfNotValidScheme() throws {

    guard let schemeValue = scheme else {
      throw VerifiableCredentialsError.invalidCredentialOfferRequest("Scheme is required.")
    }

    if schemeValue != "openid-credential-offer" {
      throw VerifiableCredentialsError.invalidCredentialOfferRequest(
        "Scheme must be 'openid-credential-offer://'.")
    }
  }

  func throwExceptionIfRequiredParams() throws {

    if params["credential_offer"] == nil && params["credential_offer_uri"] == nil {
      throw VerifiableCredentialsError.invalidCredentialOfferRequest(
        "Credential offer request must contain either credential_offer or credential_offer_uri.")
    }
  }

  func throwExceptionIfDuplicatedParams() throws {

    if let credentialOffer = params["credential_offer"],
      let credentialOfferUri = params["credential_offer_uri"]
    {
      throw VerifiableCredentialsError.invalidCredentialOfferRequest(
        "Credential offer request must not contain both credential_offer and credential_offer_uri.")
    }
  }
}

public class CredentialOfferCreator {
  let map: [String: Any]

  public init(_ map: [String: Any]) {
    self.map = map
  }

  public func create() throws -> CredentialOffer {
    guard let credentialIssuer = map["credential_issuer"] as? String,
      let credentialConfigurationIds = map["credential_configuration_ids"] as? [String]
    else {

      Logger.shared.debug(
        "credential offer request does not contain credential_issuer or credential_configuration_ids"
      )
      throw VerifiableCredentialsError.invalidCredentialOfferRequest()
    }

    guard let grants = map["grants"] as? [String: Any] else {
      return CredentialOffer(
        credentialIssuer: credentialIssuer, credentialConfigurationIds: credentialConfigurationIds)
    }

    let preAuthorizedCodeGrant = toPreAuthorizedGrant(grants)
    let authorizedCodeGrant = toAuthorizationCodeGrant(grants)

    return CredentialOffer(
      credentialIssuer: credentialIssuer, credentialConfigurationIds: credentialConfigurationIds,
      preAuthorizedCodeGrant: preAuthorizedCodeGrant, authorizedCodeGrant: authorizedCodeGrant)
  }

  func toAuthorizationCodeGrant(_ json: [String: Any]) -> AuthorizedCodeGrant? {
    guard let authorizationCodeObject = json["authorization_code"] as? [String: Any] else {
      return nil
    }

    let issuerState = authorizationCodeObject["issuer_state"] as? String
    let authorizationServer = authorizationCodeObject["authorization_server"] as? String

    return AuthorizedCodeGrant(
      issuerState: issuerState,
      authorizationServer: authorizationServer
    )
  }

  func toPreAuthorizedGrant(_ json: [String: Any]) -> PreAuthorizedCodeGrant? {
    guard
      let preAuthorizationCodeObject = json["urn:ietf:params:oauth:grant-type:pre-authorized_code"]
        as? [String: Any],
      let preAuthorizedCode = preAuthorizationCodeObject["pre-authorized_code"] as? String
    else {
      return nil
    }

    if let txCodeObject = preAuthorizationCodeObject["tx_code"] as? [String: Any] {
      let length = txCodeObject["length"] as? Int
      let inputMode = txCodeObject["input_mode"] as? String
      let description = txCodeObject["description"] as? String

      return PreAuthorizedCodeGrant(
        preAuthorizedCode: preAuthorizedCode,
        length: length,
        inputMode: inputMode,
        description: description
      )
    } else {
      return PreAuthorizedCodeGrant(preAuthorizedCode: preAuthorizedCode)
    }
  }
}

public class CredentialRequestProofCreator {
  private let cNonce: String?
  private let clientId: String
  private let issuer: String
  private let privateKey: String

  init(cNonce: String?, clientId: String, issuer: String, privateKey: String) {
    self.cNonce = cNonce
    self.clientId = clientId
    self.issuer = issuer
    self.privateKey = privateKey
  }

  func create() throws -> [String: Any] {

    let header: [String: String] = ["": ""]
    var payload: [String: Any] = [
      "iss": clientId,
      "aud": issuer,
      "iat": "DateUtil.shared.nowAsEpochSecond()",
    ]

    if let cNonce = cNonce {
      payload["nonce"] = cNonce
    }

    //FIXME algorithm
    let jwt = try JoseUtil.shared.sign(
      algorithm: "ES256", privateKeyAsJwk: privateKey, headers: header, claims: payload)

    return ["proof_type": "jwt", "proof": jwt]
  }
}
