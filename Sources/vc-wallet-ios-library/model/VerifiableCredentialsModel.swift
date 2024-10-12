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

    // Return the proof
    return ["proof_type": "jwt", "proof": jwt]
  }
}
