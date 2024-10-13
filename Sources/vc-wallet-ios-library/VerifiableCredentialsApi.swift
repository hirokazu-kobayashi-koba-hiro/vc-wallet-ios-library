//
//  VerifiableCredentialsApi.swift
//
//
//  Created by 小林弘和 on 2024/09/28.
//

import Foundation
import UIKit

public final class VerifiableCredentialsApi: @unchecked Sendable {

  public static let shared = VerifiableCredentialsApi()
  private var walletConfiguration: WalletConfiguration?
  private var verifiableCredentialsService: VerifiableCredentialsService?

  public func initialize(
    walletConfiguration: WalletConfiguration,
    verifiableCredentialsService: VerifiableCredentialsService
  ) {
    self.walletConfiguration = walletConfiguration
    self.verifiableCredentialsService = verifiableCredentialsService
  }

  public func handlePreAuthorization(
    from: UIViewController, subject: String, url: String,
    interactor: VerifiableCredentialInteractor = DefaultVerifiableCredentialInteractor()
  ) async throws {
    guard let configuration = walletConfiguration, let service = verifiableCredentialsService else {
      throw VerifiableCredentialsError.systemError(
        "VerifiableCredentialsService is not initialized.")
    }

    let credentialOfferRequest = CredentialOfferRequest(url: url)
    let credentialOfferRequestValidator = CredentialOfferRequestValidator(
      credentialOfferRequest: credentialOfferRequest)
    try credentialOfferRequestValidator.validate()

    let credentialOffer = try await service.getCredentialOffer(
      credentialOfferRequest: credentialOfferRequest)
    guard let preAuthorizedCodeGrant = credentialOffer.preAuthorizedCodeGrant else {
      throw VerifiableCredentialsError.invalidCredentialOffer(
        "PreAuthorizedCode in credential offer response is empty. It is required on pre-authorization-code flow"
      )
    }

    let credentialIssuerMetadata = try await service.getCredentialIssuerMetadata(
      url: credentialOffer.credentialIssuerMetadataEndpoint())
    let oidcMetadata =
      try await service.getOidcMetadata(
        url: credentialIssuerMetadata.getOpenIdConfigurationEndpoint())
    let clientConfiguration = try await service.getOrRegisterClientConfiguration(
      oidcMetadata: oidcMetadata)

    let (result, txCode) = await interact(
      from: from, credentialIssuerMetadata: credentialIssuerMetadata,
      credentialOffer: credentialOffer, interactor: interactor)

    if !result {
      throw VerifiableCredentialsError.notAuthenticated("user canceled")
    }

    let tokenResponse = try await service.requestTokenWithPreAuthorizedCode(
      url: oidcMetadata.tokenEndpoint, clientId: clientConfiguration.clientId,
      preAuthorizationCode: preAuthorizedCodeGrant.preAuthorizedCode, txCode: txCode)

    let verifiableCredentialsType =
      try credentialIssuerMetadata.getVerifiableCredentialsType(
        credentialConfigurationId: credentialOffer.credentialConfigurationIds[0])
    let vct = credentialIssuerMetadata.findVct(
      credentialConfigurationId: credentialOffer.credentialConfigurationIds[0])

    let proofCreator = CredentialRequestProofCreator(
      cNonce: tokenResponse.cNonce, clientId: clientConfiguration.clientId,
      issuer: oidcMetadata.issuer, privateKey: configuration.privateKey)
    let proof = try proofCreator.create()
    let credentialResponse = try await service.requestCredential(
      url: credentialIssuerMetadata.credentialEndpoint, dpopJwt: nil,
      accessToken: tokenResponse.accessToken, verifiableCredentialType: verifiableCredentialsType,
      vct: vct)

    let jwtVcConfiguration = try await service.getJwksConfiguration(
      jwtVcIssuerEndpoint: credentialOffer.jwtVcIssuerEndpoint())
    let jwks = try await service.getJwks(jwtVcConfiguration: jwtVcConfiguration)

    if let credential = credentialResponse.credential {

    }

  }

  private func interact(
    from: UIViewController,
    credentialIssuerMetadata: CredentialIssuerMetadata,
    credentialOffer: CredentialOffer,
    interactor: VerifiableCredentialInteractor
  ) async -> (Bool, String?) {

    await withCheckedContinuation { continuation in

      interactor.confirm(
        viewController: from, credentialIssuerMetadata: credentialIssuerMetadata,
        credentialOffer: credentialOffer
      ) { result, txCode in

        if result {
          continuation.resume(returning: (true, txCode))
        } else {
          continuation.resume(returning: (false, nil))
        }
      }
    }
  }
}
