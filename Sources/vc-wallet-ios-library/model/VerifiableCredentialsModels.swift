//
//  VerifiableCredentialsModel.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/12.
//

import Foundation

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

    let publicKey = try convertEcPublicKey(privateKey: privateKey)
    let header: [String: Any] = ["typ": "openid4vci-proof+jwt", "jwk": publicKey]
    var payload: [String: Any] = [
      "iss": clientId,
      "aud": issuer,
      "iat": nowAsEpochSecond(),
    ]

    if let cNonce = cNonce {
      payload["nonce"] = cNonce
    }

    let jwt = try JoseAdapter.shared.sign(
      privateKeyAsJwk: privateKey, headers: header, claims: payload)

    return ["proof_type": "jwt", "jwt": jwt]
  }
}

public class VerifiableCredentialsRecord: Codable {
  let id: String
  let issuer: String
  let type: String
  let format: String
  let rawVc: String
  let payload: [String: Any]

  init(
    id: String, issuer: String, type: String, format: String, rawVc: String, payload: [String: Any]
  ) {
    self.id = id
    self.issuer = issuer
    self.type = type
    self.format = format
    self.rawVc = rawVc
    self.payload = payload
  }

  enum CodingKeys: String, CodingKey {
    case id, issuer, type, format, rawVc, payload
  }

  public required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    issuer = try container.decode(String.self, forKey: .issuer)
    type = try container.decode(String.self, forKey: .type)
    format = try container.decode(String.self, forKey: .format)
    rawVc = try container.decode(String.self, forKey: .rawVc)

    // Custom decoding for payload as [String: Any]
    let payloadData = try container.decode(Data.self, forKey: .payload)
    payload =
      try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] ?? [:]
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(issuer, forKey: .issuer)
    try container.encode(type, forKey: .type)
    try container.encode(format, forKey: .format)
    try container.encode(rawVc, forKey: .rawVc)

    // Custom encoding for payload as JSON data
    let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [])
    try container.encode(payloadData, forKey: .payload)
  }

  func isSdJwt() -> Bool {
    return format == "vc+sd-jwt"
  }

  func isJwt() -> Bool {
    return format == "jwt_vc_json"
  }

  func isLdp() -> Bool {
    return format == "ldp_vc"
  }
}

public struct VerifiableCredentialsRecords: Sequence {
  var values: [VerifiableCredentialsRecord]

  init() {
    self.values = []
  }

  init(values: [VerifiableCredentialsRecord]) {
    self.values = values
  }

  mutating func add(record: VerifiableCredentialsRecord) -> VerifiableCredentialsRecords {
    var arrayList = values
    arrayList.append(record)
    return VerifiableCredentialsRecords(values: arrayList)
  }

  func find(ids: [String]) -> VerifiableCredentialsRecords {
    let filtered = values.filter { ids.contains($0.id) }
    return VerifiableCredentialsRecords(values: filtered)
  }

  func find(id: String) -> VerifiableCredentialsRecord? {
    return values.first { $0.id == id }
  }

  func rawVcList() -> [String] {
    return values.map { $0.rawVc }
  }

  public func makeIterator() -> IndexingIterator<[VerifiableCredentialsRecord]> {
    return values.makeIterator()
  }

  func size() -> Int {
    return values.count
  }
}

public class VerifiableCredentialTransformer {
  let issuer: String
  let verifiableCredentialsType: VerifiableCredentialsType
  let type: String
  let rawVc: String
  let jwks: String

  public init(
    issuer: String, verifiableCredentialsType: VerifiableCredentialsType, type: String,
    rawVc: String, jwks: String
  ) {
    self.issuer = issuer
    self.verifiableCredentialsType = verifiableCredentialsType
    self.type = type
    self.rawVc = rawVc
    self.jwks = jwks
  }

  public func transform() throws -> VerifiableCredentialsRecord {
    let uuid = UUID().uuidString
    let format = verifiableCredentialsType.rawValue

    switch verifiableCredentialsType {
    case .sdJwt:
      let payload = try SdJwtAdapter.shared.verifyAndDecode(sdJwt: rawVc, jwks: jwks)
      return VerifiableCredentialsRecord(
        id: uuid, issuer: issuer, type: type, format: format, rawVc: rawVc, payload: payload)
    default:
      throw VerifiableCredentialsError.unsupportedCredentialFormat(
        verifiableCredentialsType.rawValue)
    }
  }
}

public struct CredentialIssuanceResult: Codable {
  let id: String
  let issuer: String
  let credentialConfigurationId: String
  let credential: String?
  let transactionId: String?
  let cNonce: String?
  let cNonceExpiresIn: Int?
  let notificationId: String?
  let status: CredentialIssuanceResultStatus

  init(
    id: String,
    issuer: String,
    credentialConfigurationId: String,
    credential: String? = nil,
    transactionId: String? = nil,
    cNonce: String? = nil,
    cNonceExpiresIn: Int? = nil,
    notificationId: String? = nil,
    status: CredentialIssuanceResultStatus
  ) {
    self.id = id
    self.issuer = issuer
    self.credentialConfigurationId = credentialConfigurationId
    self.credential = credential
    self.transactionId = transactionId
    self.cNonce = cNonce
    self.cNonceExpiresIn = cNonceExpiresIn
    self.notificationId = notificationId
    self.status = status
  }
}

public enum CredentialIssuanceResultStatus: String, Codable {
  case pending = "PENDING"
  case success = "SUCCESS"
}
