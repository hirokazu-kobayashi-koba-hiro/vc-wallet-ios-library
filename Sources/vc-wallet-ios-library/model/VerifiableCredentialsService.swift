//
//  VerifiableCredentialsService.swift
//
//
//  Created by 小林弘和 on 2024/10/07.
//

import Foundation


public class VerifiableCredentialsService {
    
    private let httpClient = HttpClient(sessionConfiguration: URLSessionConfiguration.ephemeral)
    
    
    public func getCredentialOffer(credentialOfferRequest: CredentialOfferRequest) async throws -> CredentialOffer {
        
        if let credentialOfferUri = credentialOfferRequest.credentialOfferUri() {
            let response = try await httpClient.get(url: credentialOfferUri)
            let creator = CredentialOfferCreator(response)
            return creator.create()
        }
        
        if let credentialOffer = credentialOfferRequest.credentialOffer() {
            let response = try JSONSerialization.data(withJSONObject: credentialOffer, options: [String: Any])
            let creator = CredentialOffer(response)
            return creator.create()
        }
        
        Logger.shared.error("neither contain credentialOfferUri or credentialOffer")
        throw VerifiableCredentialsError.invalidCredentialOfferRequest
    }
    
    public func  getCredentialIssuerMetadata(url: String) async throws -> CredentialIssuerMetadata {
        
        return try await httpClient.get(url: url, responseType: CredentialIssuerMetadata.self)
    }
    
    public func getOidcMetadata(urlL String) async throws -> OidcMetadata {
        
        return try await httpClient.get(url: urlL, responseType: OidcMetadata.self)
    }
}
