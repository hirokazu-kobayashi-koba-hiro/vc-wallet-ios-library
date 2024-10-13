//
//  SdJwtUtil.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/13.
//
import Foundation
import JSONWebKey
import JSONWebSignature
import JSONWebToken
import SwiftyJSON
import Tools
import eudi_lib_sdjwt_swift

public final class SdJwtUtil: Sendable {

  public static let shared = SdJwtUtil()

  private init() {}

  public func verifyAndDecode(sdJwt: String, jwks: String) throws -> [String: Any] {
    let jwks = try JSONDecoder.jwt.decode(JWKSet.self, from: jwks.tryToData())
    let headers = try extractHeaders(jwsString: sdJwt)
    let keyID = headers["kid"] as? String
    let algorithm = headers["alg"] as? String
    let publickey = try jwks.find(keyID: keyID, algorithm: algorithm)

    let _ = try SDJWTVerifier(
      parser: CompactParser(),
      serialisedString: sdJwt
    )
    .verifyIssuance { jws in
      try SignatureVerifier(signedJWT: jws, publicKey: publickey)
    } claimVerifier: { _, _ in
      ClaimsVerifier()
    }

    let recreatedClaimsResult = try CompactParser()
      .getSignedSdJwt(serialisedString: sdJwt)
      .recreateClaims()

    Logger.shared.debug("recreatedClaimsResult: \(recreatedClaimsResult)")

    guard let claims = recreatedClaimsResult.recreatedClaims.dictionaryObject else {
      throw SDJWTError.invalidSdJwt("claims is nil")
    }
    return claims
  }
}

extension JWKSet {

  public func find(keyID: String?, algorithm: String?) throws -> JWK {
    if let keyId = keyID {
      return try self.key(withID: keyId)
    }
    if let algorithm = algorithm {
      guard let jwk = self.keys.filter({ $0.algorithm == algorithm }).first else {
        throw SDJWTError.notFoundJwk("not found jwk \(algorithm)")
      }
      return jwk
    }
    guard let jwk = self.keys.first else {
      throw SDJWTError.notFoundJwk("not found jwk")
    }
    return jwk
  }
}

public enum SDJWTError: Error {
  case notFoundJwk(_ description: String? = nil)
  case invalidSdJwt(_ description: String? = nil)
}

public func extractHeaders(jwsString: String) throws -> [String: Any] {
  let components = jwsString.components(separatedBy: ".")
  guard components.count == 3 else {
    throw SDJWTError.invalidSdJwt("invalid sd jwt")
  }
  let headerDecoded = try Base64URL.decode(components[0])
  guard let headers = readFromJson(headerDecoded) else {
    throw SDJWTError.invalidSdJwt("invalid sd jwt")
  }
  return headers
}
