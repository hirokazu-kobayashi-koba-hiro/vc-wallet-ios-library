//
//  VerifiableCredentialsError.swift
//  vc-wallet-library
//
//  Created by 小林弘和 on 2024/09/24.
//

import Foundation

public enum VerifiableCredentialsError: Error {
  case invalidCredentialOfferRequest(_ description: String? = nil)
  case invalidCredentialOffer(_ description: String? = nil)
  case invalidCredentialIssuerMetadata(_ description: String? = nil)
  case invalidClientConfiguration(_ description: String? = nil)
  case unsupportedCredentialFormat(_ description: String? = nil)
  case vcIssuerUnsupportedDynamicClientRegistration(_ description: String? = nil)
  case notAuthenticated(_ description: String? = nil)
  case networkError
  case systemError(_ description: String? = nil)
  case unknownError

}

public enum HttpError: Error {
  case networkError(statusCode: Int, response: Data? = nil)
  case clientError(statusCode: Int, response: Data? = nil)
  case tooManyRequestsError(statusCode: Int = 429, response: Data? = nil)
  case serverError(statusCode: Int, response: Data? = nil)
  case serverMaintenanceError(statusCode: Int = 503, response: Data? = nil)

}

enum JoseUtilError: Error {
  case unsupportedAlgorithm(String)
  case invalidJWKFormat
  case invalidJWSFormat
  case missingJWKParameters
  case signerCreationFailed
  case jwsCreationFailed
  case verifierCreationFailed

  var localizedDescription: String {
    switch self {
    case .unsupportedAlgorithm(let alg):
      return "\(alg) is unsupported"
    case .invalidJWKFormat:
      return "Invalid JWK format"
    case .invalidJWSFormat:
      return "Invalid JWS format"
    case .missingJWKParameters:
      return "Missing or invalid JWK parameters"
    case .signerCreationFailed:
      return "failed creation of signer, private key or algorithm is invalid"
    case .jwsCreationFailed:
      return "Invalid JWs creation failed"
    case .verifierCreationFailed:
      return "failed creation of verifier, public key or algorithm is invalid"
    }
  }
}
