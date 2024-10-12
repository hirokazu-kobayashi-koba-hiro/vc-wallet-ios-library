//
//  VerifiableCredentialInteractor.swift
//  VcWalletLibrary
//
//  Created by 小林弘和 on 2024/10/11.
//

import Foundation
import UIKit

public protocol VerifiableCredentialInteractor {
  func confirm(
    viewController: UIViewController,
    credentialIssuerMetadata: CredentialIssuerMetadata,
    credentialOffer: CredentialOffer,
    callback: @escaping (Bool, String?) -> Void
  )
}

public class DefaultVerifiableCredentialInteractor: VerifiableCredentialInteractor {

  public init() {}

  public func confirm(
    viewController: UIViewController,
    credentialIssuerMetadata: CredentialIssuerMetadata,
    credentialOffer: CredentialOffer,
    callback: @escaping (Bool, String?) -> Void
  ) {
    callback(true, nil)
  }
}
