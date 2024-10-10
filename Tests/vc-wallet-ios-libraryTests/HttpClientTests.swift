//
//  HttpClientTests.swift
//  vc-wallet-libraryTests
//
//  Created by 小林弘和 on 2024/09/08.
//

import XCTest

@testable import VcWalletLibrary

final class HttpClientTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Set up any necessary state before each test is run
  }

  override func tearDown() {
    // Clean up any state after each test is run
    super.tearDown()
  }

  // Example test for GET request
  func testGetRequestSuccess() async throws {
    // Given
    let url = "https://jsonplaceholder.typicode.com/posts/1"

    // When
    let config = URLSessionConfiguration.ephemeral
    let httpClient = HttpClient(sessionConfiguration: config)
    let response = try await httpClient.get(url: url)

    // Then
    XCTAssertNotNil(response["id"])
    XCTAssertEqual(response["id"] as? Int, 1)
    XCTAssertEqual(response["userId"] as? Int, 1)
  }

}

//class MockURLProtocol: URLProtocol {
//
//  static var mockResponseHandler: (() -> (HTTPURLResponse, Data))?
//
//  override class func canInit(with request: URLRequest) -> Bool {
//    return true
//  }
//
//  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
//    return request
//  }
//
//  override func startLoading() {
//    if let handler = MockURLProtocol.mockResponseHandler {
//      let (response, data) = handler()
//      self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
//      self.client?.urlProtocol(self, didLoad: data)
//    }
//    self.client?.urlProtocolDidFinishLoading(self)
//  }
//
//  override func stopLoading() {
//
//  }
//}
