//
//  HttpClient.swift
//  vc-wallet-library
//
//  Created by 小林弘和 on 2024/09/06.
//

import Foundation

public final class HttpClient: Sendable {

  let urlSession: URLSession

  public init(sessionConfiguration: URLSessionConfiguration) {
    urlSession = URLSession.init(configuration: sessionConfiguration)
  }

  public func get(url: String, headers: [String: String]? = nil) async throws -> [String: Any] {
    guard let url = URL(string: url) else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    headers?.forEach { header in
      request.setValue(header.value, forHTTPHeaderField: header.key)
    }
    Logger.shared.debug("request: \(request)")

    let (data, response) = try await urlSession.data(for: request)

    let responseBody = try handleResponse(response: response, data: data)

    return responseBody
  }

  public func get<T: Decodable>(
    url: String, headers: [String: String]? = nil, responseType: T.Type,
    enableSnakeCase: Bool = true
  ) async throws -> T {
    guard let url = URL(string: url) else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    headers?.forEach { header in
      request.setValue(header.value, forHTTPHeaderField: header.key)
    }

    Logger.shared.debug("request: \(request)")

    let (data, response) = try await urlSession.data(for: request)

    return try handleResponse(
      response: response, data: data, responseType: responseType, enableSnakeCase: enableSnakeCase)
  }

  public func post(url: String, headers: [String: String]? = nil, body: [String: Any]? = nil)
    async throws -> [String: Any]
  {
    guard let url = URL(string: url) else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    headers?.forEach { header in
      request.setValue(header.value, forHTTPHeaderField: header.key)
    }

    Logger.shared.debug("request: \(request)")

    if let contentType = headers?["Content-Type"],
      contentType == "application/x-www-form-urlencoded"
    {
      if let body = body {
        let formBody = body.map { "\($0.key)=\($0.value)" }
          .joined(separator: "&")
        Logger.shared.debug("request body (url-encoded): \(formBody)")
        request.httpBody = formBody.data(using: .utf8)
      }
    } else if let body = body {
      let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
      Logger.shared.debug("request body (JSON): \(String(data: jsonData, encoding: .utf8)!)")
      request.httpBody = jsonData
    }

    let (data, response) = try await urlSession.data(for: request)

    let responseBody = try handleResponse(response: response, data: data)

    return responseBody
  }

  public func post<T: Decodable>(
    url: String, headers: [String: String]? = nil,
    body: [String: Any]? = nil,
    responseType: T.Type,
    enableSnakeCase: Bool = true
  ) async throws -> T {
    guard let url = URL(string: url) else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    headers?.forEach { header in
      request.setValue(header.value, forHTTPHeaderField: header.key)
    }

    if let contentType = headers?["Content-Type"],
      contentType == "application/x-www-form-urlencoded"
    {
      if let body = body {
        let formBody = body.map { "\($0.key)=\($0.value)" }
          .joined(separator: "&")
        Logger.shared.debug("request body (url-encoded): \(formBody)")
        request.httpBody = formBody.data(using: .utf8)
      }
    } else if let body = body {
      let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
      Logger.shared.debug("request body (JSON): \(String(data: jsonData, encoding: .utf8)!)")
      request.httpBody = jsonData
    }

    Logger.shared.debug("request: \(request)")

    let (data, response) = try await urlSession.data(for: request)

    return try handleResponse(
      response: response, data: data, responseType: responseType, enableSnakeCase: enableSnakeCase)
  }

  private func handleResponse(response: URLResponse, data: Data) throws -> [String: Any] {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }
    let statusCode = httpResponse.statusCode
    Logger.shared.debug("HTTP response with status code: \(statusCode)")
    let responseJson = readFromJson(data)

    guard let response = responseJson else {
      throw URLError(.cannotParseResponse)
    }
    switch statusCode {
    case 200...299:
      return response
    case 429:
      throw HttpError.tooManyRequestsError(statusCode: statusCode, response: data)
    case 400...499:
      throw HttpError.clientError(statusCode: statusCode, response: data)
    case 503:
      throw HttpError.serverMaintenanceError(statusCode: statusCode, response: data)
    case 500...599:
      throw HttpError.serverError(statusCode: statusCode, response: data)
    default:
      throw HttpError.networkError(statusCode: statusCode, response: data)
    }
  }

  private func parse(_ data: Data) throws -> [String: Any] {
    guard !data.isEmpty else {
      return [:]
    }
    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
    Logger.shared.debug("Response: \(jsonObject)")
    guard let dictionary = jsonObject as? [String: Any] else {
      throw URLError(.cannotParseResponse)
    }
    return dictionary
  }

  private func handleResponse<T: Decodable>(
    response: URLResponse, data: Data, responseType: T.Type, enableSnakeCase: Bool
  ) throws -> T {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }
    let statusCode = httpResponse.statusCode
    Logger.shared.debug("HTTP response with status code: \(statusCode)")

    let decoder = JSONDecoder()
    if enableSnakeCase {
      decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    switch statusCode {
    case 200...299:
      if responseType == String.self, let responseString = String(data: data, encoding: .utf8) as? T
      {
        Logger.shared.debug("Response (String): \(responseString)")
        return responseString
      }
      let decodedResponse = try decoder.decode(T.self, from: data)
      Logger.shared.debug("Response: \(decodedResponse)")
      return decodedResponse
    case 429:
      throw HttpError.tooManyRequestsError(statusCode: statusCode, response: data)
    case 400...499:
      let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
      Logger.shared.debug("ClientErrorResponse: \(jsonObject)")
      throw HttpError.clientError(statusCode: statusCode, response: data)
    case 503:
      throw HttpError.serverMaintenanceError(statusCode: statusCode, response: data)
    case 500...599:
      throw HttpError.serverError(statusCode: statusCode, response: data)
    default:
      throw HttpError.networkError(statusCode: statusCode, response: data)
    }
  }
}
