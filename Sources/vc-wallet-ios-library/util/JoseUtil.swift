//
//  JoseUtil.swift
//  vc-wallet-library
//
//  Created by 小林弘和 on 2024/09/14.
//

import Foundation
import JOSESwift
import CryptoKit

public class JoseUtil {
    
    public static let shared = JoseUtil()
    
    
    public func sign(algorithm: String, privateKeyAsJwk: String, headers: [String: Any], claims: [String: Any]) throws -> String {
        let algorithm = try toAlgorithm(algorithm: algorithm)
        
        let claimsAsString = try JSONSerialization.data(withJSONObject: claims, options: [])
        let payload = Payload(claimsAsString)
        
        let (kid, secKey) = try SecKey.convertFromPrivateKeyFormattedJwk(algorithm: algorithm, privateKey: privateKeyAsJwk)
        var header = headers
        header["alg"] = algorithm.rawValue
        if let unwrappedKid = kid {
            header["kid"] = unwrappedKid
        }
        let jwsHeader = try JWSHeader(parameters: header)
        
        
        guard let signer = Signer(signatureAlgorithm: algorithm, key: secKey) else {
            throw JoseUtilError.signerCreationFailed
        }
        
        guard let jws = try? JWS(header: jwsHeader, payload: payload, signer: signer) else {
            throw JoseUtilError.jwsCreationFailed
        }
        let jwtValue = jws.compactSerializedString
        Logger.shared.debug(jwtValue)
        
        return jwtValue
    }
    
    public func verify(jws: String, algorithm: String, publicKeyAsJwk: String) throws -> VerifiedJose {
        let algorithm = try toAlgorithm(algorithm: algorithm)
        
        let jws = try JWS(compactSerialization: jws)
        let publicKey = try SecKey.convertFromPublicKeyFormattedJwk(algorithm: algorithm, publicKey: publicKeyAsJwk)
        guard let verifier = Verifier(signatureAlgorithm: algorithm, key: publicKey) else {
            throw JoseUtilError.signerCreationFailed
        }
        let verifiedJws = try jws.validate(using: verifier)
        
        guard let header = try? JSONSerialization.jsonObject(with: verifiedJws.header.data(), options: []) as? [String: Any],
              let payload = try? JSONSerialization.jsonObject(with: verifiedJws.payload.data(), options: []) as? [String: Any]
        else {
            throw JoseUtilError.invalidJWKFormat
        }
        
        return VerifiedJose(header: header, payload: payload)
    }
}

public struct VerifiedJose {
    let header: [String: Any]
    let payload: [String: Any]
    
    public init(header: [String : Any], payload: [String : Any]) {
        self.header = header
        self.payload = payload
    }
    
    
}

extension SecKey {
    
    static func convertFromPrivateKeyFormattedJwk(algorithm: SignatureAlgorithm, privateKey: String) throws -> (String?, SecKey) {
        
        switch algorithm {
            
        case .HS256, .HS384, .HS512, .RS256, .RS384, .RS512, .PS256, .PS384, .PS512:
            
            throw JoseUtilError.unsupportedAlgorithm(algorithm.rawValue)
            
        case .ES256, .ES384, .ES512:
            
            return try convertECPrivateKey(privateKeyAsJwk: privateKey)
        }
    }
    
    static func convertFromPublicKeyFormattedJwk(algorithm: SignatureAlgorithm, publicKey: String) throws -> SecKey {
        
        switch algorithm {
            
        case .HS256, .HS384, .HS512, .RS256, .RS384, .RS512, .PS256, .PS384, .PS512:
            
            throw JoseUtilError.unsupportedAlgorithm(algorithm.rawValue)
            
        case .ES256, .ES384, .ES512:
            
            return try convertECPublickKey(publickKeyAsJwk: publicKey)
        }
    }
}

func convertECPrivateKey(privateKeyAsJwk: String) throws -> (String?, SecKey) {
    
    guard let jsonData = privateKeyAsJwk.data(using: .utf8),
          let jwk = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] else {
        
        throw JoseUtilError.invalidJWKFormat
    }
    
    guard let crv = jwk["crv"],
          let x = jwk["x"],
          let y = jwk["y"],
          let d = jwk["d"],
          let xData = Data(base64URLEncoded: x),
          let yData = Data(base64URLEncoded: y),
          let dData = Data(base64URLEncoded: d) else {
        
        throw JoseUtilError.missingJWKParameters
    }
    
    let components = (
        crv: crv,
        x: xData,
        y: yData,
        d: dData
    )
    let kid = jwk["kid"]
    return (kid, try SecKey.representing(ecPrivateKeyComponents: components))
}

func convertECPublickKey(publickKeyAsJwk: String) throws -> SecKey {
    
    guard let jsonData = publickKeyAsJwk.data(using: .utf8),
          let jwk = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] else {
        
        throw JoseUtilError.invalidJWKFormat
    }
    
    guard let crv = jwk["crv"],
          let x = jwk["x"],
          let y = jwk["y"],
          let xData = Data(base64URLEncoded: x),
          let yData = Data(base64URLEncoded: y) else {
        throw JoseUtilError.missingJWKParameters
    }
    
    let components = (
        crv: crv,
        x: xData,
        y: yData
    )
    
    return try SecKey.representing(ecPublicKeyComponents: components)
}

// Base64 URL decoding (handles padding)
extension Data {
    init?(base64URLEncoded base64URLString: String) {
        var base64String = base64URLString
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let paddedLength = (4 - base64String.count % 4) % 4
        base64String += String(repeating: "=", count: paddedLength)
        
        self.init(base64Encoded: base64String)
    }
}

func toAlgorithm(algorithm: String) throws -> SignatureAlgorithm {
    
    switch algorithm {
    case "HS256":
        return SignatureAlgorithm.HS256
    case "HS384":
        return SignatureAlgorithm.HS384
    case "HS512":
        return SignatureAlgorithm.HS512
    case "RS256":
        return SignatureAlgorithm.RS256
    case "RS384":
        return SignatureAlgorithm.RS384
    case "RS512":
        return SignatureAlgorithm.RS512
    case "PS256":
        return SignatureAlgorithm.PS256
    case "PS384":
        return SignatureAlgorithm.PS384
    case "PS512":
        return SignatureAlgorithm.PS512
    case "ES256":
        return SignatureAlgorithm.ES256
    case "ES384":
        return SignatureAlgorithm.ES384
    case "ES512":
        return SignatureAlgorithm.ES512
    default:
        throw JoseUtilError.unsupportedAlgorithm(algorithm)
    }
}
