//
//  VerifiableCredentialsApi.swift
//
//
//  Created by 小林弘和 on 2024/09/28.
//

import Foundation


public class VerifiableCredentialsApi {
    
    public static let shared = VerifiableCredentialsApi()
    private let service = VerifiableCredentialsService()
    
    public func handlePreAuthorization(subject: String, url: String) async throws {
        
        let credentialOfferRequest = CredentialOfferRequest(url: url)
        let credentialOfferRequestValidator = CredentialOfferRequestValidator(credentialOfferRequest: credentialOfferRequest)
        credentialOfferRequestValidator.validate()
        
        let credentialOffer = try await service.getCredentialOffer(credentialOfferRequest: credentialOfferRequest)
        guard let preAuthorizedCodeGrant = credentialOffer.preAuthorizedCodeGrant else {
            throw VerifiableCredentialsError.invalidCredentialOffer("PreAuthorizedCode in credential offer response is empty. It is required on pre-authorization-code flow")
        }
        
        let credentialIssuerMeta = await service.getCredentialIssuerMetadata(url: credentialOffer.credentialIssuerMetadataEndpoint())
        
        
        
    }
}
