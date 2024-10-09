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
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    // Any test you write for XCTest can be annotated as throws and async.
    // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
    // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    try await VerifiableCredentialsApi.shared.handlePreAuthorization(
      subject: "test",
      url:
        "openid-credential-offer://?credential_offer_uri=https://trial.authlete.net/api/offer/MUzi6yE2swpabfvFLoG89y3GeCtawmUvvoGigQ-pf_o"
    )
  }

  func testPerformanceExample() throws {
    // This is an example of a performance test case.
    self.measure {
      // Put the code you want to measure the time of here.
    }
  }

}
