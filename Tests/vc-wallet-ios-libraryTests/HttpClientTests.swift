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

  // Example test for POST request
  func testPostRequestSuccess() async throws {
    // Given
    // Mock the response
    let url = "https://jsonplaceholder.typicode.com/posts"

    MockURLProtocol.mockResponseHandler = {
      let jsonString = """
        {
            "id": 1,
            "title": "foo",
            "body": "bar",
            "userId": 1
        }
        """
      let data = jsonString.data(using: .utf8)!
      let response = HTTPURLResponse(
        url: URL(string: url)!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil)!
      return (response, data)
    }

    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    let httpClient = HttpClient(sessionConfiguration: config)

    let body: [String: Any] = [
      "title": "foo",
      "body": "bar",
      "userId": 1,
    ]

    // When
    let response = try await httpClient.post(url: url, body: body)

    // Then
    XCTAssertNotNil(response["id"])  // Check that the ID is present in the response
    XCTAssertEqual(response["title"] as? String, "foo")
    XCTAssertEqual(response["body"] as? String, "bar")
    XCTAssertEqual(response["userId"] as? Int, 1)
  }

}

class MockURLProtocol: URLProtocol {

  static var mockResponseHandler: (() -> (HTTPURLResponse, Data))?

  override class func canInit(with request: URLRequest) -> Bool {
    return true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }

  override func startLoading() {
    if let handler = MockURLProtocol.mockResponseHandler {
      let (response, data) = handler()
      self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      self.client?.urlProtocol(self, didLoad: data)
    }
    self.client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {

  }
}
