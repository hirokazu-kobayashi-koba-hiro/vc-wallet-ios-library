//
//  VerifiableCredentialsApiTests.swift
//
//
//  Created by 小林弘和 on 2024/10/03.
//

import VcWalletLibrary
import XCTest

final class VerifiableCredentialsApiTests: XCTestCase {

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testHandlePreAuthorization() async throws {
    let viewController = await UIViewController()

    let verifiableCredentialsService = VerifiableCredentialsService(
      walletClientConfigurationRepository: WalletClientConfigurationDataSource(),
      verifiableCredentialRecordRepository: VerifiableCredentialRecordDataSource())
    VerifiableCredentialsApi.shared.initialize(
      walletConfiguration: WalletConfiguration(),
      verifiableCredentialsService: verifiableCredentialsService)

    try await VerifiableCredentialsApi.shared.handlePreAuthorization(
      from: viewController,
      subject: "test",
      url:
        "openid-credential-offer://?credential_offer_uri=https://trial.authlete.net/api/offer/idwVjINoZf6l9MNMyAtkxFEf2OZFSBYD8neZH29ofiA"
    )
  }

  func testPerformanceExample() throws {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }

}
