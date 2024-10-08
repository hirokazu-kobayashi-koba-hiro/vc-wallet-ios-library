//
//  VerifieableCredentialsModel.swift
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

public class CredentialOfferRequestValidator {
    let scheme: String
    let params: [String: String]
    
    public init(credentialOfferRequest: CredentialOfferRequest) {
        self.scheme = credentialOfferRequest.scheme
        self.params = credentialOfferRequest.params
    }
    
    public func validate() throws {
        throwExceptionIfNotValidScheme()
        throwExceptionIfRequiredParams()
        throwExceptionIfDuplicatedParams()
    }
    
    func throwExceptionIfNotValidScheme() {
        
        guard let scheme == scheme else {
            throw VerifieableCredentialsError.invalidCredentialOfferRequest("Scheme is required.")
        }
        
        guard let scheme == "openid-credential-offer" else  {
            throw VerifieableCredentialsError.invalidCredentialOfferRequest("Scheme must be 'openid-credential-offer://'.")
        }
    }
    
    func throwExceptionIfRequiredParams() {
        
        guard let credentialOffer = params["credential_offer"], let credentialOfferUri = params["credential_offer_uri"] else {
            throw VerifieableCredentialsError.invalidCredentialOfferRequest(
                "Credential offer request must contain either credential_offer or credential_offer_uri.")
        }
    }
    
    func throwExceptionIfDuplicatedParams() {
        
        if let credentialOffer = params["credential_offer"], let credentialOfferUri = params["credential_offer_uri"] {
            throw VerifieableCredentialsError.invalidCredentialOfferRequest(
                "Credential offer request must not contain both credential_offer and credential_offer_uri.")
        }
    }
}

public struct CredentialOffer {
    let credentialIssuer: String
    let credentialConfigurationIds: [String]
    let preAuthorizedCodeGrant: PreAuthorizedCodeGrant?
    let authorizedCodeGrant: AuthorizedCodeGrant?
    
    public init(credentialIssuer: String, credentialConfigurationIds: [String], preAuthorizedCodeGrant: PreAuthorizedCodeGrant? = nil, authorizedCodeGrant: AuthorizedCodeGrant? = nil) {
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

public struct PreAuthorizedCodeGrant {
    let preAuthorizedCode: String
    let length: Int?
    let inputMode: String?
    let description: String?
    
    public init(preAuthorizedCode: String, length: Int? = null, inputMode: String? = null, description: String? = null) {
        self.preAuthorizedCode = preAuthorizedCode
        self.length = length
        self.inputMode = inputMode
        self.description = description
    }
}

public struct AuthorizedCodeGrant {
    let issuerState: String?
    let authorizationServer: String?
}

public class CredentialOfferCreator {
    let map: [String: Any]
    
    public init(_ map: [String : Any]) {
        self.map = map
    }
    
    public func create() throws -> CredentialOffer {
        guard let credentialIssuer = map["credential_issuer"] as? String,
              let credentialConfigurationIds = map["credential_configuration_ids"] as? [String] else {
            
            Logger.shared.debug("credential offer request does not contain credential_issuer or credential_configuration_ids")
            throw VerifiableCredentialsError.invalidCredentialOfferRequest
        }
        
        guard let grants = map["grants"] as? [String: Any] else {
            return CredentialOffer(credentialIssuer: credentialIssuer, credentialConfigurationIds: credentialConfigurationIds)
        }
        
        
        let preAuthorizedCodeGrant = toPreAuthorizedGrant(grants)
        let authorizedCodeGrant = toAuthorizationCodeGrant(grants)
        
        return CredentialOffer(credentialIssuer: credentialIssuer, credentialConfigurationIds: credentialConfigurationIds,
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
        guard let preAuthorizationCodeObject = json["urn:ietf:params:oauth:grant-type:pre-authorized_code"] as? [String: Any],
              let preAuthorizedCode = preAuthorizationCodeObject["pre-authorized_code"] as? String else {
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

public struct CredentialIssuerMetadata: Codable {
    let credentialIssuer: String
    let authorizationServers: [String]?
    let credentialEndpoint: String
    let batchCredentialEndpoint: String?
    let deferredCredentialEndpoint: String?
    let notificationEndpoint: String?
    let credentialResponseEncryption: CredentialResponseEncryption?
    let credentialIdentifiersSupported: Bool
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
    func getVerifiableCredentialsType(credentialConfigurationId: String) throws -> VerifiableCredentialsType {
        guard let format = credentialConfigurationsSupported[credentialConfigurationId]?.format else {
            throw VerifiableCredentialsException(error: .invalidVcIssuerMetadata,
                                                 message: "not found credential configuration (\(credentialConfigurationId))")
        }
        return VerifiableCredentialsType.of(format: format)
    }
    
    // Find VCT (Verifiable Credential Type)
    func findVct(credentialConfigurationId: String) -> String? {
        return credentialConfigurationsSupported[credentialConfigurationId]?.vct
    }
    
    // Get Scope
    func getScope(credentialConfigurationId: String) throws -> String {
        guard let scope = credentialConfigurationsSupported[credentialConfigurationId]?.scope else {
            throw VerifiableCredentialsException(error: .invalidVcIssuerMetadata,
                                                 message: "not found scope configuration, (\(credentialConfigurationId))")
        }
        return scope
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

public struct OidcMetadata: Codable {
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
